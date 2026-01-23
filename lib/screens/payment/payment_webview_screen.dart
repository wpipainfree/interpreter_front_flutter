import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';
import '../../utils/app_colors.dart';

/// 결제 결과
class PaymentResult {
  final bool success;
  final int? paymentId;
  final String? message;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.message,
  });

  factory PaymentResult.success(int paymentId) =>
      PaymentResult(success: true, paymentId: paymentId);

  factory PaymentResult.failed(String message) =>
      PaymentResult(success: false, message: message);

  factory PaymentResult.cancelled() =>
      const PaymentResult(success: false, message: '결제가 취소되었습니다.');
}

/// INICIS 모바일 결제 WebView 화면
class PaymentWebViewScreen extends StatefulWidget {
  final String webviewUrl;
  final int paymentId;

  const PaymentWebViewScreen({
    super.key,
    required this.webviewUrl,
    required this.paymentId,
  });

  /// 결제 화면 열기 (플랫폼 자동 감지)
  static Future<PaymentResult?> open(
    BuildContext context, {
    required String webviewUrl,
    required int paymentId,
  }) async {
    if (kIsWeb) {
      final uri = Uri.parse(webviewUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          return await showDialog<PaymentResult>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _WebPaymentDialog(paymentId: paymentId),
          );
        }
        return null;
      } else {
        return PaymentResult.failed('결제 페이지를 열 수 없습니다.');
      }
    } else {
      if (!context.mounted) return null;
      return await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            webviewUrl: webviewUrl,
            paymentId: paymentId,
          ),
        ),
      );
    }
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isProcessing = false; // 중복 Navigator.pop 방지
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white) // 검은 화면 방지
      ..setUserAgent(null) // 기본 User-Agent 사용 (INICIS 호환성)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _progress = progress / 100);
          },
          onPageStarted: (url) {
            if (url.contains('/inicis/mobile/return') ||
                url.contains('payment/success') ||
                url.contains('payment/fail')) {
              setState(() => _isVerifying = true);
            }
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (url.contains('/inicis/mobile/return') ||
                url.contains('payment/success') ||
                url.contains('payment/fail')) {
              setState(() => _isVerifying = true);
              _checkPageContent();
            } else {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('[PaymentWebView] Navigation: $url');

            if (url.contains('/inicis/mobile/return')) {
              setState(() => _isVerifying = true);
            }

            if (url.contains('status=success') ||
                url.contains('payment/success')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }

            if (url.contains('status=fail') ||
                url.contains('payment/fail') ||
                url.contains('status=cancel') ||
                url.contains('payment/cancel')) {
              _handlePaymentFailed();
              return NavigationDecision.prevent;
            }

            if (url.startsWith('wpiapp://')) {
              _handleDeepLink(url);
              return NavigationDecision.prevent;
            }

            // 외부 앱 스킴 처리 (카드사 앱, 은행 앱 등)
            // about:, javascript:, data: 등은 제외
            if (!url.startsWith('http://') &&
                !url.startsWith('https://') &&
                !url.startsWith('about:') &&
                !url.startsWith('javascript:') &&
                !url.startsWith('data:')) {
              _launchExternalApp(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[PaymentWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webviewUrl));
  }

  void _handlePaymentSuccess() async {
    // 중복 처리 방지
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final paymentService = PaymentService();
      final status = await paymentService.getPaymentStatus(widget.paymentId);
      if (mounted) {
        Navigator.pop(
          context,
          status.isSuccess
              ? PaymentResult.success(widget.paymentId)
              : PaymentResult.failed(status.errorMessage ?? '결제 확인에 실패했습니다.'),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, PaymentResult.success(widget.paymentId));
      }
    }
  }

  void _handlePaymentFailed() {
    // 중복 처리 방지
    if (_isProcessing) return;
    _isProcessing = true;

    if (mounted) {
      Navigator.pop(context, PaymentResult.failed('결제에 실패했습니다.'));
    }
  }

  Future<void> _checkPageContent() async {
    try {
      final textContent = await _controller.runJavaScriptReturningResult(
        'document.body.innerText',
      );

      debugPrint('[PaymentWebView] Result Page Text: $textContent');

      if (textContent is String) {
        final rawJson =
            textContent.replaceAll(r'\"', '"').replaceAll(r'\n', '');
        final cleanJson = rawJson.startsWith('"') && rawJson.endsWith('"')
            ? rawJson.substring(1, rawJson.length - 1)
            : rawJson;

        if (cleanJson.contains('detail') || cleanJson.contains('errors')) {
          try {
            final Map<String, dynamic> data = jsonDecode(cleanJson);
            if (data.containsKey('detail')) {
              final detail = data['detail'];
              if (detail is String) {
                if (mounted) {
                  Navigator.pop(
                      context, PaymentResult.failed('결제 오류: $detail'));
                }
                return;
              }
            }
          } catch (_) {
            // JSON 파싱 실패
          }
        }
      }

      _handlePaymentSuccess();
    } catch (e) {
      debugPrint('[PaymentWebView] Error checking page content: $e');
      _handlePaymentSuccess();
    }
  }

  void _handleDeepLink(String url) {
    debugPrint('[PaymentWebView] DeepLink received: $url');
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];

    if (status == 'success') {
      _handlePaymentSuccess();
    } else if (status == 'cancelled' || status == 'cancel') {
      // 취소 시 즉시 화면 닫기 (백엔드 조회 없이)
      if (_isProcessing) return;
      _isProcessing = true;
      if (mounted) {
        Navigator.pop(context, PaymentResult.cancelled());
      }
    } else {
      _handlePaymentFailed();
    }
  }

  Future<void> _launchExternalApp(String url) async {
    debugPrint('[PaymentWebView] Launching external app: $url');
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[PaymentWebView] Cannot launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제 앱을 열 수 없습니다. 앱이 설치되어 있는지 확인해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[PaymentWebView] Error launching external app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, PaymentResult.cancelled());
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          if (_isVerifying)
            Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '결제 결과를 확인하고 있습니다...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 웹 플랫폼용 결제 확인 다이얼로그
class _WebPaymentDialog extends StatefulWidget {
  final int paymentId;

  const _WebPaymentDialog({required this.paymentId});

  @override
  State<_WebPaymentDialog> createState() => _WebPaymentDialogState();
}

class _WebPaymentDialogState extends State<_WebPaymentDialog> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final paymentService = PaymentService();
      final status = await paymentService.getPaymentStatus(widget.paymentId);

      if (!mounted) return;

      if (status.isSuccess) {
        Navigator.pop(context, PaymentResult.success(widget.paymentId));
      } else if (status.isFailed) {
        Navigator.pop(
          context,
          PaymentResult.failed(status.errorMessage ?? '결제에 실패했습니다.'),
        );
      } else {
        setState(() {
          _statusMessage = '결제가 아직 완료되지 않았습니다.\nINICIS 결제창에서 결제를 진행해주세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '상태 확인 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payment, color: Colors.blue),
          SizedBox(width: 8),
          Text('결제 진행 중'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 탭에서 INICIS 결제창이 열렸습니다.\n\n'
            '1. 결제 수단을 선택하고 결제를 완료하세요\n'
            '2. 결제 완료 후 아래 버튼을 눌러주세요',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_isChecking)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('결제 상태 확인 중...'),
                ],
              ),
            )
          else if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                          color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isChecking
              ? null
              : () => Navigator.pop(context, PaymentResult.cancelled()),
          child: const Text('취소'),
        ),
        ElevatedButton.icon(
          onPressed: _isChecking ? null : _checkPaymentStatus,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('결제 완료 확인'),
        ),
      ],
    );
  }
}
