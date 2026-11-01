import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../auth/auth.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';
import 'chat_repository.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepository(ref.watch(supabaseProvider));

/// Every message event of the team, as a tick other providers can watch.
@Riverpod(keepAlive: true)
class TeamMessageEvents extends _$TeamMessageEvents {
  @override
  Map<String, dynamic>? build(int teamId) {
    final channel = ref.watch(chatRepositoryProvider).watchTeam(teamId, (row) => state = row);
    ref.onDispose(channel.unsubscribe);
    return null;
  }
}

/// My channels with unread counts; refreshed whenever a message arrives.
@riverpod
Future<List<Channel>> channels(Ref ref, int teamId) {
  ref.watch(teamMessageEventsProvider(teamId));
  return ref.watch(chatRepositoryProvider).channels(teamId);
}

@riverpod
int unreadChatCount(Ref ref, int teamId) =>
    (ref.watch(channelsProvider(teamId)).value ?? const []).fold(0, (sum, c) => sum + (c.muted ? 0 : c.unread));

/// A channel's messages, newest first, live. Messages sent from this device
/// show immediately and are confirmed by the realtime echo.
@riverpod
class ChannelMessages extends _$ChannelMessages {
  @override
  Future<List<Message>> build(int teamId, int channelId) async {
    ref.listen(teamMessageEventsProvider(teamId), (_, row) {
      if (row == null || row['channel_id'] != channelId) return;
      _merge(row);
    });
    return ref.watch(chatRepositoryProvider).messages(channelId);
  }

  Future<void> _merge(Map<String, dynamic> row) async {
    if (state.value == null) return;
    final members = await ref.read(teamMembersProvider(teamId).future).catchError((_) => <Member>[]);
    final sender = members.where((m) => m.userId == row['sender_id']).firstOrNull?.profile.displayName;
    final message = Message.fromRow(row, senderName: sender ?? '');
    final current = state.value ?? const <Message>[];
    final i = current.indexWhere((m) => m.id == message.id);
    state = AsyncData(i == -1 ? [message, ...current] : ([...current]..[i] = message));
  }

  Future<void> send(String body) async {
    final repo = ref.read(chatRepositoryProvider);
    final me = ref.read(currentUserIdProvider) ?? '';
    final id = repo.newMessageId();
    final draft = Message(
      id: id,
      channelId: channelId,
      senderId: me,
      senderName: '',
      body: body.trim(),
      createdAt: DateTime.now(),
      pending: true,
    );
    state = AsyncData([draft, ...?state.value]);
    try {
      await repo.send(id: id, teamId: teamId, channelId: channelId, body: body);
    } catch (_) {
      state = AsyncData([for (final m in state.value ?? const <Message>[]) if (m.id != id) m]);
      rethrow;
    }
  }
}

@riverpod
Future<Poll> poll(Ref ref, int pollId) => ref.watch(chatRepositoryProvider).poll(pollId);
