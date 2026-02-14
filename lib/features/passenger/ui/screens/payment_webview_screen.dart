import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.onPaymentComplete,
  });

  final String authorizationUrl;
  final VoidCallback onPaymentComplete;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ridePayChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Payment completed — trigger callback
          widget.onPaymentComplete();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept callback URLs (e.g., Paystack redirect)
            if (request.url.contains('paystack.co/close') ||
                request.url.contains('callback') ||
                request.url.contains('payment/verify')) {
              widget.onPaymentComplete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Make Payment',
          style: TextStyles.t1.copyWith(
            fontSize: FontSizes.s18,
            fontWeight: FontWeight.w700,
            color: AppColors.onAccent,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Padding(
              padding: EdgeInsetsGeometry.only(top: height * 0.2),
              child: SizedBox.square(
                dimension: 30,
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
