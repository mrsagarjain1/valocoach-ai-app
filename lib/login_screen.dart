import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String riotAuthUrl = 
      "https://auth.riotgames.com/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&scope=account%20openid&nonce=1";

  InAppWebViewController? webViewController;
  CookieManager cookieManager = CookieManager.instance();

  @override
  void initState() {
    super.initState();
    _clearCookies();
  }

  Future<void> _clearCookies() async {
    await cookieManager.deleteAllCookies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riot Login")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(riotAuthUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          clearCache: true,
          useShouldOverrideUrlLoading: true,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
           if (url != null) {
             _handleUrlChanged(url.toString(), "start");
           }
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
           if (url != null) {
             _handleUrlChanged(url.toString(), "history");
           }
        },
        onLoadStop: (controller, url) async {
           if (url != null) {
             _handleUrlChanged(url.toString(), "stop");
           }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var url = navigationAction.request.url.toString();
          if (url.contains("access_token=")) {
            _handleUrlChanged(url, "override");
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Manual emergency close just in case
          Navigator.pop(context);
        },
        child: const Icon(Icons.close),
        tooltip: 'Close Page',
      ),
    );
  }

  bool _isPopped = false;

  Future<void> _handleUrlChanged(String urlStr, String source) async {
    print("WebView URL Changed ($source): $urlStr");
    
    if (_isPopped) return;

    if (urlStr.contains("access_token=")) {
      print("Token found in URL ($source)!");
      
      // Sometimes the token is after a '#' and sometimes a '?'
      Uri uri = Uri.parse(urlStr.replaceFirst('#', '?'));
      String? accessToken = uri.queryParameters['access_token'];
      String? idToken = uri.queryParameters['id_token'];

      if (accessToken != null && accessToken.isNotEmpty) {
        _isPopped = true;
        
        try {
          // Fetch ALL cookies to be safe, searching both auth and playvalorant domains
          List<Cookie> authCookies = await cookieManager.getCookies(url: WebUri("https://auth.riotgames.com"));
          List<Cookie> playCookies = await cookieManager.getCookies(url: WebUri("https://playvalorant.com"));
          
          List<Cookie> allCookies = [...authCookies, ...playCookies];
          
          String cookieStr = "";
          for (var cookie in allCookies) {
             // Avoid duplicating cookies
             if (!cookieStr.contains("${cookie.name}=")) {
               cookieStr += "${cookie.name}=${cookie.value};\n";
             }
          }

          print("Successfully grabbed token & cookies");

          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, {
                  "access_token": accessToken,
                  "id_token": idToken ?? "",
                  "cookies": cookieStr,
                });
              }
            });
          }
        } catch (e) {
          print("Error fetching cookies: $e");
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, {
                  "access_token": accessToken,
                  "id_token": idToken ?? "",
                  "cookies": "Error getting cookies: $e",
                });
              }
            });
          }
        }
      }
    }
  }
}
