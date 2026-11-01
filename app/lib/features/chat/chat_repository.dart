import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:uuid/uuid.dart';

class Channel {
  const Channel({
    required this.id,
    required this.kind,
    required this.name,
    required this.archived,
    required this.muted,
    required this.unread,
    this.sessionId,
    this.lastBody,
    this.lastIsPoll = false,
    this.lastAt,
  });

  factory Channel.fromRow(Map<String, dynamic> r) => Channel(
        id: r['id'] as int,
        kind: r['kind'] as String,
        name: r['name'] as String,
        sessionId: r['session_id'] as int?,
        archived: r['archived'] as bool,
        muted: r['muted'] as bool,
        unread: r['unread'] as int,
        lastBody: r['last_body'] as String?,
        lastIsPoll: r['last_is_poll'] as bool? ?? false,
        lastAt: r['last_at'] == null ? null : DateTime.parse(r['last_at'] as String),
      );

  final int id;
  final String kind; // team | parts | session
  final String name;
  final int? sessionId;
  final bool archived;
  final bool muted;
  final int unread;
  final String? lastBody;
  final bool lastIsPoll;
  final DateTime? lastAt;
}

class Message {
  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.body,
    this.pollId,
    this.deleted = false,
    this.pending = false,
  });

  factory Message.fromRow(Map<String, dynamic> r, {String? senderName}) => Message(
        id: r['id'] as String,
        channelId: r['channel_id'] as int,
        senderId: r['sender_id'] as String,
        senderName: senderName ?? ((r['profiles'] as Map?)?['display_name'] as String? ?? ''),
        body: r['body'] as String?,
        pollId: r['poll_id'] as int?,
        createdAt: DateTime.parse(r['created_at'] as String),
        deleted: r['deleted_at'] != null,
      );

  final String id;
  final int channelId;
  final String senderId;
  final String senderName;
  final String? body;
  final int? pollId;
  final DateTime createdAt;
  final bool deleted;

  /// Sent from this device, not yet confirmed by the server.
  final bool pending;
}

class PollOption {
  const PollOption({required this.id, required this.label, required this.votes, required this.mine, this.voters});
  final int id;
  final String label;
  final int votes;
  final bool mine;

  /// Null when the poll is anonymous.
  final List<String>? voters;
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.multiple,
    required this.anonymous,
    required this.options,
    this.closesAt,
  });
  final int id;
  final String question;
  final bool multiple;
  final bool anonymous;
  final DateTime? closesAt;
  final List<PollOption> options;

  bool get closed => closesAt != null && closesAt!.isBefore(DateTime.now());
  int get total => options.fold(0, (sum, o) => sum + o.votes);
}

class ChatRepository {
  ChatRepository(this._db);
  final SupabaseClient _db;

  Future<List<Channel>> channels(int teamId) async {
    final rows = await _db.rpc('my_channels', params: {'p_team_id': teamId}) as List<dynamic>;
    return [for (final r in rows.cast<Map<String, dynamic>>()) Channel.fromRow(r)];
  }

  Future<List<Message>> messages(int channelId, {int limit = 100}) async {
    final rows = await _db
        .from('messages')
        .select('id, channel_id, sender_id, body, poll_id, created_at, deleted_at, profiles(display_name)')
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(Message.fromRow).toList();
  }

  String newMessageId() => const Uuid().v7();

  /// Idempotent: the id is made on the device, so retrying is safe.
  Future<void> send({required String id, required int teamId, required int channelId, required String body}) =>
      _db.from('messages').upsert(
        {'id': id, 'team_id': teamId, 'channel_id': channelId, 'body': body.trim()},
        onConflict: 'id',
        ignoreDuplicates: true,
      );

  Future<void> delete(String messageId) => _db
      .from('messages')
      .update({'deleted_at': DateTime.now().toUtc().toIso8601String(), 'body': null})
      .eq('id', messageId);

  Future<void> markRead(int teamId, int channelId) =>
      _db.rpc('mark_channel_read', params: {'p_channel_id': channelId});

  Future<void> setMuted(int teamId, int channelId, bool muted) =>
      _db.rpc('set_channel_muted', params: {'p_channel_id': channelId, 'p_muted': muted});

  Future<void> createPartsChannel(int teamId, String name, List<int> partIds) async {
    final row = await _db
        .from('channels')
        .insert({'team_id': teamId, 'kind': 'parts', 'name': name.trim()})
        .select('id')
        .single();
    if (partIds.isEmpty) return;
    await _db.from('channel_parts').insert([
      for (final p in partIds) {'team_id': teamId, 'channel_id': row['id'], 'part_id': p},
    ]);
  }

  Future<int> createPoll({
    required int teamId,
    required String question,
    required List<String> options,
    int? channelId,
    int? announcementId,
    bool multiple = false,
    bool anonymous = false,
  }) async =>
      await _db.rpc('create_poll', params: {
        'p_team_id': teamId,
        'p_question': question,
        'p_options': options,
        'p_channel_id': channelId,
        'p_announcement_id': announcementId,
        'p_multiple': multiple,
        'p_anonymous': anonymous,
      }) as int;

  Future<Poll> poll(int pollId) async {
    final (meta, results) = await (
      _db.from('polls').select('id, question, multiple, anonymous, closes_at').eq('id', pollId).single(),
      _db.rpc('poll_results', params: {'p_poll_id': pollId}),
    ).wait;
    return Poll(
      id: meta['id'] as int,
      question: meta['question'] as String,
      multiple: meta['multiple'] as bool,
      anonymous: meta['anonymous'] as bool,
      closesAt: meta['closes_at'] == null ? null : DateTime.parse(meta['closes_at'] as String),
      options: [
        for (final r in (results as List).cast<Map<String, dynamic>>())
          PollOption(
            id: r['option_id'] as int,
            label: r['label'] as String,
            votes: r['votes'] as int,
            mine: r['mine'] as bool,
            voters: (r['voters'] as List?)?.cast<String>(),
          ),
      ],
    );
  }

  Future<void> vote(int pollId, List<int> optionIds) =>
      _db.rpc('poll_vote', params: {'p_poll_id': pollId, 'p_option_ids': optionIds});

  /// New or edited messages the user may see in [teamId] (RLS applies).
  RealtimeChannel watchTeam(int teamId, void Function(Map<String, dynamic> row) onRow) => _db
      .channel('messages:$teamId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'team_id', value: teamId),
        callback: (payload) {
          if (payload.newRecord.isNotEmpty) onRow(payload.newRecord);
        },
      )
      .subscribe();
}
