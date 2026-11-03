// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PraiseTeam';

  @override
  String get loginTagline =>
      'Setlists, sheets and rotations, shared with your team.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get devLoginTitle => 'Developer login (local server only)';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get welcomeTitle => 'Join your worship team';

  @override
  String get welcomeBody =>
      'Got an invite code? Join right away. First one here? Create the team.';

  @override
  String get joinWithCode => 'Join with an invite code';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get inviteCodeHint => '8 characters';

  @override
  String get join => 'Join';

  @override
  String get createTeam => 'Create a team';

  @override
  String get teamName => 'Team name';

  @override
  String get teamNameHint => 'e.g. Youth worship team';

  @override
  String get pendingTitle => 'Waiting for approval';

  @override
  String pendingBody(String team) {
    return 'You\'ll get in as soon as a leader of $team approves.';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get joinAnotherTeam => 'Join another team';

  @override
  String get navTeam => 'Team';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navSettings => 'Settings';

  @override
  String get switchTeam => 'Switch team';

  @override
  String get addTeam => 'Add a team';

  @override
  String get inviteTitle => 'Invite code';

  @override
  String get inviteHint => 'Send this code to new members.';

  @override
  String get newInviteCode => 'Replace code';

  @override
  String get newInviteCodeConfirm =>
      'The current code will stop working. Replace it?';

  @override
  String get joinRequests => 'Join requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Decline';

  @override
  String get members => 'Members';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get roleOwner => 'Admin';

  @override
  String get roleLeader => 'Leader';

  @override
  String get roleMember => 'Member';

  @override
  String get you => 'You';

  @override
  String get noPartsYet => 'No part yet';

  @override
  String get editParts => 'Set parts';

  @override
  String get changeRole => 'Change role';

  @override
  String get removeFromTeam => 'Remove from team';

  @override
  String removeConfirm(String name) {
    return 'Remove $name from the team?';
  }

  @override
  String get parts => 'Parts';

  @override
  String get manageParts => 'Manage parts';

  @override
  String get myParts => 'My parts';

  @override
  String get partsPickerHint => 'Pick every part you can serve in.';

  @override
  String get addPart => 'Add part';

  @override
  String get partName => 'Part name';

  @override
  String get renamePart => 'Rename';

  @override
  String get hidePart => 'Hide from list';

  @override
  String get partKindVocal => 'Vocals';

  @override
  String get partKindInstrument => 'Instruments';

  @override
  String get partKindTech => 'Sound & media';

  @override
  String get notificationsEmpty => 'New notifications will show up here.';

  @override
  String get notifJoinRequestTitle => 'Join request';

  @override
  String notifJoinRequestBody(String name, String team) {
    return '$name asked to join $team.';
  }

  @override
  String get notifApprovedTitle => 'You\'re in';

  @override
  String notifApprovedBody(String team) {
    return 'You joined $team.';
  }

  @override
  String get notifFallback => 'New notification';

  @override
  String get profile => 'Profile';

  @override
  String get displayName => 'Name';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Use device setting';

  @override
  String get teamSettings => 'Team settings';

  @override
  String get requireApproval => 'Leaders approve new members';

  @override
  String get leaveTeam => 'Leave team';

  @override
  String leaveTeamConfirm(String team) {
    return 'Leave $team?';
  }

  @override
  String get errorInvalidCode =>
      'That invite code doesn\'t match. Check the 8 characters and try again.';

  @override
  String get errorNotAllowed => 'Only leaders can do this.';

  @override
  String get errorLastOwner =>
      'A team needs at least one admin. Make someone else an admin first.';

  @override
  String get errorNetwork =>
      'Can\'t reach the server. Check your internet connection.';

  @override
  String get errorGoogleNotConfigured => 'Google sign-in isn\'t set up yet.';

  @override
  String errorGeneric(String detail) {
    return 'Couldn\'t complete the request: $detail';
  }

  @override
  String get navSessions => 'Services';

  @override
  String get navSongs => 'Songs';

  @override
  String get upcomingSessions => 'Upcoming';

  @override
  String get pastSessions => 'Past';

  @override
  String get noSessionsLeader => 'Add a service and start its setlist.';

  @override
  String get noSessionsMember =>
      'Services show up here once a leader adds them.';

  @override
  String get addSession => 'Add service';

  @override
  String get editSession => 'Edit service';

  @override
  String get deleteSession => 'Delete service';

  @override
  String deleteSessionConfirm(String title) {
    return 'Delete \'$title\'? Its setlist is deleted too.';
  }

  @override
  String get sessionTitle => 'Service name';

  @override
  String get sessionTitleHint => 'e.g. Sunday 2nd service';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get location => 'Place';

  @override
  String get theme => 'Sermon passage or theme';

  @override
  String get notes => 'Notes';

  @override
  String get repeatWeekly => 'Repeat weekly at this time';

  @override
  String repeatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'for $count weeks',
      one: 'for 1 week',
    );
    return '$_temp0';
  }

  @override
  String get templates => 'Templates';

  @override
  String get editTemplates => 'Edit templates';

  @override
  String get sessionTemplates => 'Service templates';

  @override
  String get weeklyServices => 'Weekly services';

  @override
  String get addTemplate => 'Add template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get noTemplates =>
      'Add the services you hold on the same day, at the same time and place every week. When you add a service, pick one to fill it in.';

  @override
  String get saveAsTemplate => 'Save as a template';

  @override
  String get saveAsTemplateHint =>
      'Next time, pick it to fill in the name, day, time and place';

  @override
  String get templateTitleTaken => 'A template with this name already exists';

  @override
  String deleteTemplateConfirm(String title) {
    return 'Delete the template \'$title\'? Services already added stay as they are.';
  }

  @override
  String get weekday => 'Day';

  @override
  String get setlist => 'Setlist';

  @override
  String get setlistDraft => 'Draft';

  @override
  String get setlistPublished => 'Announced';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get addSongToSetlist => 'Add song';

  @override
  String get publishSetlist => 'Announce setlist';

  @override
  String get republishSetlist => 'Announce changes';

  @override
  String get publishConfirm =>
      'Announce this setlist? Your team gets notified.';

  @override
  String get republishConfirm => 'Tell the team what changed?';

  @override
  String get published => 'Setlist announced';

  @override
  String get noChanges => 'Nothing changed since the last announcement.';

  @override
  String get setlistEmptyLeader => 'Add songs to build the setlist.';

  @override
  String get setlistEmptyMember => 'The setlist hasn\'t been announced yet.';

  @override
  String get key => 'Key';

  @override
  String get songForm => 'Song form';

  @override
  String get songFormHint => 'e.g. I-V1-C-V2-C-B-C-O';

  @override
  String get sheet => 'Sheet';

  @override
  String get noSheet => 'No sheet';

  @override
  String get removeFromSetlist => 'Remove from setlist';

  @override
  String changeAdded(String songs) {
    return 'Added: $songs';
  }

  @override
  String changeRemoved(String songs) {
    return 'Removed: $songs';
  }

  @override
  String changeKey(String changes) {
    return 'Key: $changes';
  }

  @override
  String changeTempo(String changes) {
    return 'Tempo: $changes';
  }

  @override
  String get changeOrder => 'New order';

  @override
  String notifSetlistTitle(String session) {
    return 'Setlist: $session';
  }

  @override
  String notifSetlistUpdatedTitle(String session) {
    return 'Setlist changed: $session';
  }

  @override
  String get searchSongs => 'Search by title or artist';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortRecent => 'Recently played';

  @override
  String get sortMost => 'Most played';

  @override
  String get sortLongAgo => 'Not played lately';

  @override
  String get addSong => 'Add song';

  @override
  String get editSong => 'Edit song';

  @override
  String get deleteSong => 'Delete song';

  @override
  String deleteSongConfirm(String title) {
    return 'Delete \'$title\' from the library?';
  }

  @override
  String get songInUse => 'Songs used in a setlist can\'t be deleted.';

  @override
  String get songTitle => 'Title';

  @override
  String get bpm => 'BPM';

  @override
  String get timeSignature => 'Time signature';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Comma separated (e.g. thanksgiving, upbeat)';

  @override
  String get originalLinks => 'Original recordings';

  @override
  String get addLink => 'Add link';

  @override
  String get linkUrl => 'URL (https://...)';

  @override
  String get linkLabel => 'Label (optional)';

  @override
  String get versions => 'Versions';

  @override
  String get version => 'Version';

  @override
  String get addVersion => 'Add version';

  @override
  String get editVersion => 'Edit version';

  @override
  String get deleteVersion => 'Delete version';

  @override
  String deleteVersionConfirm(String title) {
    return 'Delete the version \'$title\'? Its sheets and links are deleted too.';
  }

  @override
  String get versionInUse => 'A version used in a setlist can\'t be deleted.';

  @override
  String get versionName => 'Artist or version';

  @override
  String get versionNameHint => 'e.g. the artist, a live recording';

  @override
  String get unnamedVersion => 'Main version';

  @override
  String get firstVersion => 'First version';

  @override
  String get firstVersionHint =>
      'Add more versions on the song\'s page for other artists or arrangements. A setlist can also change the key and tempo for one service.';

  @override
  String get playedLast => 'Played last';

  @override
  String get songHasNoVersion =>
      'This song has no version yet. Add one on the song\'s page.';

  @override
  String changeVersion(String changes) {
    return 'Version: $changes';
  }

  @override
  String get sheets => 'Sheets';

  @override
  String get uploadSheet => 'Upload sheet';

  @override
  String get uploadSheetHint =>
      'Pick a PDF or photos; they\'re saved as one sheet.';

  @override
  String get sheetLabel => 'Label (e.g. chords, drums)';

  @override
  String get uploading => 'Uploading';

  @override
  String pages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get history => 'History';

  @override
  String playedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Played $count times',
      one: 'Played once',
    );
    return '$_temp0';
  }

  @override
  String get neverPlayed => 'Not played yet';

  @override
  String lastPlayed(String ago) {
    return 'Last $ago';
  }

  @override
  String usualKey(String key) {
    return 'Usually $key';
  }

  @override
  String nextPlanned(String date) {
    return 'Next $date';
  }

  @override
  String get today => 'today';

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String yearsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get stats => 'Statistics';

  @override
  String get topSongs => 'Most played';

  @override
  String notPlayedSince(int months) {
    return 'Not played in $months+ months';
  }

  @override
  String get period3m => '3 months';

  @override
  String get period6m => '6 months';

  @override
  String get period1y => '1 year';

  @override
  String get periodAll => 'All time';

  @override
  String timesShort(int count) {
    return '$count×';
  }

  @override
  String get viewSheet => 'Open sheet';

  @override
  String get viewSheets => 'Open sheets';

  @override
  String get annotate => 'Annotate';

  @override
  String get doneAnnotating => 'Done';

  @override
  String get pen => 'Pen';

  @override
  String get highlighter => 'Highlighter';

  @override
  String get eraser => 'Eraser';

  @override
  String get inkForMe => 'Only me';

  @override
  String get inkForTeam => 'Whole team';

  @override
  String get showTeamInk => 'Show team notes';

  @override
  String get showMyInk => 'Show my notes';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get stageMode => 'Stage mode';

  @override
  String get copyPreviousInk => 'Bring notes from last time';

  @override
  String copiedInk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Brought $count notes',
      one: 'Brought 1 note',
    );
    return '$_temp0';
  }

  @override
  String get noPreviousInk =>
      'No notes of yours on this sheet from an earlier service.';

  @override
  String get noSheetForSong => 'No sheet for this song';

  @override
  String pageOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get inkColor => 'Color';

  @override
  String unsavedInk(int count) {
    return '$count waiting to save';
  }

  @override
  String get rotation => 'Rotation';

  @override
  String get rotationList => 'List';

  @override
  String get rotationTable => 'Table';

  @override
  String openPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String get myServing => 'I\'m serving';

  @override
  String get noServing => 'Nothing coming up for you.';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get declineReason => 'Reason (optional)';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPending => 'Waiting';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get autoAssign => 'Auto-assign';

  @override
  String autoAssignDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filled $count places as drafts. Review, then send.',
      one: 'Filled 1 place as a draft. Review, then send.',
      zero: 'Nothing to fill',
    );
    return '$_temp0';
  }

  @override
  String sendDrafts(int count) {
    return 'Send ($count)';
  }

  @override
  String sendDraftsConfirm(int count) {
    return 'Send $count drafts? Each person gets a request.';
  }

  @override
  String sent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent $count requests',
      one: 'Sent 1 request',
    );
    return '$_temp0';
  }

  @override
  String get addPerson => 'Add person';

  @override
  String get replacePerson => 'Replace';

  @override
  String get removePerson => 'Remove';

  @override
  String needed(int count) {
    return '$count needed';
  }

  @override
  String get setNeeded => 'People needed';

  @override
  String get defaultNeeded => 'Default people per part';

  @override
  String get defaultNeededHint => 'New services start with these numbers.';

  @override
  String get unavailableThatDay => 'Unavailable that day';

  @override
  String get alreadyServing => 'Already serving';

  @override
  String get requestSwap => 'Ask for a sub';

  @override
  String get swapMessage => 'Message (optional)';

  @override
  String get swapRequested => 'Asked teammates in this part';

  @override
  String get cancelSwap => 'Cancel sub request';

  @override
  String get swapOpen => 'Needs a sub';

  @override
  String get takeSwap => 'I\'ll take it';

  @override
  String get swapTaken => 'It\'s yours now';

  @override
  String get blockouts => 'Unavailable dates';

  @override
  String get myBlockouts => 'My unavailable dates';

  @override
  String get teamBlockouts => 'Team\'s unavailable dates';

  @override
  String get addBlockout => 'Add dates';

  @override
  String get blockoutNote => 'Note (optional, leaders only)';

  @override
  String get noBlockouts => 'No dates added.';

  @override
  String get servingPeople => 'Serving';

  @override
  String notifAssignmentRequested(String session, String part) {
    return '$session: can you serve on $part?';
  }

  @override
  String notifAssignmentDeclined(String name, String session, String part) {
    return '$name declined $part for $session';
  }

  @override
  String notifAssignmentRemoved(String session, String part) {
    return 'You\'re off $part for $session';
  }

  @override
  String notifAssignmentNudge(String session, String part) {
    return 'Still waiting on your answer: $part for $session';
  }

  @override
  String notifSwapRequested(String name, String session, String part) {
    return '$name needs a sub: $part for $session';
  }

  @override
  String notifSwapFilled(String name, String session, String part) {
    return '$name took $part for $session';
  }

  @override
  String notifServiceReminder(String session, String part) {
    return 'Tomorrow: $part for $session';
  }

  @override
  String notifRehearsalScheduled(String when) {
    return 'Rehearsal: $when';
  }

  @override
  String notifRehearsalReminder(String when) {
    return 'Rehearsal soon: $when';
  }

  @override
  String get rehearsals => 'Rehearsals';

  @override
  String get addRehearsal => 'Add rehearsal';

  @override
  String get noRehearsals => 'No rehearsal scheduled.';

  @override
  String get rsvpGoing => 'Going';

  @override
  String get rsvpLate => 'Late';

  @override
  String get rsvpNotGoing => 'Can\'t come';

  @override
  String get attendanceCheck => 'Attendance';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get calendarSubscribe => 'Subscribe in your calendar';

  @override
  String get calendarHint =>
      'Your services and rehearsals show up in your calendar.';

  @override
  String get openInCalendar => 'Open in calendar app';

  @override
  String get newCalendarUrl => 'Make a new address';

  @override
  String get newCalendarUrlHint => 'The old address stops working.';

  @override
  String get googleCalendarHint =>
      'Google Calendar: on the web, Other calendars > From URL. Updates can take a few hours.';

  @override
  String get navChat => 'Chat';

  @override
  String get announcements => 'Announcements';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get editAnnouncement => 'Edit announcement';

  @override
  String get deleteAnnouncement => 'Delete announcement';

  @override
  String get announcementTitle => 'Title';

  @override
  String get announcementBody => 'Message';

  @override
  String get pinAnnouncement => 'Pin to top';

  @override
  String get pinned => 'Pinned';

  @override
  String get noAnnouncements => 'No announcements yet.';

  @override
  String get newBadge => 'New';

  @override
  String get channels => 'Channels';

  @override
  String get archivedChannel => 'Past service (read-only)';

  @override
  String get newChannel => 'New channel';

  @override
  String get channelName => 'Channel name';

  @override
  String get channelPartsHint =>
      'People who play these parts are in it. Leaders see every channel.';

  @override
  String get noMessages => 'Say hello.';

  @override
  String get messageHint => 'Message';

  @override
  String get send => 'Send';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deletedMessage => 'Message deleted';

  @override
  String get newPoll => 'New poll';

  @override
  String get pollQuestion => 'Question';

  @override
  String pollOption(int n) {
    return 'Option $n';
  }

  @override
  String get addOption => 'Add option';

  @override
  String get multipleChoice => 'Allow several choices';

  @override
  String get anonymousPoll => 'Anonymous';

  @override
  String get vote => 'Vote';

  @override
  String votes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
    );
    return '$_temp0';
  }

  @override
  String get pollClosed => 'Poll closed';

  @override
  String get anonymous => 'Anonymous';

  @override
  String notifChatTitle(String channel) {
    return '$channel';
  }

  @override
  String notifAnnouncementTitle(String title) {
    return 'Announcement: $title';
  }

  @override
  String pollPreview(String question) {
    return 'Poll: $question';
  }

  @override
  String get liveStart => 'Go live';

  @override
  String get liveNeedsConnection => 'Connect to the internet to go live.';

  @override
  String get liveLeave => 'Leave live';

  @override
  String liveWatching(int count) {
    return '$count together';
  }

  @override
  String get liveFollow => 'Follow';

  @override
  String get liveFollowHint =>
      'When off, your page stays put when others turn.';

  @override
  String get sendCue => 'Send cue';

  @override
  String get cueAgain => 'Once more';

  @override
  String get cueChorus => 'To chorus';

  @override
  String get cueBridge => 'To bridge';

  @override
  String get cueEnding => 'Ending';

  @override
  String get cueKeyUp => 'Key up';

  @override
  String get cueSofter => 'Softer';

  @override
  String get cueFaster => 'Faster';

  @override
  String get cueSlower => 'Slower';

  @override
  String get cueNextSong => 'Next song';

  @override
  String get cueCustom => 'Type a cue';

  @override
  String get cueTo => 'To';

  @override
  String get cueEveryone => 'Everyone';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get allSetlists => 'Every setlist';

  @override
  String get allSetlistsHint =>
      'Also tell me about setlists for services I\'m not serving at.';

  @override
  String get pushSection => 'Push notifications';

  @override
  String get pushSetlists => 'Setlists';

  @override
  String get pushServing => 'Serving requests and swaps';

  @override
  String get pushRehearsals => 'Rehearsals';

  @override
  String get pushAnnouncements => 'Announcements';

  @override
  String get pushChat => 'Chat';

  @override
  String get pushJoining => 'Joining the team';

  @override
  String get pushOffHint =>
      'Turning one off stops the push only. It still shows in your notifications and chat unread counts.';

  @override
  String get offline => 'Offline';

  @override
  String get offlineShowingSaved =>
      'You\'re offline. Showing what\'s saved on this device.';

  @override
  String offlineNotesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes upload',
      one: '1 note uploads',
    );
    return '$_temp0 when you reconnect.';
  }

  @override
  String notesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes waiting',
      one: '1 note waiting',
    );
    return '$_temp0';
  }

  @override
  String unsentNotesSignOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes haven\'t',
      one: '1 note hasn\'t',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'them',
      one: 'it',
    );
    return '$_temp0 uploaded yet. Signing out deletes $_temp1.';
  }

  @override
  String get open => 'View';

  @override
  String get pushThisDevice => 'Push on this device';

  @override
  String get pushBlocked =>
      'Notifications for this app are turned off in your device or browser settings.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get nextService => 'Next service';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String inDays(int count) {
    return 'In $count days';
  }

  @override
  String get setlistComing => 'Setlist coming soon';

  @override
  String moreSongs(int count) {
    return '$count more';
  }

  @override
  String get partChatsToJoin => 'Part chats it joins';

  @override
  String get navHome => 'Home';

  @override
  String get todo => 'To do';

  @override
  String get nothingToDo => 'Nothing to do.';

  @override
  String rehearsalRsvpTodo(String title) {
    return 'Coming to the $title rehearsal?';
  }

  @override
  String get teamRehearsal => 'Team rehearsal';

  @override
  String get newAnnouncementTodo => 'New announcement';

  @override
  String joinRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count join requests',
      one: '1 join request',
    );
    return '$_temp0';
  }

  @override
  String get readiness => 'Getting ready';

  @override
  String setlistPublishedCount(int count) {
    return 'Setlist out, $count songs';
  }

  @override
  String setlistDraftCount(int count) {
    return 'Draft setlist, $count songs';
  }

  @override
  String get setlistNone => 'No setlist';

  @override
  String placesFilled(int accepted, int needed) {
    return '$accepted/$needed accepted';
  }

  @override
  String get placesUnset => 'No places set';

  @override
  String waitingCount(int count) {
    return '$count waiting';
  }

  @override
  String declinedCount(int count) {
    return '$count declined';
  }

  @override
  String unsentCount(int count) {
    return '$count not sent';
  }

  @override
  String rehearsalComing(int count, int total) {
    return 'Rehearsal: $count/$total coming';
  }

  @override
  String noAnswerCount(int count) {
    return '$count no answer';
  }

  @override
  String get noRehearsal => 'No rehearsal';

  @override
  String get mySchedule => 'My schedule';

  @override
  String get noScheduleSoon => 'Nothing in the next four weeks.';

  @override
  String get teamNews => 'Team news';

  @override
  String get noNews => 'No news.';

  @override
  String get servingLoad => 'Who\'s been serving';

  @override
  String get servingLoadHint =>
      'Times asked to serve in the last 8 weeks, to spot anyone carrying too much.';

  @override
  String get songNotes => 'Songs';

  @override
  String get mostPlayedRecently => 'Most played, last 3 months';

  @override
  String get notPlayedLately => 'Not played lately';

  @override
  String rehearsalAt(String when) {
    return 'Rehearsal $when';
  }

  @override
  String get moreCues => 'More cues';

  @override
  String get hideCues => 'Hide cues';

  @override
  String get showCues => 'Show cues';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountWarning =>
      'Your account, profile, chat messages, notes, assignments and personal settings will be permanently deleted. Songs, sheets and services shared with other members stay with their teams. Notes saved only on this device will also be deleted.';

  @override
  String get deleteAccountUnderstand =>
      'I understand that my account and personal data cannot be recovered.';

  @override
  String get accountNeedsOwner =>
      'You are the only owner of the teams below. Make another member an owner on the team page before deleting your account.';

  @override
  String deleteSoloTeams(String teams) {
    return 'Teams where you are the only member ($teams) and all their songs, sheets and services will also be deleted.';
  }

  @override
  String inTeamTimezone(String timezone) {
    return 'Team time zone: $timezone';
  }

  @override
  String get demoBanner => 'Demo · saved on this device only';

  @override
  String get demoReset => 'Reset';

  @override
  String get demoStart => 'Open demo';

  @override
  String get demoLiveHint =>
      'This demo previews live mode on this device only.';

  @override
  String get demoVideo => '3-minute tour';
}
