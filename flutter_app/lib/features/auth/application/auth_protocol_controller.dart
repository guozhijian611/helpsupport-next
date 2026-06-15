import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_protocol.dart';
import 'auth_controller.dart';

final authProtocolProvider = FutureProvider.autoDispose
    .family<AuthProtocolDocument, AuthProtocolQuery>((ref, query) {
      return ref
          .watch(authRepositoryProvider)
          .fetchProtocol(query.type, locale: query.locale);
    });
