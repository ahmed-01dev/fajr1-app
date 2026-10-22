import 'package:flutter/material.dart';

import '../../core/theme/fajr_theme.dart';
import 'adhkar_data.dart';

/// Morning adhkar reader. Pure offline reading — no network, no fake data.
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FajrTheme.navyDeep,
      appBar: AppBar(title: const Text('أذكار الصباح')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kMorningAdhkar.length,
        itemBuilder: (context, index) {
          final dhikr = kMorningAdhkar[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: FajrTheme.gold,
                        radius: 14,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: FajrTheme.navyDeep,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (dhikr.count > 1)
                        Chip(
                          backgroundColor: FajrTheme.emerald,
                          label: Text(
                            '×${dhikr.count}',
                            style: const TextStyle(
                              color: FajrTheme.navyDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dhikr.text,
                    style: FajrTheme.headline.copyWith(fontSize: 17, height: 1.9),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '📖 ${dhikr.source}',
                    style: FajrTheme.label,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
