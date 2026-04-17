import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dio/dio.dart'; // Require Dio for Exception handling
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../providers/app_providers.dart';

void showPremiumModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const PremiumModal(),
  );
}

class PremiumModal extends ConsumerStatefulWidget {
  const PremiumModal({super.key});

  @override
  ConsumerState<PremiumModal> createState() => _PremiumModalState();
}

class _PremiumModalState extends ConsumerState<PremiumModal> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final api = ref.read(apiServiceProvider);

      // 1. Send verification to backend (Next.js logs/confirms, though DB is updated by Webhook)
      try {
        await api.verifyRazorpayPayment(
          orderId: response.orderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );
      } catch (e) {
         print('Payment verified by gateway, but backend proxy returned error: $e');
      }

      // 2. Poll for the Webhook to actually update the DB
      bool isPremium = false;
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 2));
        await authNotifier.refreshPremium();
        final authState = ref.read(authProvider);
        if (authState.isPremium) {
          isPremium = true;
          break;
        }
      }
      
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context); // Close modal
        
        if (isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to Premium! 🎉', style: AppTheme.inter(size: 13, weight: FontWeight.w600, color: Colors.black)),
              backgroundColor: AppTheme.accentYellow,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment received! Your premium status will activate shortly.', style: AppTheme.inter(size: 13, color: Colors.white)),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Payment received, but error syncing status.');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed or cancelled.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet not supported.');
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: AppTheme.inter(size: 13, color: Colors.white)),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startCheckout() async {
    if (_isProcessing) return;

    final auth = ref.read(authProvider);
    if (!auth.isClerkSignedIn) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed('/clerk-login');
      return;
    }

    setState(() => _isProcessing = true);
    final api = ref.read(apiServiceProvider);

    try {
      // 0. Double-check clerk_id sync to prevent 400/hang
      if (auth.clerkUserId != null) {
        api.setClerkUserId(auth.clerkUserId);
      }

      // 1. Create order on backend (with 30s timeout now in ApiService)
      final orderRes = await api.createRazorpayOrder();
      final orderId = orderRes['orderId'];
      final amount = orderRes['amount'];
      final currency = orderRes['currency'];
      final backendKeyId = orderRes['key_id'];

      final user = ClerkAuth.of(context).user;
      
      // 2. Open Razorpay native checkout
      final Map<String, dynamic> options = {
        'key': backendKeyId ?? ApiConfig.razorpayKeyId,
        'amount': amount,
        'currency': currency,
        'name': 'ValoCoach.AI',
        'description': 'Premium Subscription',
        'order_id': orderId,
        'theme': {
          'color': '#f53d4c' // ValoCoach Red
        }
      };
      
      final email = (user?.emailAddresses != null && user!.emailAddresses!.isNotEmpty)
              ? user.emailAddresses![0].emailAddress 
              : null;
              
      if (email != null && email.isNotEmpty) {
        options['prefill'] = {'email': email};
      }

      print('[Razorpay] attempt to open modal with options: $options');
      _razorpay.open(options);
    } on DioException catch (de) {
      if (de.type == DioExceptionType.connectionTimeout || de.type == DioExceptionType.receiveTimeout) {
        _showError('Server is waking up (Render cold start). Please try again in 10 seconds.');
      } else {
        _showError('Backend Error: ${de.message ?? de.toString()}');
      }
    } catch (e) {
      _showError('Checkout Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    
    return Container(
      height: height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Content
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('ValoCoach.', style: AppTheme.krona(size: 18, color: AppTheme.primaryRed)),
                              Text('Premium', style: AppTheme.inter(size: 18, weight: FontWeight.w900, color: AppTheme.accentYellow, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Unlock your full potential', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Scrollable features
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Video placeholder or graphic
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('assets/agents/jett.png'), // placeholder
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                          border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.3)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppTheme.darkBg.withValues(alpha: 0.9)],
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(20),
                          child: Text('DOMINATE YOUR RANK', style: AppTheme.krona(size: 20, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Features grid
                      _FeatureBlock(
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFf53d4c),
                        title: 'AI MATCH ANALYSIS',
                        description: 'Radiant-level coaching review of every match with deep stats and actionable tips.',
                      ),
                      const SizedBox(height: 16),
                      _FeatureBlock(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFa855f7),
                        title: 'SMART QUESTS',
                        description: 'Personalized daily and weekly challenges tailored to your weaknesses.',
                      ),
                      const SizedBox(height: 16),
                      _FeatureBlock(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFfbbf24),
                        title: 'BATTLE PASS',
                        description: 'XP progression system fully integrated with your in-game performance.',
                      ),
                      const SizedBox(height: 16),
                      _FeatureBlock(
                        icon: Icons.card_giftcard_rounded,
                        color: const Color(0xFF10b981),
                        title: 'REAL REWARDS',
                        description: 'Level up to unlock Valorant Points (VP) and exclusive gaming gear.',
                      ),
                      
                      const SizedBox(height: 100), // padding for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom sticky button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBg.withValues(alpha: 0),
                    AppTheme.darkBg,
                    AppTheme.darkBg,
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: _startCheckout,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFdaa520), Color(0xFFb8860b)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFdaa520).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Center(
                    child: _isProcessing 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text('JOIN AT ₹99 / MONTH', style: AppTheme.krona(size: 14, color: Colors.black, letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.krona(size: 12, color: color, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(description, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
