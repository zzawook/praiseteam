// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'PraiseTeam';

  @override
  String get loginTagline => '콘티, 악보, 로테이션을 팀이 함께 봐요.';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get devLoginTitle => '개발용 로그인 (로컬 서버 전용)';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get signIn => '로그인';

  @override
  String get signUp => '계정 만들기';

  @override
  String get signOut => '로그아웃';

  @override
  String get loading => '불러오는 중';

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get create => '만들기';

  @override
  String get delete => '삭제';

  @override
  String get close => '닫기';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사했어요';

  @override
  String get welcomeTitle => '찬양팀에 들어가기';

  @override
  String get welcomeBody => '초대 코드를 받았다면 바로 가입하고, 처음이라면 팀을 만들어요.';

  @override
  String get joinWithCode => '초대 코드로 가입';

  @override
  String get inviteCode => '초대 코드';

  @override
  String get inviteCodeHint => '8자리 코드';

  @override
  String get join => '가입하기';

  @override
  String get createTeam => '새 팀 만들기';

  @override
  String get teamName => '팀 이름';

  @override
  String get teamNameHint => '예: 청년부 찬양팀';

  @override
  String get pendingTitle => '승인을 기다리고 있어요';

  @override
  String pendingBody(String team) {
    return '$team 리더가 승인하면 바로 들어갈 수 있어요.';
  }

  @override
  String get checkAgain => '다시 확인';

  @override
  String get cancelRequest => '가입 요청 취소';

  @override
  String get joinAnotherTeam => '다른 팀에 가입';

  @override
  String get navTeam => '팀';

  @override
  String get navNotifications => '알림';

  @override
  String get navSettings => '설정';

  @override
  String get switchTeam => '팀 바꾸기';

  @override
  String get addTeam => '팀 추가';

  @override
  String get inviteTitle => '초대 코드';

  @override
  String get inviteHint => '이 코드를 새 팀원에게 보내주세요.';

  @override
  String get newInviteCode => '새 코드로 바꾸기';

  @override
  String get newInviteCodeConfirm => '지금 코드는 더 이상 쓸 수 없게 돼요. 새 코드로 바꿀까요?';

  @override
  String get joinRequests => '가입 요청';

  @override
  String get approve => '승인';

  @override
  String get reject => '거절';

  @override
  String get members => '멤버';

  @override
  String membersCount(int count) {
    return '멤버 $count명';
  }

  @override
  String get roleOwner => '관리자';

  @override
  String get roleLeader => '리더';

  @override
  String get roleMember => '멤버';

  @override
  String get you => '나';

  @override
  String get noPartsYet => '파트 미정';

  @override
  String get editParts => '파트 정하기';

  @override
  String get changeRole => '역할 바꾸기';

  @override
  String get removeFromTeam => '팀에서 내보내기';

  @override
  String removeConfirm(String name) {
    return '$name님을 팀에서 내보낼까요?';
  }

  @override
  String get parts => '파트';

  @override
  String get manageParts => '파트 관리';

  @override
  String get myParts => '내 파트';

  @override
  String get partsPickerHint => '섬길 수 있는 파트를 모두 골라주세요.';

  @override
  String get addPart => '파트 추가';

  @override
  String get partName => '파트 이름';

  @override
  String get renamePart => '이름 바꾸기';

  @override
  String get hidePart => '목록에서 숨기기';

  @override
  String get partKindVocal => '보컬';

  @override
  String get partKindInstrument => '악기';

  @override
  String get partKindTech => '음향·영상';

  @override
  String get notificationsEmpty => '새 알림이 오면 여기에 보여요.';

  @override
  String get notifJoinRequestTitle => '가입 요청';

  @override
  String notifJoinRequestBody(String name, String team) {
    return '$name님이 $team에 가입을 요청했어요.';
  }

  @override
  String get notifApprovedTitle => '가입 승인';

  @override
  String notifApprovedBody(String team) {
    return '$team에 가입됐어요.';
  }

  @override
  String get notifFallback => '새 알림';

  @override
  String get profile => '프로필';

  @override
  String get displayName => '이름';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '기기 설정 따르기';

  @override
  String get teamSettings => '팀 설정';

  @override
  String get requireApproval => '가입할 때 리더 승인 받기';

  @override
  String get leaveTeam => '팀 나가기';

  @override
  String leaveTeamConfirm(String team) {
    return '$team에서 나갈까요?';
  }

  @override
  String get errorInvalidCode => '초대 코드가 맞지 않아요. 대소문자 상관없이 8자리를 다시 확인해 주세요.';

  @override
  String get errorNotAllowed => '이 작업은 리더만 할 수 있어요.';

  @override
  String get errorLastOwner => '팀에는 관리자가 한 명 이상 있어야 해요. 다른 사람을 먼저 관리자로 정해주세요.';

  @override
  String get errorNetwork => '서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.';

  @override
  String get errorGoogleNotConfigured => 'Google 로그인이 아직 설정되지 않았어요.';

  @override
  String errorGeneric(String detail) {
    return '요청을 처리하지 못했어요: $detail';
  }

  @override
  String get navSessions => '예배';

  @override
  String get navSongs => '곡';

  @override
  String get upcomingSessions => '다가오는 예배';

  @override
  String get pastSessions => '지난 예배';

  @override
  String get noSessionsLeader => '예배를 추가하고 콘티를 준비해 보세요.';

  @override
  String get noSessionsMember => '리더가 예배를 추가하면 여기에 보여요.';

  @override
  String get addSession => '예배 추가';

  @override
  String get editSession => '예배 수정';

  @override
  String get deleteSession => '예배 삭제';

  @override
  String deleteSessionConfirm(String title) {
    return '\'$title\' 예배를 삭제할까요? 콘티도 함께 삭제돼요.';
  }

  @override
  String get sessionTitle => '예배 이름';

  @override
  String get sessionTitleHint => '예: 주일 2부 예배';

  @override
  String get date => '날짜';

  @override
  String get time => '시간';

  @override
  String get location => '장소';

  @override
  String get theme => '설교 본문이나 주제';

  @override
  String get notes => '메모';

  @override
  String get repeatWeekly => '매주 같은 시간에 반복';

  @override
  String repeatCount(int count) {
    return '$count주 동안';
  }

  @override
  String get templates => '템플릿';

  @override
  String get editTemplates => '템플릿 편집';

  @override
  String get sessionTemplates => '예배 템플릿';

  @override
  String get weeklyServices => '매주 드리는 예배';

  @override
  String get addTemplate => '템플릿 추가';

  @override
  String get editTemplate => '템플릿 수정';

  @override
  String get noTemplates =>
      '매주 같은 요일, 같은 시간, 같은 장소에서 드리는 예배를 등록해 두세요. 예배를 추가할 때 골라서 바로 채울 수 있어요.';

  @override
  String get saveAsTemplate => '템플릿으로 저장';

  @override
  String get saveAsTemplateHint => '다음부터는 골라서 이름, 요일, 시간, 장소를 채워요';

  @override
  String get templateTitleTaken => '같은 이름의 템플릿이 있어요';

  @override
  String deleteTemplateConfirm(String title) {
    return '\'$title\' 템플릿을 삭제할까요? 이미 추가한 예배는 그대로 남아요.';
  }

  @override
  String get weekday => '요일';

  @override
  String get setlist => '콘티';

  @override
  String get setlistDraft => '초안';

  @override
  String get setlistPublished => '공지됨';

  @override
  String songsCount(int count) {
    return '$count곡';
  }

  @override
  String get addSongToSetlist => '곡 추가';

  @override
  String get publishSetlist => '콘티 공지하기';

  @override
  String get republishSetlist => '바뀐 내용 공지하기';

  @override
  String get publishConfirm => '팀에 콘티를 공지할까요? 팀원들에게 알림이 가요.';

  @override
  String get republishConfirm => '바뀐 내용을 팀에 알릴까요?';

  @override
  String get published => '콘티를 공지했어요';

  @override
  String get noChanges => '지난 공지 이후 바뀐 게 없어요.';

  @override
  String get setlistEmptyLeader => '곡을 추가해서 콘티를 만들어요.';

  @override
  String get setlistEmptyMember => '아직 콘티가 공지되지 않았어요.';

  @override
  String get key => '키';

  @override
  String get songForm => '송폼';

  @override
  String get songFormHint => '예: I-V1-C-V2-C-B-C-O';

  @override
  String get sheet => '악보';

  @override
  String get noSheet => '악보 없음';

  @override
  String get removeFromSetlist => '콘티에서 빼기';

  @override
  String changeAdded(String songs) {
    return '추가: $songs';
  }

  @override
  String changeRemoved(String songs) {
    return '빠짐: $songs';
  }

  @override
  String changeKey(String changes) {
    return '키: $changes';
  }

  @override
  String changeTempo(String changes) {
    return '템포: $changes';
  }

  @override
  String get changeOrder => '순서 변경';

  @override
  String notifSetlistTitle(String session) {
    return '$session 콘티';
  }

  @override
  String notifSetlistUpdatedTitle(String session) {
    return '$session 콘티가 바뀌었어요';
  }

  @override
  String get searchSongs => '곡 이름이나 가수로 찾기';

  @override
  String get sortTitle => '이름순';

  @override
  String get sortRecent => '최근에 한 곡';

  @override
  String get sortMost => '많이 한 곡';

  @override
  String get sortLongAgo => '오래 안 한 곡';

  @override
  String get addSong => '곡 추가';

  @override
  String get editSong => '곡 정보 수정';

  @override
  String get deleteSong => '곡 삭제';

  @override
  String deleteSongConfirm(String title) {
    return '\'$title\' 곡을 라이브러리에서 삭제할까요?';
  }

  @override
  String get songInUse => '콘티에 쓰인 곡은 삭제할 수 없어요.';

  @override
  String get songTitle => '곡 이름';

  @override
  String get bpm => 'BPM';

  @override
  String get timeSignature => '박자';

  @override
  String get tags => '태그';

  @override
  String get tagsHint => '쉼표로 구분 (예: 감사, 빠른 곡)';

  @override
  String get originalLinks => '원곡 링크';

  @override
  String get addLink => '링크 추가';

  @override
  String get linkUrl => '주소 (https://...)';

  @override
  String get linkLabel => '이름 (선택)';

  @override
  String get versions => '버전';

  @override
  String get version => '버전';

  @override
  String get addVersion => '버전 추가';

  @override
  String get editVersion => '버전 수정';

  @override
  String get deleteVersion => '버전 삭제';

  @override
  String deleteVersionConfirm(String title) {
    return '\'$title\' 버전을 삭제할까요? 이 버전의 악보와 링크도 함께 삭제돼요.';
  }

  @override
  String get versionInUse => '콘티에 쓰인 버전은 삭제할 수 없어요.';

  @override
  String get versionName => '가수·버전';

  @override
  String get versionNameHint => '예: 마커스워십, 어노인팅 라이브';

  @override
  String get unnamedVersion => '기본 버전';

  @override
  String get firstVersion => '첫 버전';

  @override
  String get firstVersionHint =>
      '가수나 편곡이 다르면 곡 화면에서 버전을 더 추가할 수 있어요. 키와 템포는 콘티에서 그날만 바꿀 수도 있어요.';

  @override
  String get playedLast => '마지막에 쓴 버전';

  @override
  String get songHasNoVersion => '이 곡에는 버전이 없어요. 곡 화면에서 버전을 추가해 주세요.';

  @override
  String changeVersion(String changes) {
    return '버전: $changes';
  }

  @override
  String get sheets => '악보';

  @override
  String get uploadSheet => '악보 올리기';

  @override
  String get uploadSheetHint => 'PDF나 사진을 고르면 악보 한 개로 저장돼요.';

  @override
  String get sheetLabel => '악보 이름 (예: 코드, 드럼)';

  @override
  String get uploading => '올리는 중';

  @override
  String pages(int count) {
    return '$count쪽';
  }

  @override
  String get history => '기록';

  @override
  String playedTimes(int count) {
    return '총 $count회';
  }

  @override
  String get neverPlayed => '아직 안 했어요';

  @override
  String lastPlayed(String ago) {
    return '마지막 $ago';
  }

  @override
  String usualKey(String key) {
    return '주로 $key';
  }

  @override
  String nextPlanned(String date) {
    return '다음 예정 $date';
  }

  @override
  String get today => '오늘';

  @override
  String daysAgo(int n) {
    return '$n일 전';
  }

  @override
  String weeksAgo(int n) {
    return '$n주 전';
  }

  @override
  String monthsAgo(int n) {
    return '$n개월 전';
  }

  @override
  String yearsAgo(int n) {
    return '$n년 전';
  }

  @override
  String get stats => '통계';

  @override
  String get topSongs => '많이 한 곡';

  @override
  String notPlayedSince(int months) {
    return '$months개월 넘게 안 한 곡';
  }

  @override
  String get period3m => '3개월';

  @override
  String get period6m => '6개월';

  @override
  String get period1y => '1년';

  @override
  String get periodAll => '전체';

  @override
  String timesShort(int count) {
    return '$count회';
  }

  @override
  String get viewSheet => '악보 보기';

  @override
  String get viewSheets => '악보 보기';

  @override
  String get annotate => '필기';

  @override
  String get doneAnnotating => '완료';

  @override
  String get pen => '펜';

  @override
  String get highlighter => '형광펜';

  @override
  String get eraser => '지우개';

  @override
  String get inkForMe => '나만 보기';

  @override
  String get inkForTeam => '팀 공용';

  @override
  String get showTeamInk => '팀 필기 보이기';

  @override
  String get showMyInk => '내 필기 보이기';

  @override
  String get undo => '실행 취소';

  @override
  String get redo => '다시 실행';

  @override
  String get stageMode => '무대 모드';

  @override
  String get copyPreviousInk => '지난 필기 가져오기';

  @override
  String copiedInk(int count) {
    return '필기 $count개를 가져왔어요';
  }

  @override
  String get noPreviousInk => '같은 악보로 한 지난 예배에 내 필기가 없어요.';

  @override
  String get noSheetForSong => '이 곡에는 악보가 없어요';

  @override
  String pageOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get inkColor => '색';

  @override
  String unsavedInk(int count) {
    return '저장 대기 $count';
  }

  @override
  String get rotation => '로테이션';

  @override
  String get rotationList => '목록';

  @override
  String get rotationTable => '표';

  @override
  String openPlaces(int count) {
    return '빈 자리 $count';
  }

  @override
  String get myServing => '내 섬김';

  @override
  String get noServing => '다가오는 섬김이 없어요.';

  @override
  String get accept => '수락';

  @override
  String get decline => '거절';

  @override
  String get declineReason => '못 하는 이유 (선택)';

  @override
  String get statusDraft => '초안';

  @override
  String get statusPending => '응답 대기';

  @override
  String get statusAccepted => '수락';

  @override
  String get statusDeclined => '거절';

  @override
  String get autoAssign => '자동 배정';

  @override
  String autoAssignDone(int count) {
    return '$count자리를 초안으로 채웠어요. 확인하고 고친 뒤 보내세요.';
  }

  @override
  String sendDrafts(int count) {
    return '보내기 ($count)';
  }

  @override
  String sendDraftsConfirm(int count) {
    return '초안 $count건을 보낼까요? 배정된 사람에게 알림이 가요.';
  }

  @override
  String sent(int count) {
    return '$count건을 보냈어요';
  }

  @override
  String get addPerson => '사람 추가';

  @override
  String get replacePerson => '다른 사람으로 바꾸기';

  @override
  String get removePerson => '빼기';

  @override
  String needed(int count) {
    return '$count명';
  }

  @override
  String get setNeeded => '필요 인원';

  @override
  String get defaultNeeded => '기본 필요 인원';

  @override
  String get defaultNeededHint => '새로 만드는 예배에 이 인원이 들어가요.';

  @override
  String get unavailableThatDay => '그날 안 돼요';

  @override
  String get alreadyServing => '이미 섬김';

  @override
  String get requestSwap => '대타 요청';

  @override
  String get swapMessage => '남길 말 (선택)';

  @override
  String get swapRequested => '같은 파트 팀원들에게 대타를 요청했어요';

  @override
  String get cancelSwap => '대타 요청 취소';

  @override
  String get swapOpen => '대타 구함';

  @override
  String get takeSwap => '대신 섬기기';

  @override
  String get swapTaken => '섬김을 넘겨받았어요';

  @override
  String get blockouts => '불가능 날짜';

  @override
  String get myBlockouts => '내 불가능 날짜';

  @override
  String get teamBlockouts => '팀원 불가능 날짜';

  @override
  String get addBlockout => '날짜 추가';

  @override
  String get blockoutNote => '메모 (선택, 리더만 봐요)';

  @override
  String get noBlockouts => '등록된 날짜가 없어요.';

  @override
  String get servingPeople => '섬기는 사람';

  @override
  String notifAssignmentRequested(String session, String part) {
    return '$session $part 섬김 요청';
  }

  @override
  String notifAssignmentDeclined(String name, String session, String part) {
    return '$name님이 $session $part 섬김을 거절했어요';
  }

  @override
  String notifAssignmentRemoved(String session, String part) {
    return '$session $part 섬김에서 빠졌어요';
  }

  @override
  String notifAssignmentNudge(String session, String part) {
    return '$session $part 섬김 요청에 아직 답하지 않았어요';
  }

  @override
  String notifSwapRequested(String name, String session, String part) {
    return '$name님이 $session $part 대타를 구해요';
  }

  @override
  String notifSwapFilled(String name, String session, String part) {
    return '$name님이 $session $part을(를) 맡았어요';
  }

  @override
  String notifServiceReminder(String session, String part) {
    return '내일 $session $part 섬김이 있어요';
  }

  @override
  String notifRehearsalScheduled(String when) {
    return '연습 일정: $when';
  }

  @override
  String notifRehearsalReminder(String when) {
    return '곧 연습이에요: $when';
  }

  @override
  String get rehearsals => '연습';

  @override
  String get addRehearsal => '연습 추가';

  @override
  String get noRehearsals => '잡힌 연습이 없어요.';

  @override
  String get rsvpGoing => '참석';

  @override
  String get rsvpLate => '지각';

  @override
  String get rsvpNotGoing => '불참';

  @override
  String get attendanceCheck => '출석 체크';

  @override
  String get present => '출석';

  @override
  String get absent => '결석';

  @override
  String get calendarSubscribe => '캘린더에 구독';

  @override
  String get calendarHint => '내 섬김과 연습 일정이 캘린더에 자동으로 들어가요.';

  @override
  String get openInCalendar => '캘린더 앱에서 열기';

  @override
  String get newCalendarUrl => '주소 새로 만들기';

  @override
  String get newCalendarUrlHint => '새로 만들면 예전 주소로는 더 이상 보이지 않아요.';

  @override
  String get googleCalendarHint =>
      '구글 캘린더는 웹에서 \'다른 캘린더 > URL로 추가\'에 붙여넣어요. 반영되기까지 몇 시간 걸릴 수 있어요.';

  @override
  String get navChat => '채팅';

  @override
  String get announcements => '공지';

  @override
  String get newAnnouncement => '공지 쓰기';

  @override
  String get editAnnouncement => '공지 수정';

  @override
  String get deleteAnnouncement => '공지 삭제';

  @override
  String get announcementTitle => '제목';

  @override
  String get announcementBody => '내용';

  @override
  String get pinAnnouncement => '맨 위에 고정';

  @override
  String get pinned => '고정';

  @override
  String get noAnnouncements => '아직 공지가 없어요.';

  @override
  String get newBadge => '새 글';

  @override
  String get channels => '채널';

  @override
  String get archivedChannel => '지난 예배 (읽기만 가능)';

  @override
  String get newChannel => '채널 만들기';

  @override
  String get channelName => '채널 이름';

  @override
  String get channelPartsHint => '이 파트를 맡은 사람들이 들어와요. 리더는 모든 채널을 봐요.';

  @override
  String get noMessages => '첫 메시지를 남겨보세요.';

  @override
  String get messageHint => '메시지';

  @override
  String get send => '보내기';

  @override
  String get mute => '알림 끄기';

  @override
  String get unmute => '알림 켜기';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get deletedMessage => '삭제된 메시지예요';

  @override
  String get newPoll => '투표 만들기';

  @override
  String get pollQuestion => '질문';

  @override
  String pollOption(int n) {
    return '선택지 $n';
  }

  @override
  String get addOption => '선택지 추가';

  @override
  String get multipleChoice => '여러 개 고를 수 있게';

  @override
  String get anonymousPoll => '익명 투표';

  @override
  String get vote => '투표하기';

  @override
  String votes(int count) {
    return '$count표';
  }

  @override
  String get pollClosed => '마감된 투표';

  @override
  String get anonymous => '익명';

  @override
  String notifChatTitle(String channel) {
    return '$channel';
  }

  @override
  String notifAnnouncementTitle(String title) {
    return '공지: $title';
  }

  @override
  String pollPreview(String question) {
    return '투표: $question';
  }

  @override
  String get liveStart => '라이브하기';

  @override
  String get liveNeedsConnection => '라이브를 시작하려면 인터넷에 연결해 주세요.';

  @override
  String get liveLeave => '라이브 나가기';

  @override
  String liveWatching(int count) {
    return '$count명 함께';
  }

  @override
  String get liveFollow => '따라가기';

  @override
  String get liveFollowHint => '끄면 다른 사람이 넘겨도 내 화면은 그대로예요.';

  @override
  String get sendCue => '큐 보내기';

  @override
  String get cueAgain => '한 번 더';

  @override
  String get cueChorus => '후렴으로';

  @override
  String get cueBridge => '브릿지로';

  @override
  String get cueEnding => '엔딩';

  @override
  String get cueKeyUp => '키 업';

  @override
  String get cueSofter => '작게';

  @override
  String get cueFaster => '빠르게';

  @override
  String get cueSlower => '천천히';

  @override
  String get cueNextSong => '다음 곡';

  @override
  String get cueCustom => '직접 입력';

  @override
  String get cueTo => '받는 사람';

  @override
  String get cueEveryone => '모두';

  @override
  String get notificationsSection => '알림';

  @override
  String get allSetlists => '모든 예배 콘티 받기';

  @override
  String get allSetlistsHint => '섬기지 않는 예배의 콘티 공지도 알려 줘요.';

  @override
  String get pushSection => '푸시 알림';

  @override
  String get pushSetlists => '콘티 공지';

  @override
  String get pushServing => '섬김 요청과 대타';

  @override
  String get pushRehearsals => '연습';

  @override
  String get pushAnnouncements => '공지';

  @override
  String get pushChat => '채팅';

  @override
  String get pushJoining => '팀 가입';

  @override
  String get pushOffHint => '꺼도 알림 목록과 채팅의 안 읽은 표시는 그대로예요.';

  @override
  String get offline => '오프라인';

  @override
  String get offlineShowingSaved => '오프라인이에요. 이 기기에 저장해 둔 내용을 보여 줘요.';

  @override
  String offlineNotesWaiting(int count) {
    return '필기 $count개는 연결되면 올라가요.';
  }

  @override
  String notesWaiting(int count) {
    return '필기 $count개 대기';
  }

  @override
  String unsentNotesSignOut(int count) {
    return '아직 올라가지 않은 필기가 $count개 있어요. 로그아웃하면 이 필기는 사라져요.';
  }

  @override
  String get open => '보기';

  @override
  String get pushThisDevice => '이 기기에서 푸시 받기';

  @override
  String get pushBlocked => '기기나 브라우저 설정에서 이 앱의 알림이 꺼져 있어요.';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get nextService => '다음 예배';

  @override
  String get tomorrow => '내일';

  @override
  String inDays(int count) {
    return '$count일 후';
  }

  @override
  String get setlistComing => '콘티 준비 중';

  @override
  String moreSongs(int count) {
    return '외 $count곡';
  }

  @override
  String get partChatsToJoin => '이 파트가 들어갈 채팅방';

  @override
  String get navHome => '홈';

  @override
  String get todo => '할 일';

  @override
  String get nothingToDo => '할 일이 없어요.';

  @override
  String rehearsalRsvpTodo(String title) {
    return '$title 연습에 오나요?';
  }

  @override
  String get teamRehearsal => '팀 연습';

  @override
  String get newAnnouncementTodo => '새 공지가 있어요';

  @override
  String joinRequestsCount(int count) {
    return '가입 요청 $count명';
  }

  @override
  String get readiness => '준비 현황';

  @override
  String setlistPublishedCount(int count) {
    return '콘티 공지됨 $count곡';
  }

  @override
  String setlistDraftCount(int count) {
    return '콘티 초안 $count곡';
  }

  @override
  String get setlistNone => '콘티 없음';

  @override
  String placesFilled(int accepted, int needed) {
    return '수락 $accepted/$needed';
  }

  @override
  String get placesUnset => '필요 인원 미정';

  @override
  String waitingCount(int count) {
    return '응답 대기 $count';
  }

  @override
  String declinedCount(int count) {
    return '거절 $count';
  }

  @override
  String unsentCount(int count) {
    return '보내지 않음 $count';
  }

  @override
  String rehearsalComing(int count, int total) {
    return '연습 참석 $count/$total';
  }

  @override
  String noAnswerCount(int count) {
    return '미응답 $count';
  }

  @override
  String get noRehearsal => '연습 없음';

  @override
  String get mySchedule => '내 일정';

  @override
  String get noScheduleSoon => '앞으로 4주 동안 잡힌 일정이 없어요.';

  @override
  String get teamNews => '팀 소식';

  @override
  String get noNews => '새 소식이 없어요.';

  @override
  String get servingLoad => '섬김 분배';

  @override
  String get servingLoadHint => '최근 8주 동안 섬긴 횟수예요. 한 사람에게 몰리지 않는지 봐 주세요.';

  @override
  String get songNotes => '곡 참고';

  @override
  String get mostPlayedRecently => '최근 3개월 많이 한 곡';

  @override
  String get notPlayedLately => '오래 안 한 곡';

  @override
  String rehearsalAt(String when) {
    return '연습 $when';
  }

  @override
  String get moreCues => '큐 더보기';

  @override
  String get hideCues => '큐 숨기기';

  @override
  String get showCues => '큐 보이기';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountWarning =>
      '계정과 프로필, 채팅 메시지, 필기, 편성 및 개인 설정이 영구 삭제돼요. 다른 팀원들과 공유한 곡·악보·예배 기록은 팀에 남아요. 기기에만 저장된 필기도 삭제돼요.';

  @override
  String get deleteAccountUnderstand => '삭제한 계정과 개인 데이터는 복구할 수 없다는 점을 이해했어요.';

  @override
  String get accountNeedsOwner =>
      '아래 팀의 유일한 관리자예요. 팀 화면에서 다른 팀원에게 관리자 권한을 넘긴 뒤 계정을 삭제해 주세요.';

  @override
  String deleteSoloTeams(String teams) {
    return '혼자 남아 있는 팀($teams)과 그 팀의 모든 곡·악보·일정도 삭제돼요.';
  }

  @override
  String inTeamTimezone(String timezone) {
    return '팀 시간대: $timezone';
  }

  @override
  String get demoBanner => '데모 · 이 기기에만 저장돼요';

  @override
  String get demoReset => '초기화';

  @override
  String get demoStart => '데모 시작하기';

  @override
  String get demoLiveHint => '데모에서는 이 기기에서 라이브 화면을 미리 볼 수 있어요.';

  @override
  String get demoVideo => '3분 소개 영상';
}
