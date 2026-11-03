import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme.dart';
import '../../core/music_widgets.dart';
import '../../core/env.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../annotations/annotation_layer.dart';
import '../annotations/annotations_controller.dart';
import '../annotations/ink.dart';
import '../annotations/stroke_outbox.dart';
import '../auth/auth.dart';
import '../live/cue_widgets.dart';
import '../live/live_clock.dart';
import '../live/live_session.dart';
import '../sessions/models.dart';
import '../sessions/sessions_providers.dart';
import '../songs/models.dart';
import '../songs/song_artwork.dart';
import '../songs/songs_providers.dart';
import '../teams/models.dart';
import '../teams/teams_providers.dart';
import 'sheet_pdf_page.dart';

part 'setlist_viewer_screen.g.dart';

/// Sheets used by a session's setlist, by id.
@riverpod
Future<Map<int, Sheet>> sessionSheets(Ref ref, int sessionId) async {
  ref.watch(onlineStatusProvider.select((s) => s.epoch)); // refresh on reconnect
  final items = await ref.watch(setlistProvider(sessionId).future);
  final sheets = await ref.watch(songsRepositoryProvider).sheetsByIds([for (final i in items) ?i.sheetId]);
  return {for (final s in sheets) s.id: s};
}

/// One page of the music stand: a page of an item's sheet, or a stand-in
/// for a song without a sheet.
class StandPage {
  const StandPage(this.item, this.sheet, this.pageIndex);
  final SetlistItem item;
  final Sheet? sheet;
  final int pageIndex;
}

List<StandPage> standPages(List<SetlistItem> items, Map<int, Sheet> sheets) => [
  for (final item in items)
    if (sheets[item.sheetId] case final sheet?)
      for (var p = 0; p < sheet.pageCount; p++) StandPage(item, sheet, p)
    else
      StandPage(item, null, 0),
];

/// The music stand: every page of the setlist in order, with notes.
class SetlistViewerScreen extends ConsumerStatefulWidget {
  const SetlistViewerScreen({
    super.key,
    required this.teamId,
    required this.sessionId,
    this.initialItemId,
    this.startLive = false,
  });
  final int teamId;
  final int sessionId;
  final int? initialItemId;
  final bool startLive;

  @override
  ConsumerState<SetlistViewerScreen> createState() => _SetlistViewerScreenState();
}

class _SetlistViewerScreenState extends ConsumerState<SetlistViewerScreen> {
  PageController? _pages;
  int _current = 0;
  InkSettings _ink = const InkSettings();
  bool _stage = false;
  final _undo = <InkAction>[];
  final _redo = <InkAction>[];
  final _focus = FocusNode();

  /// Live mode: shared page turns and cues for everyone at this service.
  LiveSession? _live;
  bool _follow = true;
  bool _joiningLive = false;
  bool _autoLiveRequested = false;

  /// Anyone may put the cue bar away to give the pages the room (cues sent
  /// by others still show). Remembered on this device.
  static const _cuesHiddenKey = 'stand.cuesHidden';
  late bool _cuesHidden = ref.read(sharedPreferencesProvider).getBool(_cuesHiddenKey) ?? false;

  void _setCuesHidden(bool hidden) {
    setState(() => _cuesHidden = hidden);
    ref.read(sharedPreferencesProvider).setBool(_cuesHiddenKey, hidden);
  }

  /// True while the stand moves because someone else turned; such moves
  /// are not announced again.
  bool _followingMove = false;
  List<StandPage> _lastPages = const [];

  @override
  void dispose() {
    _pages?.dispose();
    _focus.dispose();
    if (_stage) WakelockPlus.disable();
    _live?.leave();
    _live?.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    if (_joiningLive || _live != null) return;
    final me = ref.read(currentUserIdProvider);
    if (me == null) return;
    if (!ref.read(onlineStatusProvider).online) {
      showMessage(context, AppLocalizations.of(context).liveNeedsConnection);
      return;
    }
    _joiningLive = true;
    try {
      final members = await ref.read(teamMembersProvider(widget.teamId).future);
      if (!mounted) return;
      final mine = members.where((m) => m.userId == me).firstOrNull;
      final live =
          LiveSession(
            db: ref.read(supabaseProvider),
            sessionId: widget.sessionId,
            me: me,
            name: mine?.profile.displayName ?? '',
            myPartIds: {...?mine?.partIds},
            onFollow: _onFollow,
          )..addListener(() {
            if (mounted) setState(() {});
          });
      live.join();
      setState(() => _live = live);
      if (Env.demo) showMessage(context, AppLocalizations.of(context).demoLiveHint);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      _joiningLive = false;
    }
  }

