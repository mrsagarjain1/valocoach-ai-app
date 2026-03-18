import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config/app_theme.dart';

/// Riot Login via WebView.
/// Pop returns `Map<String, String>?` with `{'puuid': ..., 'token': ...}`
class RiotLoginScreen extends StatefulWidget {
  const RiotLoginScreen({super.key});

  @override
  State<RiotLoginScreen> createState() => _RiotLoginScreenState();
}

class _RiotLoginScreenState extends State<RiotLoginScreen> {
  InAppWebViewController? _webCtrl;
  bool _loading = true;
  bool _captured = false;
  String? _statusMsg;

  // The Riot SSO URL — same one the web app uses
  static const _riotUrl =
      'https://auth.riotgames.com/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&nonce=1&scope=openid%20link%20ban%20lol%20offline_access%20openid';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text('LINK RIOT ACCOUNT', style: AppTheme.krona(size: 14, letterSpacing: 1)),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(color: AppTheme.primaryRed, backgroundColor: AppTheme.cardBg),
              )
            : null,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_riotUrl)),
            initialSettings: InAppWebViewSettings(
              userAgent:
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              javaScriptEnabled: true,
              domStorageEnabled: true,
              allowsBackForwardNavigationGestures: true,
            ),
            onWebViewCreated: (c) => _webCtrl = c,
            onLoadStart: (c, url) {
              setState(() => _loading = true);
              _interceptUrl(url?.toString() ?? '');
            },
            onLoadStop: (c, url) async {
              setState(() => _loading = false);

              // Also check for token in URL after redirect
              _interceptUrl(url?.toString() ?? '');

              // Try to get token from cookies too
              await _tryGetCookieToken(url?.toString() ?? '');
            },
            onReceivedError: (c, req, err) {
              // Ignore if we already captured
              if (!_captured) {
                setState(() => _statusMsg = 'Error: ${err.description}');
              }
            },
          ),

          // Status overlay when capture happens
          if (_statusMsg != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _captured ? AppTheme.accentGreen : AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _captured ? Icons.check_circle_outline : Icons.error_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_statusMsg!, style: AppTheme.inter(size: 13, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _interceptUrl(String url) {
    if (_captured) return;

    // Intercept the access_token from the redirect URL fragment
    if (url.contains('access_token=')) {
      final uri = Uri.parse(url.replaceFirst('#', '?'));
      final token = uri.queryParameters['access_token'];
      if (token != null && token.isNotEmpty) {
        _onTokenCaptured(token);
      }
    }

    // Intercept the openwrt / opt_in redirect (success page)
    if (url.contains('/opt_in') && url.contains('code=')) {
      setState(() => _statusMsg = 'Login successful! Processing...');
    }
  }

  Future<void> _tryGetCookieToken(String url) async {
    if (_captured) return;
    if (_webCtrl == null) return;

    // Try to inject JS to read the token from localStorage or cookies
    try {
      final result = await _webCtrl!.evaluateJavascript(source: '''
        (function() {
          var token = null;
          // Check cookies
          var cookies = document.cookie;
          var match = cookies.match(/access_token=([^;]+)/);
          if (match) token = match[1];
          
          // Check URL hash
          var hash = window.location.hash;
          var hashMatch = hash.match(/access_token=([^&]+)/);
          if (hashMatch) token = hashMatch[1];
          
          // Check URL search
          var search = window.location.search;
          var searchMatch = search.match(/access_token=([^&]+)/);
          if (searchMatch) token = searchMatch[1];
          
          return token;
        })()
      ''');

      if (result != null && result != 'null' && result.toString().length > 20) {
        _onTokenCaptured(result.toString().replaceAll('"', ''));
      }
    } catch (_) {
      // Ignore JS errors
    }
  }

  void _onTokenCaptured(String token) {
    if (_captured) return;
    _captured = true;

    setState(() => _statusMsg = '✓ Riot account linked!');

    // Decode basic info from token (JWT payload)
    String? puuid;
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = base64Decode(_padBase64(parts[1]));
        final json = String.fromCharCodes(payload);
        // Simple regex extraction
        final puuidMatch = RegExp(r'"sub":"([^"]+)"').firstMatch(json);
        puuid = puuidMatch?.group(1);
      }
    } catch (_) {}

    // Pop back with result after brief success display
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop({
          'token': token,
          'puuid': puuid ?? '',
        });
      }
    });
  }

  String _padBase64(String s) {
    while (s.length % 4 != 0) {
      s += '=';
    }
    return s.replaceAll('-', '+').replaceAll('_', '/');
  }
}
