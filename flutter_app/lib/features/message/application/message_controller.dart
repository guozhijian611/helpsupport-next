import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/message_models.dart';
import '../data/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(apiClientProvider));
});

final unreadMessageCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(messageRepositoryProvider).fetchUnreadCount();
});

final messageListProvider = FutureProvider.autoDispose
    .family<MessagePage<MessageItem>, MessageQuery>((ref, query) {
      return ref
          .watch(messageRepositoryProvider)
          .fetchMessages(
            isRead: query.isRead,
            page: query.page,
            pageSize: query.pageSize,
          );
    });
