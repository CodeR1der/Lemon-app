class OnboardingContent {
  final String imagePath;
  final Map<String, OnboardingTranslation> translations;

  OnboardingContent({
    required this.imagePath,
    required this.translations,
  });

  factory OnboardingContent.fromJson(Map<String, dynamic> json) {
    return OnboardingContent(
      imagePath: json['image'],
      translations: (json['translations'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, OnboardingTranslation.fromJson(value)),
      ),
    );
  }
}

class OnboardingTranslation {
  final String title;
  final String subtitle;
  final String text;
  final String? subtext;

  OnboardingTranslation({
    required this.title,
    required this.subtitle,
    required this.text,
    this.subtext,
  });

  factory OnboardingTranslation.fromJson(Map<String, dynamic> json) {
    return OnboardingTranslation(
      title: json['title'],
      subtitle: json['subtitle'],
      text: json['text'],
      subtext: json['subtext'],
    );
  }
}