import 'package:flutter/material.dart';
import 'test_screen.dart';

class TestIntroScreen extends StatelessWidget {
  const TestIntroScreen({super.key});

  Widget _infoCard({required IconData icon, required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WPI 검사 안내',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _infoCard(icon: Icons.timer, title: '소요 시간', content: '약 15-20분'),
              _infoCard(icon: Icons.quiz, title: '문항 수', content: '총 60문항'),
              _infoCard(
                icon: Icons.psychology,
                title: '검사 방법',
                content: '각 문항을 읽고 현재 자신의 상태에 가장 가까운 답변을 선택하세요.',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Color(0xFFF57C00)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '정답이 없습니다. 솔직하게 응답해주세요.',
                        style: TextStyle(color: Color(0xFF795548)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('검사 시작', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
