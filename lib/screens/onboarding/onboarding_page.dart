import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/auth/auth.dart';
import 'package:task_tracker/services/onboarding_service.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';

import '../../models/onboarding_content.dart';
import '../../widgets/common/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _pageCount = 0;
  late Future<List<OnboardingContent>> _onboardingData;

  @override
  void initState() {
    super.initState();
    _onboardingData = OnboardingLoader.loadOnboardingData();
  }

  bool get _isLastPage {
    return _onboardingData != null && _currentPage == _pageCount - 1;
  }

  void _handleNext() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.to.markOnboardingAsSeen();
    Get.off(() => AuthWrapper(
          supabase: Supabase.instance.client,
          homeScreen: const BottomNavigationMenu(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<OnboardingContent>>(
        future: _onboardingData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final contents = snapshot.data!;
            _pageCount = contents.length;
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: contents.length,
                    itemBuilder: (context, index) {
                      return OnboardingContentPage(
                        content: contents[index],
                        locale: Localizations.localeOf(context).toString(),
                      );
                    },
                  ),
                ),
                _buildBottomNavigation(contents.length),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBottomNavigation(int pageCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      color: Colors.white,
      child: _isLastPage
          ? AppButtons.primaryButton(
              text: 'Начать',
              onPressed: _completeOnboarding,
            )
          : Row(
              children: [
                _buildPageIndicator(pageCount),
                const Spacer(),
                _buildNextButton(),
              ],
            ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.appPrimary
                : AppColors.dropDownGrey,
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return OutlinedButton(
      style: AppButtonStyles.onboardingButton,
      onPressed: _handleNext,
      child: const Icon(
        Icons.arrow_forward,
        color: Colors.black,
        size: 24,
      ),
    );
  }
}

class OnboardingContentPage extends StatelessWidget {
  final OnboardingContent content;
  final String locale;

  const OnboardingContentPage({
    required this.content,
    required this.locale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final translation =
        OnboardingLoader.getTranslationForLocale(content, locale);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Spacer(),
          Image.asset(
            content.imagePath,
            fit: BoxFit.contain,
          ),
          _buildBottomWidget(translation),
        ],
      ),
    );
  }

  Widget _buildBottomWidget(OnboardingTranslation translation) {
    return ClipRect(
      clipper: const ClipPad(
        padding: EdgeInsets.only(top: 30),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.dropDownGrey,
              blurRadius: 32,
              spreadRadius: -8,
              offset: Offset(0, -8),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translation.title, style: AppTextStyles.titleOnboarding),
            AppSpacing.height16,
            Text(translation.subtitle, style: AppTextStyles.titleMedium),
            AppSpacing.height8,
            Text(translation.text, style: AppTextStyles.onboardingBody),
            if (translation.subtext != null) ...[
              AppSpacing.height8,
              Text(
                translation.subtext!,
                style: AppTextStyles.onboardingBody.copyWith(
                  color: AppColors.secondaryGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClipPad extends CustomClipper<Rect> {
  final EdgeInsets padding;

  const ClipPad({
    this.padding = EdgeInsets.zero
  });

  @override
  Rect getClip(Size size) => padding.inflateRect(Offset.zero & size);

  @override
  bool shouldReclip(ClipPad oldClipper) => oldClipper.padding != padding;
}


class OnboardingLoader {
  static Future<List<OnboardingContent>> loadOnboardingData() async {
    final String response = await rootBundle
        .loadString('assets/onboarding/data/onboarding_data.json');
    final data = json.decode(response) as Map<String, dynamic>;

    return (data['onboarding_screens'] as List)
        .map((item) => OnboardingContent.fromJson(item))
        .toList();
  }

  static OnboardingTranslation getTranslationForLocale(
      OnboardingContent content, String locale) {
    final lang = locale.split('_').first;
    return content.translations[lang] ?? content.translations['en']!;
  }
}