  void _startLiveOnOpen() {
    if (!widget.startLive || _autoLiveRequested) return;
    _autoLiveRequested = true;
    // Join only after the pages and controller are attached, so a late
    // joiner's first presence update can move straight to the current page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLive();
    });
  }

  Future<void> _leaveLive() async {
    final live = _live;
    setState(() => _live = null);
    await live?.leave();
    live?.dispose();
  }

  /// Turning follow back on rejoins the group: jump to the latest turn
  /// seen while I was looking elsewhere.
  void _setFollow(bool on) {
    setState(() => _follow = on);
    final latest = _live?.clock.current?.position;
    if (on && latest != null) _onFollow(latest);
  }

  void _onFollow(StandPosition position) {
    if (!_follow || !mounted) return;
    final index = _lastPages.indexWhere((p) => p.item.id == position.itemId && p.pageIndex == position.pageIndex);
    if (index < 0 || index == _current) return;
    _followingMove = true;
    _pages
        ?.animateToPage(index, duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
        .whenComplete(() => _followingMove = false);
  }

  void _pageChanged(int index, List<StandPage> pages) {
    setState(() => _current = index);
    final live = _live;
    if (live != null && live.joined && _follow && !_followingMove) {
      live.turned(StandPosition(itemId: pages[index].item.id, pageIndex: pages[index].pageIndex));
    }
  }

  /// Back to where the stand was opened from, or to its service when it
  /// was opened directly (a link, a notification) and there is nothing to
  /// go back to.
  void _close() => context.canPop() ? context.pop() : context.go('/t/${widget.teamId}/sessions/${widget.sessionId}');

  Future<void> _cue() async {
    final parts = await ref.read(teamPartsProvider(widget.teamId).future);
    if (!mounted) return;
    final picked = await showCueSheet(context, parts);
    if (picked != null) await _live?.sendCue(picked.text, partId: picked.partId);
  }

  void _go(int delta, int count) {
    final target = (_current + delta).clamp(0, count - 1);
    if (target == _current) return;
    _pages?.animateToPage(target, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  void _setStage(bool on) {
    setState(() => _stage = on);
    on ? WakelockPlus.enable() : WakelockPlus.disable();
  }

  void _record(InkAction action) => setState(() {
    _undo.add(action);
    _redo.clear();
  });

  void _applyUndo() {
    if (_undo.isEmpty) return;
    final action = _undo.removeLast();
    final ink = ref.read(sessionInkProvider(widget.sessionId).notifier);
    ink.setDeleted(action.strokeId, deleted: action is Drew);
    setState(() => _redo.add(action));
  }

  void _applyRedo() {
    if (_redo.isEmpty) return;
    final action = _redo.removeLast();
    final ink = ref.read(sessionInkProvider(widget.sessionId).notifier);
    ink.setDeleted(action.strokeId, deleted: action is Erased);
    setState(() => _undo.add(action));
  }

  Future<void> _copyPrevious(SetlistItem item) async {
    final l10n = AppLocalizations.of(context);
    var count = 0;
    final ok = await runGuarded(context, () async {
      count = await ref.read(sessionInkProvider(widget.sessionId).notifier).copyPrevious(item.id);
    });
    if (ok && mounted) showMessage(context, count == 0 ? l10n.noPreviousInk : l10n.copiedInk(count));
  }

  @override
  Widget build(BuildContext context) {
    final setlist = ref.watch(setlistProvider(widget.sessionId));
    final sheets = ref.watch(sessionSheetsProvider(widget.sessionId));
    ref.watch(sessionInkProvider(widget.sessionId)); // start syncing notes

    return Scaffold(
      backgroundColor: _stage ? AppColors.stageBlack : const Color(0xFF2B2E33),
      body: AsyncBody(
        value: setlist,
        onRetry: () => ref.invalidate(setlistProvider(widget.sessionId)),
        data: (items) => AsyncBody(
          value: sheets,
          onRetry: () => ref.invalidate(sessionSheetsProvider(widget.sessionId)),
          data: (sheetMap) {
            final pages = standPages(items, sheetMap);
            if (pages.isEmpty) return const SizedBox.shrink();
            _lastPages = pages;
            _pages ??= PageController(
              initialPage: _current =
                  (widget.initialItemId == null ? 0 : pages.indexWhere((p) => p.item.id == widget.initialItemId)).clamp(
                    0,
                    pages.length - 1,
                  ),
            );
            final page = pages[_current.clamp(0, pages.length - 1)];
            _startLiveOnOpen();
            return _keyboard(pages.length, _stand(pages, page));
          },
        ),
      ),
    );
  }

  Widget _keyboard(int count, Widget child) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      final key = event.logicalKey;
      // Bluetooth page turners send these.
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.pageDown ||
          key == LogicalKeyboardKey.space) {
        _go(1, count);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.pageUp) {
        _go(-1, count);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: child,
  );

  Widget _stand(List<StandPage> pages, StandPage page) {
    final isLeader = ref.watch(activeMembershipProvider(widget.teamId))?.role.isLeader ?? false;
    final me = ref.watch(currentUserIdProvider);
    final online = ref.watch(onlineStatusProvider.select((s) => s.online));
    final waiting = ref.watch(strokeOutboxProvider);
    // While drawing with a finger the pages must not slide; with a stylus,
    // fingers keep turning pages and only the pen draws.
    final physics = _ink.drawing && !_ink.stylusOnly ? const NeverScrollableScrollPhysics() : const PageScrollPhysics();

    return SafeArea(
      child: Column(
        children: [
          _Header(
            page: page,
            index: _current,
            total: pages.length,
            stage: _stage,
            onClose: _close,
            live: _live,
            follow: _follow,
            onFollow: _setFollow,
            online: online,
            waiting: waiting,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // expand: the pages fill the slot. A loose Stack would size
                // itself to its only unpositioned child, the hidden cue banner.
                final pagesArea = Stack(
                  fit: StackFit.expand,
                  children: [
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.trackpad,
                          if (!_ink.drawing) PointerDeviceKind.mouse,
                        },
                      ),
                      child: PageView.builder(
                        controller: _pages,
                        physics: physics,
                        itemCount: pages.length,
                        onPageChanged: (i) => _pageChanged(i, pages),
                        itemBuilder: (context, i) => _PageSlot(
                          page: pages[i],
                          stage: _stage,
                          tapToTurn: !_ink.drawing,
                          onTurn: (delta) => _go(delta, pages.length),
                          annotations: pages[i].sheet == null
                              ? null
                              : AnnotationLayer(
                                  teamId: widget.teamId,
                                  sessionId: widget.sessionId,
                                  itemId: pages[i].item.id,
                                  sheetId: pages[i].sheet!.id,
                                  pageIndex: pages[i].pageIndex,
                                  settings: _ink,
                                  isLeader: isLeader,
                                  myId: me,
                                  onAction: _record,
                                  onStylusSeen: () {
                                    if (!_ink.stylusOnly) setState(() => _ink = _ink.copyWith(stylusOnly: true));
                                  },
                                ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: CueBanner(
                        cue: _live?.cue,
                        serial: _live?.cueSerial ?? 0,
                        partName: (id) => id == null
                            ? null
                            : (ref.read(teamPartsProvider(widget.teamId)).value ?? const <Part>[])
                                  .where((p) => p.id == id)
                                  .firstOrNull
                                  ?.name,
                      ),
                    ),
                  ],
                );
                final live = _live;
                // Sideways, a portrait page leaves room at its side: the
                // rail goes there. Upright, the strip sits under the pages.
                final rail = box.maxWidth > box.maxHeight;
                // The pages keep the same place in the tree whether or not
                // the bar is there, so joining or leaving live mode never
                // rebuilds them (and never loses the page you are on).
                return Flex(
                  direction: rail ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: pagesArea),
                    if (live != null && !_cuesHidden)
                      CueBar(vertical: rail, onCue: (text) => live.sendCue(text), onMore: _cue),
                  ],
                );
              },
            ),
          ),
          _Toolbar(
            ink: _ink,
            stage: _stage,
            canUndo: _undo.isNotEmpty,
            canRedo: _redo.isNotEmpty,
            hasSheet: page.sheet != null,
            onInk: (settings) => setState(() => _ink = settings),
            onStage: _setStage,
            onUndo: _applyUndo,
            onRedo: _applyRedo,
            onCopyPrevious: () => _copyPrevious(page.item),
            live: _live != null,
            online: online,
            onLive: () => _live == null ? _startLive() : _leaveLive(),
            cuesHidden: _cuesHidden,
            onToggleCues: () => _setCuesHidden(!_cuesHidden),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.page,
    required this.index,
    required this.total,
    required this.stage,
    required this.onClose,
    required this.live,
    required this.follow,
    required this.onFollow,
    required this.online,
    required this.waiting,
  });
  final LiveSession? live;

  /// Offline, the stand shows the copy kept on the device; notes drawn
  /// meanwhile wait to be sent ([waiting] of them).
  final bool online;
  final int waiting;
  final bool follow;
  final ValueChanged<bool> onFollow;
  final StandPage page;
  final int index;
  final int total;
  final bool stage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const fg = Colors.white;
    final songForm = page.item.songForm;
    final live = this.live;

    // First line: the song and where I am. Second line, when there is one:
    // the song form under the title, and live mode's status, so on a phone
    // neither squeezes the title.
    final first = Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: fg),
          tooltip: l10n.close,
        ),
        Expanded(
          child: Text(
            page.item.song.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: fg,
              fontFamily: AppType.setlistFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (page.item.effectiveKey != null)
          Theme(
            data: theme.copyWith(colorScheme: theme.colorScheme.copyWith(primary: fg)),
            child: KeyBadge(page.item.effectiveKey, emphasized: true),
          ),
        if (page.item.effectiveBpm case final bpm?) ...[
          const SizedBox(width: 8),
          Text('$bpm BPM', style: theme.textTheme.labelMedium?.copyWith(color: fg.withValues(alpha: 0.85))),
        ],
        if (!online || waiting > 0) ...[
          const SizedBox(width: 12),
          Icon(online ? Icons.cloud_upload_outlined : Icons.cloud_off_outlined, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            waiting > 0 ? l10n.notesWaiting(waiting) : l10n.offline,
            style: theme.textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
        const SizedBox(width: 16),
        Text(l10n.pageOf(index + 1, total), style: theme.textTheme.labelLarge?.copyWith(color: fg)),
      ],
    );

    // The song form keeps its line whole; live mode's status sits beside it
    // when both fit, else wraps under it.
    final second = songForm == null && live == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                if (songForm != null)
                  Text(
                    songForm,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                if (live != null)
                  Tooltip(
                    message: l10n.liveFollowHint,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 10, color: AppColors.stageAmber),
                        const SizedBox(width: 6),
                        Text(
                          l10n.liveWatching(live.participants),
                          style: theme.textTheme.labelLarge?.copyWith(color: fg),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.liveFollow, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
                        Switch(value: follow, onChanged: onFollow, activeThumbColor: AppColors.stageAmber),
                      ],
                    ),
                  ),
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, ?second],
      ),
    );
  }
}

