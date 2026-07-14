import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep only the status bar (top), hide Android nav buttons (bottom).
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  // Dark status bar with light icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0A0A0A),
    statusBarIconBrightness: Brightness.light,
  ));
  // Portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const FlipMeetApp());
}

// ─── Root widget ─────────────────────────────────────────────────────────────

class FlipMeetApp extends StatelessWidget {
  const FlipMeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlipMeet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>    _fade;
  late Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WebViewScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / emoji
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.45),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💬', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ).createShader(bounds),
                  child: const Text(
                    'FlipMeet',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Meet someone new',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WebView Screen ──────────────────────────────────────────────────────────

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isOffline = false;
  bool _isLoading = true;
  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  static const String _liveUrl = 'https://flipmeet.fun';

  // JS injected after every page load.
  // • Fixes viewport meta for correct scaling
  // • visualViewport: scrolls active input into view when keyboard opens
  // • Scrolls chat containers to bottom when keyboard opens
  // • Prevents context-menu on non-interactive elements
  // • Prevents double-tap zoom
  static const String _injectJs = r"""
(function() {
  try {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) { m = document.createElement('meta'); m.name = 'viewport'; document.head.appendChild(m); }
    m.content = 'width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover';

    if (window.visualViewport) {
      function onVPChange() {
        var diff = window.innerHeight - window.visualViewport.height;
        if (diff > 150) {
          var el = document.activeElement;
          if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
            setTimeout(function() {
              el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }, 80);
          }
          ['[class*=message]','[class*=Message]','[class*=chat]','[class*=Chat]']
            .forEach(function(s) {
              document.querySelectorAll(s).forEach(function(e) {
                if (e.scrollHeight > e.clientHeight) e.scrollTop = e.scrollHeight;
              });
            });
        }
      }
      window.visualViewport.addEventListener('resize', onVPChange);
      window.visualViewport.addEventListener('scroll', onVPChange);
    }

    document.addEventListener('contextmenu', function(e) {
      var t = e.target.tagName;
      if (t !== 'INPUT' && t !== 'TEXTAREA' && t !== 'A') e.preventDefault();
    });

    var _lastTap = 0;
    document.addEventListener('touchend', function(e) {
      var now = Date.now();
      if (now - _lastTap < 300) e.preventDefault();
      _lastTap = now;
    }, { passive: false });
  } catch (ex) {}
})();
""";

  @override
  void initState() {
    super.initState();
    _setupController();
    _listenConnectivity();
  }

  void _setupController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..setUserAgent(
        // Remove "wv" so the site serves full Chrome-mobile experience
        'Mozilla/5.0 (Linux; Android 11; Pixel 5) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() { _isLoading = true; _isOffline = false; }),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_injectJs);
            // Re-hide nav buttons after page finishes
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [SystemUiOverlay.top],
            );
          },
          onWebResourceError: (err) {
            if (err.isForMainFrame == true) {
              setState(() { _isOffline = true; _isLoading = false; });
            }
          },
        ),
      )
      ..setOnPlatformPermissionRequest(
        // Automatically grant camera / mic requests from the site
        (request) => request.grant(),
      );

    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final online = await _checkOnline();
    if (online) {
      _controller.loadRequest(Uri.parse(_liveUrl));
    } else {
      setState(() { _isOffline = true; _isLoading = false; });
    }
  }

  Future<bool> _checkOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty &&
             !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  void _listenConnectivity() {
    _connectSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty &&
                     !results.contains(ConnectivityResult.none);
      if (online && _isOffline) {
        setState(() { _isOffline = false; _isLoading = true; });
        _controller.loadRequest(Uri.parse(_liveUrl));
      }
    });
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Restore immersive mode whenever the widget rebuilds (e.g. after keyboard)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        resizeToAvoidBottomInset: true, // WebView shrinks when keyboard opens
        body: Stack(
          children: [
            // ── WebView (always in tree so state is kept) ──────────────────
            Visibility(
              visible: !_isOffline,
              maintainState: true,
              child: WebViewWidget(controller: _controller),
            ),

            // ── Offline / error screen ─────────────────────────────────────
            if (_isOffline)
              _OfflineScreen(onRetry: () {
                setState(() { _isOffline = false; _isLoading = true; });
                _loadUrl();
              }),

            // ── No chrome loading indicator needed ─────────────────────────
            // (removed intentionally per design)
          ],
        ),
      ),
    );
  }
}

// ─── Offline Screen ───────────────────────────────────────────────────────────

class _OfflineScreen extends StatefulWidget {
  final VoidCallback onRetry;
  const _OfflineScreen({required this.onRetry});

  @override
  State<_OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<_OfflineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand name
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ).createShader(b),
                  child: const Text(
                    'FlipMeet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Pulsing icon
                FadeTransition(
                  opacity: Tween(begin: 0.4, end: 1.0).animate(_pulse),
                  child: const Text('📡', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your WiFi or mobile data,\nthen tap Retry to reconnect.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9CA3AF),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
