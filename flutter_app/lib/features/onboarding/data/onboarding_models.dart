class OnboardingQuery {
  const OnboardingQuery({
    this.scene = 'first_launch',
    this.version = '',
    this.locale = 'en-US',
  });

  final String scene;
  final String version;
  final String locale;

  Map<String, dynamic> toQueryParameters() {
    return {'scene': scene, 'version': version, 'locale': locale};
  }

  @override
  bool operator ==(Object other) {
    return other is OnboardingQuery &&
        other.scene == scene &&
        other.version == version &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(scene, version, locale);
}

class OnboardingPage {
  const OnboardingPage({
    required this.id,
    required this.scene,
    required this.version,
    required this.locale,
    required this.title,
    required this.description,
    required this.image,
    required this.buttonText,
    required this.actionType,
    required this.actionValue,
    required this.sort,
  });

  final int id;
  final String scene;
  final String version;
  final String locale;
  final String title;
  final String description;
  final String image;
  final String buttonText;
  final String actionType;
  final String actionValue;
  final int sort;

  factory OnboardingPage.fromJson(Map<String, dynamic> json) {
    return OnboardingPage(
      id: _intValue(json['id']),
      scene: _stringValue(json['scene'], fallback: 'first_launch'),
      version: _stringValue(json['version']),
      locale: _stringValue(json['locale'], fallback: 'en-US'),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      image: _stringValue(json['image']),
      buttonText: _stringValue(json['button_text']),
      actionType: _stringValue(json['action_type'], fallback: 'next'),
      actionValue: _stringValue(json['action_value']),
      sort: _intValue(json['sort'], fallback: 100),
    );
  }

  OnboardingPage copyWith({
    int? id,
    String? scene,
    String? version,
    String? locale,
    String? title,
    String? description,
    String? image,
    String? buttonText,
    String? actionType,
    String? actionValue,
    int? sort,
  }) {
    return OnboardingPage(
      id: id ?? this.id,
      scene: scene ?? this.scene,
      version: version ?? this.version,
      locale: locale ?? this.locale,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      buttonText: buttonText ?? this.buttonText,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      sort: sort ?? this.sort,
    );
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }
}