/// A sheet page fitted to the screen, with its notes on top; or a card for
/// a song without a sheet.
class _PageSlot extends ConsumerWidget {
  const _PageSlot({
    required this.page,
    required this.stage,
    required this.tapToTurn,
    required this.onTurn,
    required this.annotations,
  });
  final StandPage page;
  final bool stage;
  final bool tapToTurn;
  final void Function(int delta) onTurn;
  final Widget? annotations;

  static const _invert = ColorFilter.matrix([
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sheet = page.sheet;
    Widget content;
    if (sheet == null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (setlistThumbnail(page.item) case final url?) ...[
                SongArtwork(url: url, width: 256, height: 144),
                const SizedBox(height: 20),
              ],
              Text(
                page.item.song.title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: Colors.white, fontFamily: AppType.setlistFamily, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(l10n.noSheetForSong, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    } else {
      final bytes = ref.watch(sheetBytesProvider(sheet.storagePath));
      final size = sheet.pageSizes[page.pageIndex];
      content = AsyncBody(
        value: bytes,
        onRetry: () => ref.invalidate(sheetBytesProvider(sheet.storagePath)),
        data: (data) => Center(
          child: AspectRatio(
            aspectRatio: size.width / size.height,
            child: ColorFiltered(
              // Stage mode inverts page and notes together, so every mark
              // stays legible on black.
              colorFilter: stage ? _invert : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: SheetPdfPage(
                      data: data,
                      sourceName: sheet.storagePath,
                      pageNumber: page.pageIndex + 1,
                    ),
                  ),
                  ?annotations,
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Keep the wrapper mounted in drawing mode too. Swapping the subtree
    // here would dispose the PDF every time the annotation toolbar opens.
    // Tap the left or right third to turn the page (one-handed on stage).
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: tapToTurn
            ? (d) {
                final x = d.localPosition.dx / constraints.maxWidth;
                if (x > 0.66) onTurn(1);
                if (x < 0.33) onTurn(-1);
              }
            : null,
        child: content,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.ink,
    required this.stage,
    required this.canUndo,
    required this.canRedo,
    required this.hasSheet,
    required this.onInk,
    required this.onStage,
    required this.onUndo,
    required this.onRedo,
    required this.onCopyPrevious,
    required this.live,
    required this.online,
    required this.onLive,
    required this.cuesHidden,
    required this.onToggleCues,
  });
  final bool live;

  /// Live mode and copying earlier notes need the server.
  final bool online;
  final VoidCallback onLive;
  final bool cuesHidden;
  final VoidCallback onToggleCues;
  final InkSettings ink;
  final bool stage;
  final bool canUndo;
  final bool canRedo;
  final bool hasSheet;
  final ValueChanged<InkSettings> onInk;
  final ValueChanged<bool> onStage;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCopyPrevious;

  static const _penColors = [0xFF1D1F23, 0xFF2541B2, 0xFFC62828, 0xFF2E7D32];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const fg = Colors.white;
    final buttonStyle = TextButton.styleFrom(foregroundColor: fg);

    if (!ink.drawing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            if (hasSheet)
              FilledButton.icon(
                onPressed: () => onInk(ink.copyWith(mode: InkMode.pen)),
                icon: const Icon(Icons.edit),
                label: Text(l10n.annotate),
              ),
            TextButton.icon(
              style: buttonStyle,
              onPressed: () => onStage(!stage),
              icon: Icon(stage ? Icons.light_mode : Icons.dark_mode),
              label: Text(l10n.stageMode),
            ),
            if (hasSheet)
              TextButton.icon(
                style: buttonStyle,
                onPressed: online ? onCopyPrevious : null,
                icon: const Icon(Icons.history),
                label: Text(l10n.copyPreviousInk),
              ),
            TextButton.icon(
              style: buttonStyle,
              onPressed: live || online ? onLive : null,
              icon: Icon(live ? Icons.stop_circle_outlined : Icons.sensors, color: live ? AppColors.stageAmber : null),
              label: Text(live ? l10n.liveLeave : l10n.liveStart),
            ),
            if (live)
              TextButton.icon(
                style: buttonStyle,
                onPressed: onToggleCues,
                icon: Icon(cuesHidden ? Icons.campaign_outlined : Icons.expand_more, color: AppColors.stageAmber),
                label: Text(cuesHidden ? l10n.showCues : l10n.hideCues),
              ),
          ],
        ),
      );
    }

    final forTeam = ink.target == InkVisibility.team;
    return Material(
      color: const Color(0xFF1D1F23),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // Who the next strokes are for: the two inks.
            SegmentedButton<InkVisibility>(
              style: SegmentedButton.styleFrom(
                foregroundColor: fg,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: forTeam ? AppColors.teamInk : AppColors.myPencil,
              ),
              segments: [
                ButtonSegment(
                  value: InkVisibility.private,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l10n.inkForMe),
                ),
                ButtonSegment(
                  value: InkVisibility.team,
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(l10n.inkForTeam),
                ),
              ],
              selected: {ink.target},
              onSelectionChanged: (s) => onInk(ink.copyWith(target: s.first)),
            ),
            const SizedBox(width: 12),
            for (final (mode, icon, label) in [
              (InkMode.pen, Icons.edit, l10n.pen),
              (InkMode.highlighter, Icons.border_color, l10n.highlighter),
              (InkMode.eraser, Icons.auto_fix_normal, l10n.eraser),
            ])
              IconButton(
                tooltip: label,
                isSelected: ink.mode == mode,
                color: fg,
                selectedIcon: Icon(icon, color: AppColors.stageAmber),
                icon: Icon(icon),
                onPressed: () => onInk(ink.copyWith(mode: mode)),
              ),
            if (ink.mode == InkMode.pen)
              for (final c in _penColors)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkResponse(
                    onTap: () => onInk(ink.copyWith(color: c)),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ink.color == c ? AppColors.stageAmber : Colors.white54,
                          width: ink.color == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(width: 8),
            IconButton(tooltip: l10n.undo, color: fg, onPressed: canUndo ? onUndo : null, icon: const Icon(Icons.undo)),
            IconButton(tooltip: l10n.redo, color: fg, onPressed: canRedo ? onRedo : null, icon: const Icon(Icons.redo)),
            PopupMenuButton<String>(
              iconColor: fg,
              onSelected: (v) =>
                  onInk(v == 'team' ? ink.copyWith(showTeam: !ink.showTeam) : ink.copyWith(showMine: !ink.showMine)),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(value: 'team', checked: ink.showTeam, child: Text(l10n.showTeamInk)),
                CheckedPopupMenuItem(value: 'mine', checked: ink.showMine, child: Text(l10n.showMyInk)),
              ],
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => onInk(ink.copyWith(mode: InkMode.view)),
              child: Text(l10n.doneAnnotating),
            ),
          ],
        ),
      ),
    );
  }
}
