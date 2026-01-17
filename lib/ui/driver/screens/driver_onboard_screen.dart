import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'driver_splash_screen.dart';

class DriverOnboardScreen extends ConsumerStatefulWidget {
  const DriverOnboardScreen({super.key});

  @override
  ConsumerState<DriverOnboardScreen> createState() =>
      _DriverOnboardScreenState();
}

class _DriverOnboardScreenState extends ConsumerState<DriverOnboardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Start Earning',
      description:
          'Drive with Drup and earn money on your own schedule. Set your own hours and be your own boss.',
      icon: Icons.attach_money,
      color: Color(0xff5490D0),
    ),
    OnboardingPage(
      title: 'Safe & Secure',
      description:
          'Your safety is our priority. All rides are tracked and monitored for your protection.',
      icon: Icons.security,
      color: Color(0xff4B7DB8),
    ),
    OnboardingPage(
      title: 'Get Started',
      description:
          'Join thousands of drivers already earning with Drup. Start your journey today!',
      icon: Icons.rocket_launch,
      color: Color(0xff253B80),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onGetStarted() {
    // Mark onboarding as shown
    ref.read(driverOnboardingShownProvider.notifier).state = true;

    // Navigate to driver home
    context.go(AppRoutes.driverHomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _pages[_currentPage].color,
                _pages[_currentPage].color.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _onGetStarted,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Dot indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),

                const Gap(40),

                // Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: CustomButton(
                    text: 'Get Started',
                    onPressed: _onGetStarted,
                    backgroundColor: Colors.white,
                    textColor: _pages[_currentPage].color,
                  ),
                ),

                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(page.icon, size: 60, color: Colors.white),
          ),

          const Gap(60),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Gap(24),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyles.t1.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
