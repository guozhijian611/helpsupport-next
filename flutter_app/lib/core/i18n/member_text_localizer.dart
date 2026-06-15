import 'package:flutter/widgets.dart';

import 'l10n_extensions.dart';

const String normalizedGenderMale = 'male';
const String normalizedGenderFemale = 'female';
const String normalizedGenderPrivate = 'private';

String localizedGreeting(BuildContext context, {DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 11) {
    return context.l10n.greetingMorning;
  }
  if (hour >= 11 && hour < 14) {
    return context.l10n.greetingNoon;
  }
  if (hour >= 14 && hour < 18) {
    return context.l10n.greetingAfternoon;
  }
  return context.l10n.greetingEvening;
}

String normalizeGenderKey(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return normalizedGenderPrivate;
  }
  if (normalized == 'female' || normalized == '2' || normalized == '女') {
    return normalizedGenderFemale;
  }
  if (normalized == 'private' || normalized == '0' || normalized == '保密') {
    return normalizedGenderPrivate;
  }
  return normalizedGenderMale;
}

String localizedGender(BuildContext context, String value) {
  switch (normalizeGenderKey(value)) {
    case normalizedGenderFemale:
      return context.l10n.genderFemale;
    case normalizedGenderPrivate:
      return context.l10n.genderPrivate;
    default:
      return context.l10n.genderMale;
  }
}
