import 'package:flutter/material.dart';
import '../../models/wpi_result.dart';
import 'existence_detail_screen.dart';
import '../../utils/main_shell_tab_controller.dart';
import '../main_shell.dart';

class ResultSummaryScreen extends StatelessWidget {
  final WpiResult result;
  const ResultSummaryScreen({super.key, required this.result});

  void _goHome(BuildContext context) {
    MainShellTabController.index.value = 0;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(result.existenceType),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.insights, size: 64, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.format_quote,
                                color: Color(0xFFF57C00), size: 28),
                            SizedBox(width: 12),
                            Text('핵심 메시지',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(result.coreMessage,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF424242))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('당신의 마음 구조',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        _lineIndicator(
                          label: '빨간선 (자기 믿음)',
                          value: result.redLineValue,
                          color: Colors.red,
                          description: result.redLineDescription,
                        ),
                        const SizedBox(height: 24),
                        _lineIndicator(
                          label: '파란선 (내면화된 기준)',
                          value: result.blueLineValue,
                          color: Colors.blue,
                          description: result.blueLineDescription,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gap 분석',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF795548))),
                              const SizedBox(height: 8),
                              Text(result.gapAnalysis,
                                  style: const TextStyle(
                                      color: Color(0xFF5D4037), height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.favorite,
                                color: Color(0xFFE91E63), size: 24),
                            SizedBox(width: 12),
                            Text('감정 신호',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.emotionalSignals
                              .map((signal) => Chip(
                                    label: Text(signal),
                                    backgroundColor: const Color(0xFFFFE0EC),
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF880E4F)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.accessibility_new,
                                color: Color(0xFF4CAF50), size: 24),
                            SizedBox(width: 12),
                            Text('몸 신호',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...result.bodySignals.map(
                          (signal) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 20, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(signal,
                                      style: const TextStyle(
                                          fontSize: 14, height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExistenceDetailScreen(result: result),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('존재 구조 상세 분석 보기',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _goHome(context),
                      child: const Text('대시보드로 이동'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _lineIndicator({
    required String label,
    required double value,
    required Color color,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 8),
        Text(description),
      ],
    );
  }
}
