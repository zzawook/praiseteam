// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'55001851c70359edf90a0d93fc5b409df3b0c5ec';

/// Every message event of the team, as a tick other providers can watch.

@ProviderFor(TeamMessageEvents)
final teamMessageEventsProvider = TeamMessageEventsFamily._();

/// Every message event of the team, as a tick other providers can watch.
final class TeamMessageEventsProvider
    extends $NotifierProvider<TeamMessageEvents, Map<String, dynamic>?> {
  /// Every message event of the team, as a tick other providers can watch.
  TeamMessageEventsProvider._({
    required TeamMessageEventsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'teamMessageEventsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamMessageEventsHash();

  @override
  String toString() {
    return r'teamMessageEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TeamMessageEvents create() => TeamMessageEvents();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, dynamic>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, dynamic>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMessageEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamMessageEventsHash() => r'd434c890d18322879450e6f759adcc327647492d';

/// Every message event of the team, as a tick other providers can watch.

final class TeamMessageEventsFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamMessageEvents,
          Map<String, dynamic>?,
          Map<String, dynamic>?,
          Map<String, dynamic>?,
          int
        > {
  TeamMessageEventsFamily._()
    : super(
        retry: null,
        name: r'teamMessageEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Every message event of the team, as a tick other providers can watch.

  TeamMessageEventsProvider call(int teamId) =>
      TeamMessageEventsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamMessageEventsProvider';
}

/// Every message event of the team, as a tick other providers can watch.

abstract class _$TeamMessageEvents extends $Notifier<Map<String, dynamic>?> {
  late final _$args = ref.$arg as int;
  int get teamId => _$args;

  Map<String, dynamic>? build(int teamId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, dynamic>?, Map<String, dynamic>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, dynamic>?, Map<String, dynamic>?>,
              Map<String, dynamic>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// My channels with unread counts; refreshed whenever a message arrives.

@ProviderFor(channels)
final channelsProvider = ChannelsFamily._();

/// My channels with unread counts; refreshed whenever a message arrives.

final class ChannelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Channel>>,
          List<Channel>,
          FutureOr<List<Channel>>
        >
    with $FutureModifier<List<Channel>>, $FutureProvider<List<Channel>> {
  /// My channels with unread counts; refreshed whenever a message arrives.
  ChannelsProvider._({
    required ChannelsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'channelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelsHash();

  @override
  String toString() {
    return r'channelsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Channel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Channel>> create(Ref ref) {
    final argument = this.argument as int;
    return channels(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelsHash() => r'e151f4d4c8d685158564edbf12902829e5c6a0e5';

/// My channels with unread counts; refreshed whenever a message arrives.

final class ChannelsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Channel>>, int> {
  ChannelsFamily._()
    : super(
        retry: null,
        name: r'channelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// My channels with unread counts; refreshed whenever a message arrives.

  ChannelsProvider call(int teamId) =>
      ChannelsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'channelsProvider';
}

@ProviderFor(unreadChatCount)
final unreadChatCountProvider = UnreadChatCountFamily._();

final class UnreadChatCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  UnreadChatCountProvider._({
    required UnreadChatCountFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'unreadChatCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unreadChatCountHash();

  @override
  String toString() {
    return r'unreadChatCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as int;
    return unreadChatCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadChatCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadChatCountHash() => r'8b1bd3e8e52794a6a33008c95e68480a15abf94e';

final class UnreadChatCountFamily extends $Family
    with $FunctionalFamilyOverride<int, int> {
  UnreadChatCountFamily._()
    : super(
        retry: null,
        name: r'unreadChatCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UnreadChatCountProvider call(int teamId) =>
      UnreadChatCountProvider._(argument: teamId, from: this);

  @override
  String toString() => r'unreadChatCountProvider';
}

/// A channel's messages, newest first, live. Messages sent from this device
/// show immediately and are confirmed by the realtime echo.

@ProviderFor(ChannelMessages)
final channelMessagesProvider = ChannelMessagesFamily._();

/// A channel's messages, newest first, live. Messages sent from this device
/// show immediately and are confirmed by the realtime echo.
final class ChannelMessagesProvider
    extends $AsyncNotifierProvider<ChannelMessages, List<Message>> {
  /// A channel's messages, newest first, live. Messages sent from this device
  /// show immediately and are confirmed by the realtime echo.
  ChannelMessagesProvider._({
    required ChannelMessagesFamily super.from,
    required (int, int) super.argument,
  }) : super(
         retry: null,
         name: r'channelMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelMessagesHash();

  @override
  String toString() {
    return r'channelMessagesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ChannelMessages create() => ChannelMessages();

  @override
  bool operator ==(Object other) {
    return other is ChannelMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelMessagesHash() => r'9e9d76e2eda8b0cd021d2b868b693ed275900b2a';

/// A channel's messages, newest first, live. Messages sent from this device
/// show immediately and are confirmed by the realtime echo.

final class ChannelMessagesFamily extends $Family
    with
        $ClassFamilyOverride<
          ChannelMessages,
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>,
          (int, int)
        > {
  ChannelMessagesFamily._()
    : super(
        retry: null,
        name: r'channelMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A channel's messages, newest first, live. Messages sent from this device
  /// show immediately and are confirmed by the realtime echo.

  ChannelMessagesProvider call(int teamId, int channelId) =>
      ChannelMessagesProvider._(argument: (teamId, channelId), from: this);

  @override
  String toString() => r'channelMessagesProvider';
}

/// A channel's messages, newest first, live. Messages sent from this device
/// show immediately and are confirmed by the realtime echo.

abstract class _$ChannelMessages extends $AsyncNotifier<List<Message>> {
  late final _$args = ref.$arg as (int, int);
  int get teamId => _$args.$1;
  int get channelId => _$args.$2;

  FutureOr<List<Message>> build(int teamId, int channelId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Message>>, List<Message>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Message>>, List<Message>>,
              AsyncValue<List<Message>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(poll)
final pollProvider = PollFamily._();

final class PollProvider
    extends $FunctionalProvider<AsyncValue<Poll>, Poll, FutureOr<Poll>>
    with $FutureModifier<Poll>, $FutureProvider<Poll> {
  PollProvider._({required PollFamily super.from, required int super.argument})
    : super(
        retry: null,
        name: r'pollProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pollHash();

  @override
  String toString() {
    return r'pollProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Poll> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Poll> create(Ref ref) {
    final argument = this.argument as int;
    return poll(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PollProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollHash() => r'4c2a177f4ef8a74b7ada7d852aef4fab906c9275';

final class PollFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Poll>, int> {
  PollFamily._()
    : super(
        retry: null,
        name: r'pollProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PollProvider call(int pollId) => PollProvider._(argument: pollId, from: this);

  @override
  String toString() => r'pollProvider';
}
