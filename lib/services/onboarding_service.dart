import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends GetxService {
  static OnboardingService get to => Get.find();

  final RxBool _hasSeenOnboarding = false.obs;

  bool get hasSeenOnboarding =>  _hasSeenOnboarding.value;

  @override
  void onInit() {
    super.onInit();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding.value = prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      print('Ошибка загрузки состояния онбординга: $e');
      _hasSeenOnboarding.value = false;
    }
  }

  // Метод для ожидания инициализации
  Future<void> waitForInitialization() async {
    // Просто ждем немного, чтобы SharedPreferences успел загрузиться
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> markOnboardingAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      _hasSeenOnboarding.value = true;
    } catch (e) {
      print('Ошибка сохранения состояния онбординга: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', false);
      _hasSeenOnboarding.value = false;
    } catch (e) {
      print('Ошибка сброса состояния онбординга: $e');
    }
  }
}
