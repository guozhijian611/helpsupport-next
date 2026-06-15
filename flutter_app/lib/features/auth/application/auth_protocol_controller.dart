import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_protocol.dart';
import 'auth_controller.dart';

final authProtocolProvider = FutureProvider.autoDispose
    .family<AuthProtocolDocument, AuthProtocolType>((ref, type) {
      return ref.watch(authRepositoryProvider).fetchProtocol(type);
    });
