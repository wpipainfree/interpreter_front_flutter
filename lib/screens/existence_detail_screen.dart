import 'package:flutter/material.dart';
import '../models/wpi_result.dart';

class ExistenceDetailScreen extends StatelessWidget {
  final WpiResult result;
  const ExistenceDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('존재 구조 상세')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(result.existenceType,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(result.coreMessage, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            const Text('해석 가이드',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                '빨간선(자기 믿음)과 파란선(내면화된 기준) 간의 간격을 확인하고, 감정/몸 신호를 함께 살펴보세요.'),
            const SizedBox(height: 16),
            _bullet('빨간선이 높은 경우: 자기 확신이 강하며 목표 지향적입니다.'),
            _bullet('파란선이 높은 경우: 외부 기준을 중시하며 규율을 잘 따릅니다.'),
            _bullet('간격이 큰 경우: 내적 갈등이나 피로감이 느껴질 수 있습니다.'),
            const SizedBox(height: 16),
            const Text('추천 액션',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _bullet('일상 루틴에서 짧은 호흡 명상을 시도해보세요.'),
            _bullet('감정 일지를 작성하며 감정/몸 신호를 기록하세요.'),
            _bullet('필요시 전문 상담사와의 대화를 통해 조율하세요.'),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
