import 'package:ebroker/exports/main_export.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    required this.url,
    required this.gateway,
    super.key,
  });

  final String url;
  final String gateway;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await _initializeWebView();
    });
  }

  Future<void> _initializeWebView() async {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (_interceptUrl(request.url)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {},
        onPageFinished: (url) {
          setState(() {
            isLoading = false;
          });
        },
        onWebResourceError: (error) {},
        onUrlChange: (change) {
          _interceptUrl(change.url);
        },
      ),
    );
    // Enable debugging for Android
    if (controller.platform is AndroidWebViewController) {
      await AndroidWebViewController.enableDebugging(true);
      await (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    await controller.loadRequest(Uri.parse(widget.url));
    _controller = controller;
  }

  // Returns true if URL was intercepted (navigation should be prevented).
  bool _interceptUrl(String? urlString) {
    if (urlString == null) return false;
    final uri = Uri.parse(urlString);

    final isBackendHost = uri.host == Uri.parse(AppConfig.baseUrl).host;

    if (!isBackendHost &&
        widget.gateway.toLowerCase() != 'paypal' &&
        widget.gateway.toLowerCase() != 'flutterwave') {
      return false;
    }

    if (urlString.contains('app_payment_status')) {
      // PayPal: error=false + PayerID = success, anything else = cancel/fail
      final error = uri.queryParameters['error'];
      final payerId = uri.queryParameters['PayerID'];
      Navigator.pop(context, error == 'false' && payerId != null);
      return true;
    } else if (urlString.contains('flutterwave-payment-status')) {
      final status = uri.queryParameters['status'];
      Navigator.pop(context, status == 'successful');
      return true;
    } else if (urlString.contains('cancel') ||
        uri.queryParameters['status'] == 'cancel' ||
        uri.queryParameters['status'] == 'cancelled') {
      Navigator.pop(context, false);
      return true;
    } else if (urlString.contains('success') ||
        uri.queryParameters['status'] == 'success') {
      Navigator.pop(context, true);
      return true;
    } else if (urlString.contains('fail') ||
        uri.queryParameters['status'] == 'failed') {
      Navigator.pop(context, false);
      return true;
    }

    return false;
  }

  Future<void> _handleBackPress() async {
    final now = DateTime.now();
    final timeDifference = _lastBackPressTime == null
        ? const Duration(seconds: 3)
        : now.difference(_lastBackPressTime!);

    if (timeDifference > const Duration(seconds: 2)) {
      // First back press - show warning toast
      _lastBackPressTime = now;
      await Fluttertoast.showToast(
        msg:
            'If you go back, payment will be cancelled. Press back again to exit.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      // Second back press within 2 seconds - exit with false (payment cancelled)
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.gateway.toUpperCase(),
          showBackButton: false,
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: context.color.tertiaryColor,
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
