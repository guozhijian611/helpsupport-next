import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/onboarding_models.dart';

final onboardingPagesProvider = FutureProvider.autoDispose
    .family<List<OnboardingPage>, OnboardingQuery>((ref, query) {
      return ref.watch(onboardingRepositoryProvider).fetchPages(query);
    });
