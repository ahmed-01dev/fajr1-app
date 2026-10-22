import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();
const db = admin.firestore();

/** Simple per-user, per-action rate-limit window stored in Firestore. */
async function rateLimit(
  uid: string,
  action: string,
  max: number,
  windowMs: number
): Promise<void> {
  const ref = db.doc(`_rate/${uid}_${action}`);
  const snap = await ref.get();
  const now = Date.now();
  const data = snap.data() as { count?: number; reset?: number } | undefined;
  if (data && data.reset && data.reset > now && (data.count ?? 0) >= max) {
    throw new functions.https.HttpsError("resource-exhausted", "RATE_LIMITED");
  }
  await ref.set({
    count:
      data && data.reset && data.reset > now ? (data.count ?? 0) + 1 : 1,
    reset: data && data.reset && data.reset > now ? data.reset : now + windowMs,
  });
}

/**
 * confirmWakeup — self-reported Fajr wake-up confirmation.
 * IDEMPOTENT per (uid, localDate): a repeat call for the same day can never
 * farm XP. XP and streaks are computed HERE — clients cannot award points.
 */
export const confirmWakeup = functions.https.onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "AUTH_REQUIRED");
  }

  await rateLimit(uid, "confirm", 5, 60_000); // max 5 confirmations/min

  const localDate = String(req.data?.localDate ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
    throw new functions.https.HttpsError("invalid-argument", "BAD_DATE");
  }

  // Stable document id ⇒ natural idempotency key.
  const eventRef = db.doc(`wakeup_events/wakeup_${uid}_${localDate}`);

  let alreadyDone = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(eventRef);
    if (snap.exists) {
      alreadyDone = true;
      return;
    }
    tx.set(eventRef, {
      uid,
      localDate,
      selfReported: true,
      requestId: String(req.data?.requestId ?? ""),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  if (alreadyDone) {
    throw new functions.https.HttpsError(
      "already-exists",
      "DUPLICATE_EVENT"
    );
  }

  // Award XP and update the streak in ONE transaction on the user doc.
  const userRef = db.doc(`users/${uid}`);
  const xpGain = 10;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const data = snap.data()!;
    const lastDate: string = data.lastWakeupDate ?? "";

    const yesterday = new Date(localDate);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayKey = yesterday.toISOString().slice(0, 10);

    const streak = lastDate === yesterdayKey ? (data.streak ?? 0) + 1 : 1;
    tx.update(userRef, {
      xp: (data.xp ?? 0) + xpGain,
      streak,
      lastWakeupDate: localDate,
    });
  });

  return { ok: true, xpGain };
});

/**
 * joinTeam — membership changes happen ONLY here. The invitation code is
 * validated server-side; duplicate joins and full teams are rejected.
 */
export const joinTeam = functions.https.onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "AUTH_REQUIRED");
  }

  const code = String(req.data?.code ?? "").trim();
  if (!/^[A-Z0-9]{8}$/.test(code)) {
    throw new functions.https.HttpsError("invalid-argument", "BAD_CODE");
  }

  await rateLimit(uid, "join", 3, 60_000); // max 3 join attempts/min

  const teams = await db
    .collection("teams")
    .where("inviteCode", "==", code)
    .limit(1)
    .get();
  if (teams.empty) {
    throw new functions.https.HttpsError("not-found", "TEAM_NOT_FOUND");
  }
  const team = teams.docs[0];

  const memberRef = team.ref.collection("members").doc(uid);
  let result: "JOINED" | "ALREADY_MEMBER" = "JOINED";
  await db.runTransaction(async (tx) => {
    const memberSnap = await tx.get(memberRef);
    if (memberSnap.exists) {
      result = "ALREADY_MEMBER";
      return;
    }
    const teamSnap = await tx.get(team.ref);
    if ((teamSnap.data()!.memberCount ?? 0) >= 50) {
      throw new functions.https.HttpsError("resource-exhausted", "TEAM_FULL");
    }
    tx.set(memberRef, {
      uid,
      role: "member",
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(team.ref, {
      memberCount: admin.firestore.FieldValue.increment(1),
    });
  });

  return { ok: true, result, teamId: team.id };
});

/**
 * sendCompanionRequest — rate-limited, duplicate-checked, block-checked.
 * The recipient's phone number is NEVER exposed; consent is separate.
 */
export const sendCompanionRequest = functions.https.onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "AUTH_REQUIRED");
  }

  const toUid = String(req.data?.toUid ?? "");
  if (!toUid || toUid === uid) {
    throw new functions.https.HttpsError("invalid-argument", "SELF_REQUEST");
  }

  await rateLimit(uid, "companion", 3, 60_000); // max 3 requests/min

  // Blocked check: the recipient blocked the sender ⇒ refuse.
  const blockSnap = await db
    .doc(`blocked_users/${toUid}`)
    .get();
  const blocks = blockSnap.data() as { list?: string[] } | undefined;
  if (blocks?.list?.includes(uid)) {
    throw new functions.https.HttpsError("permission-denied", "BLOCKED");
  }

  // Duplicate pending request ⇒ refuse instead of spamming.
  const pending = await db
    .collection("companion_requests")
    .where("fromUid", "==", uid)
    .where("toUid", "==", toUid)
    .where("status", "==", "pending")
    .limit(1)
    .get();
  if (!pending.empty) {
    throw new functions.https.HttpsError("already-exists", "DUPLICATE_REQUEST");
  }

  await db.collection("companion_requests").add({
    fromUid: uid,
    toUid,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
