import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'PraiseTeam'**
  String get appTitle;

  /// No description provided for @loginTagline.
  ///
  /// In ko, this message translates to:
  /// **'콘티, 악보, 로테이션을 팀이 함께 봐요.'**
  String get loginTagline;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// No description provided for @devLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'개발용 로그인 (로컬 서버 전용)'**
  String get devLoginTitle;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ko, this message translates to:
  /// **'계정 만들기'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @create.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get copied;

  /// No description provided for @welcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'찬양팀에 들어가기'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 받았다면 바로 가입하고, 처음이라면 팀을 만들어요.'**
  String get welcomeBody;

  /// No description provided for @joinWithCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드로 가입'**
  String get joinWithCode;

  /// No description provided for @inviteCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get inviteCode;

  /// No description provided for @inviteCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'8자리 코드'**
  String get inviteCodeHint;

  /// No description provided for @join.
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get join;

  /// No description provided for @createTeam.
  ///
  /// In ko, this message translates to:
  /// **'새 팀 만들기'**
  String get createTeam;

  /// No description provided for @teamName.
  ///
  /// In ko, this message translates to:
  /// **'팀 이름'**
  String get teamName;

  /// No description provided for @teamNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 청년부 찬양팀'**
  String get teamNameHint;

  /// No description provided for @pendingTitle.
  ///
  /// In ko, this message translates to:
  /// **'승인을 기다리고 있어요'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In ko, this message translates to:
  /// **'{team} 리더가 승인하면 바로 들어갈 수 있어요.'**
  String pendingBody(String team);

  /// No description provided for @checkAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get checkAgain;

  /// No description provided for @cancelRequest.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청 취소'**
  String get cancelRequest;

  /// No description provided for @joinAnotherTeam.
  ///
  /// In ko, this message translates to:
  /// **'다른 팀에 가입'**
  String get joinAnotherTeam;

  /// No description provided for @navTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get navTeam;

  /// No description provided for @navNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get navNotifications;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @switchTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 바꾸기'**
  String get switchTeam;

  /// No description provided for @addTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 추가'**
  String get addTeam;

  /// No description provided for @inviteTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get inviteTitle;

  /// No description provided for @inviteHint.
  ///
  /// In ko, this message translates to:
  /// **'이 코드를 새 팀원에게 보내주세요.'**
  String get inviteHint;

  /// No description provided for @newInviteCode.
  ///
  /// In ko, this message translates to:
  /// **'새 코드로 바꾸기'**
  String get newInviteCode;

  /// No description provided for @newInviteCodeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'지금 코드는 더 이상 쓸 수 없게 돼요. 새 코드로 바꿀까요?'**
  String get newInviteCodeConfirm;

  /// No description provided for @joinRequests.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청'**
  String get joinRequests;

  /// No description provided for @approve.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get reject;

  /// No description provided for @members.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get members;

  /// No description provided for @membersCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String membersCount(int count);

  /// No description provided for @roleOwner.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get roleOwner;

  /// No description provided for @roleLeader.
  ///
  /// In ko, this message translates to:
  /// **'리더'**
  String get roleLeader;

  /// No description provided for @roleMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get roleMember;

  /// No description provided for @you.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get you;

  /// No description provided for @noPartsYet.
  ///
  /// In ko, this message translates to:
  /// **'파트 미정'**
  String get noPartsYet;

  /// No description provided for @editParts.
  ///
  /// In ko, this message translates to:
  /// **'파트 정하기'**
  String get editParts;

  /// No description provided for @changeRole.
  ///
  /// In ko, this message translates to:
  /// **'역할 바꾸기'**
  String get changeRole;

  /// No description provided for @removeFromTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀에서 내보내기'**
  String get removeFromTeam;

  /// No description provided for @removeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 팀에서 내보낼까요?'**
  String removeConfirm(String name);

  /// No description provided for @parts.
  ///
  /// In ko, this message translates to:
  /// **'파트'**
  String get parts;

  /// No description provided for @manageParts.
  ///
  /// In ko, this message translates to:
  /// **'파트 관리'**
  String get manageParts;

  /// No description provided for @myParts.
  ///
  /// In ko, this message translates to:
  /// **'내 파트'**
  String get myParts;

  /// No description provided for @partsPickerHint.
  ///
  /// In ko, this message translates to:
  /// **'섬길 수 있는 파트를 모두 골라주세요.'**
  String get partsPickerHint;

  /// No description provided for @addPart.
  ///
  /// In ko, this message translates to:
  /// **'파트 추가'**
  String get addPart;

  /// No description provided for @partName.
  ///
  /// In ko, this message translates to:
  /// **'파트 이름'**
  String get partName;

  /// No description provided for @renamePart.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get renamePart;

  /// No description provided for @hidePart.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 숨기기'**
  String get hidePart;

  /// No description provided for @partKindVocal.
  ///
  /// In ko, this message translates to:
  /// **'보컬'**
  String get partKindVocal;

  /// No description provided for @partKindInstrument.
  ///
  /// In ko, this message translates to:
  /// **'악기'**
  String get partKindInstrument;

  /// No description provided for @partKindTech.
  ///
  /// In ko, this message translates to:
  /// **'음향·영상'**
  String get partKindTech;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'새 알림이 오면 여기에 보여요.'**
  String get notificationsEmpty;

  /// No description provided for @notifJoinRequestTitle.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청'**
  String get notifJoinRequestTitle;

  /// No description provided for @notifJoinRequestBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {team}에 가입을 요청했어요.'**
  String notifJoinRequestBody(String name, String team);

  /// No description provided for @notifApprovedTitle.
  ///
  /// In ko, this message translates to:
  /// **'가입 승인'**
  String get notifApprovedTitle;

  /// No description provided for @notifApprovedBody.
  ///
  /// In ko, this message translates to:
  /// **'{team}에 가입됐어요.'**
  String notifApprovedBody(String team);

  /// No description provided for @notifFallback.
  ///
  /// In ko, this message translates to:
  /// **'새 알림'**
  String get notifFallback;

  /// No description provided for @profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get displayName;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정 따르기'**
  String get languageSystem;

  /// No description provided for @teamSettings.
  ///
  /// In ko, this message translates to:
  /// **'팀 설정'**
  String get teamSettings;

  /// No description provided for @requireApproval.
  ///
  /// In ko, this message translates to:
  /// **'가입할 때 리더 승인 받기'**
  String get requireApproval;

  /// No description provided for @leaveTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 나가기'**
  String get leaveTeam;

  /// No description provided for @leaveTeamConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{team}에서 나갈까요?'**
  String leaveTeamConfirm(String team);

  /// No description provided for @errorInvalidCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드가 맞지 않아요. 대소문자 상관없이 8자리를 다시 확인해 주세요.'**
  String get errorInvalidCode;

  /// No description provided for @errorNotAllowed.
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 리더만 할 수 있어요.'**
  String get errorNotAllowed;

  /// No description provided for @errorLastOwner.
  ///
  /// In ko, this message translates to:
  /// **'팀에는 관리자가 한 명 이상 있어야 해요. 다른 사람을 먼저 관리자로 정해주세요.'**
  String get errorLastOwner;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.'**
  String get errorNetwork;

  /// No description provided for @errorGoogleNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인이 아직 설정되지 않았어요.'**
  String get errorGoogleNotConfigured;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'요청을 처리하지 못했어요: {detail}'**
  String errorGeneric(String detail);

  /// No description provided for @navSessions.
  ///
  /// In ko, this message translates to:
  /// **'예배'**
  String get navSessions;

  /// No description provided for @navSongs.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get navSongs;

  /// No description provided for @upcomingSessions.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 예배'**
  String get upcomingSessions;

  /// No description provided for @pastSessions.
  ///
  /// In ko, this message translates to:
  /// **'지난 예배'**
  String get pastSessions;

  /// No description provided for @noSessionsLeader.
  ///
  /// In ko, this message translates to:
  /// **'예배를 추가하고 콘티를 준비해 보세요.'**
  String get noSessionsLeader;

  /// No description provided for @noSessionsMember.
  ///
  /// In ko, this message translates to:
  /// **'리더가 예배를 추가하면 여기에 보여요.'**
  String get noSessionsMember;

  /// No description provided for @addSession.
  ///
  /// In ko, this message translates to:
  /// **'예배 추가'**
  String get addSession;

  /// No description provided for @editSession.
  ///
  /// In ko, this message translates to:
  /// **'예배 수정'**
  String get editSession;

  /// No description provided for @deleteSession.
  ///
  /// In ko, this message translates to:
  /// **'예배 삭제'**
  String get deleteSession;

  /// No description provided for @deleteSessionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 예배를 삭제할까요? 콘티도 함께 삭제돼요.'**
  String deleteSessionConfirm(String title);

  /// No description provided for @sessionTitle.
  ///
  /// In ko, this message translates to:
  /// **'예배 이름'**
  String get sessionTitle;

  /// No description provided for @sessionTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 주일 2부 예배'**
  String get sessionTitleHint;

  /// No description provided for @date.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get date;

  /// No description provided for @time.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get time;

  /// No description provided for @location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get location;

  /// No description provided for @theme.
  ///
  /// In ko, this message translates to:
  /// **'설교 본문이나 주제'**
  String get theme;

  /// No description provided for @notes.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get notes;

  /// No description provided for @repeatWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주 같은 시간에 반복'**
  String get repeatWeekly;

  /// No description provided for @repeatCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}주 동안'**
  String repeatCount(int count);

  /// No description provided for @templates.
  ///
  /// In ko, this message translates to:
  /// **'템플릿'**
  String get templates;

  /// No description provided for @editTemplates.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 편집'**
  String get editTemplates;

  /// No description provided for @sessionTemplates.
  ///
  /// In ko, this message translates to:
  /// **'예배 템플릿'**
  String get sessionTemplates;

  /// No description provided for @weeklyServices.
  ///
  /// In ko, this message translates to:
  /// **'매주 드리는 예배'**
  String get weeklyServices;

  /// No description provided for @addTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 추가'**
  String get addTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 수정'**
  String get editTemplate;

  /// No description provided for @noTemplates.
  ///
  /// In ko, this message translates to:
  /// **'매주 같은 요일, 같은 시간, 같은 장소에서 드리는 예배를 등록해 두세요. 예배를 추가할 때 골라서 바로 채울 수 있어요.'**
  String get noTemplates;

  /// No description provided for @saveAsTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿으로 저장'**
  String get saveAsTemplate;

  /// No description provided for @saveAsTemplateHint.
  ///
  /// In ko, this message translates to:
  /// **'다음부터는 골라서 이름, 요일, 시간, 장소를 채워요'**
  String get saveAsTemplateHint;

  /// No description provided for @templateTitleTaken.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 템플릿이 있어요'**
  String get templateTitleTaken;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 템플릿을 삭제할까요? 이미 추가한 예배는 그대로 남아요.'**
  String deleteTemplateConfirm(String title);

  /// No description provided for @weekday.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get weekday;

  /// No description provided for @setlist.
  ///
  /// In ko, this message translates to:
  /// **'콘티'**
  String get setlist;

  /// No description provided for @setlistDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get setlistDraft;

  /// No description provided for @setlistPublished.
  ///
  /// In ko, this message translates to:
  /// **'공지됨'**
  String get setlistPublished;

  /// No description provided for @songsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡'**
  String songsCount(int count);

  /// No description provided for @addSongToSetlist.
  ///
  /// In ko, this message translates to:
  /// **'곡 추가'**
  String get addSongToSetlist;

  /// No description provided for @publishSetlist.
  ///
  /// In ko, this message translates to:
  /// **'콘티 공지하기'**
  String get publishSetlist;

  /// No description provided for @republishSetlist.
  ///
  /// In ko, this message translates to:
  /// **'바뀐 내용 공지하기'**
  String get republishSetlist;

  /// No description provided for @publishConfirm.
  ///
  /// In ko, this message translates to:
  /// **'팀에 콘티를 공지할까요? 팀원들에게 알림이 가요.'**
  String get publishConfirm;

  /// No description provided for @republishConfirm.
  ///
  /// In ko, this message translates to:
  /// **'바뀐 내용을 팀에 알릴까요?'**
  String get republishConfirm;

  /// No description provided for @published.
  ///
  /// In ko, this message translates to:
  /// **'콘티를 공지했어요'**
  String get published;

  /// No description provided for @noChanges.
  ///
  /// In ko, this message translates to:
  /// **'지난 공지 이후 바뀐 게 없어요.'**
  String get noChanges;

  /// No description provided for @setlistEmptyLeader.
  ///
  /// In ko, this message translates to:
  /// **'곡을 추가해서 콘티를 만들어요.'**
  String get setlistEmptyLeader;

  /// No description provided for @setlistEmptyMember.
  ///
  /// In ko, this message translates to:
  /// **'아직 콘티가 공지되지 않았어요.'**
  String get setlistEmptyMember;

  /// No description provided for @key.
  ///
  /// In ko, this message translates to:
  /// **'키'**
  String get key;

  /// No description provided for @songForm.
  ///
  /// In ko, this message translates to:
  /// **'송폼'**
  String get songForm;

  /// No description provided for @selectedVersion.
  ///
  /// In ko, this message translates to:
  /// **'선택한 버전'**
  String get selectedVersion;

  /// No description provided for @referenceLinks.
  ///
  /// In ko, this message translates to:
  /// **'참고 링크'**
  String get referenceLinks;

  /// No description provided for @noVersionLinks.
  ///
  /// In ko, this message translates to:
  /// **'이 버전에는 참고 링크가 없어요. 곡 전체 정보에서 다른 버전도 확인할 수 있어요.'**
  String get noVersionLinks;

  /// No description provided for @fullSongDetails.
  ///
  /// In ko, this message translates to:
  /// **'곡 전체 정보'**
  String get fullSongDetails;

  /// No description provided for @editSetlistItem.
  ///
  /// In ko, this message translates to:
  /// **'콘티 수정'**
  String get editSetlistItem;

  /// No description provided for @watchOnYouTube.
  ///
  /// In ko, this message translates to:
  /// **'YouTube에서 보기'**
  String get watchOnYouTube;

  /// No description provided for @linkOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'링크를 열지 못했어요. 다시 시도해 주세요.'**
  String get linkOpenFailed;

  /// No description provided for @songFormHint.
  ///
  /// In ko, this message translates to:
  /// **'자유롭게 적어 주세요. 줄바꿈도 그대로 저장돼요.'**
  String get songFormHint;

  /// No description provided for @sheet.
  ///
  /// In ko, this message translates to:
  /// **'악보'**
  String get sheet;

  /// No description provided for @noSheet.
  ///
  /// In ko, this message translates to:
  /// **'악보 없음'**
  String get noSheet;

  /// No description provided for @removeFromSetlist.
  ///
  /// In ko, this message translates to:
  /// **'콘티에서 빼기'**
  String get removeFromSetlist;

  /// No description provided for @changeAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가: {songs}'**
  String changeAdded(String songs);

  /// No description provided for @changeRemoved.
  ///
  /// In ko, this message translates to:
  /// **'빠짐: {songs}'**
  String changeRemoved(String songs);

  /// No description provided for @changeKey.
  ///
  /// In ko, this message translates to:
  /// **'키: {changes}'**
  String changeKey(String changes);

  /// No description provided for @changeTempo.
  ///
  /// In ko, this message translates to:
  /// **'템포: {changes}'**
  String changeTempo(String changes);

  /// No description provided for @changeOrder.
  ///
  /// In ko, this message translates to:
  /// **'순서 변경'**
  String get changeOrder;

  /// No description provided for @notifSetlistTitle.
  ///
  /// In ko, this message translates to:
  /// **'{session} 콘티'**
  String notifSetlistTitle(String session);

  /// No description provided for @notifSetlistUpdatedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{session} 콘티가 바뀌었어요'**
  String notifSetlistUpdatedTitle(String session);

  /// No description provided for @searchSongs.
  ///
  /// In ko, this message translates to:
  /// **'곡 이름이나 가수로 찾기'**
  String get searchSongs;

  /// No description provided for @sortTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get sortTitle;

  /// No description provided for @sortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근에 한 곡'**
  String get sortRecent;

  /// No description provided for @sortMost.
  ///
  /// In ko, this message translates to:
  /// **'많이 한 곡'**
  String get sortMost;

  /// No description provided for @sortLongAgo.
  ///
  /// In ko, this message translates to:
  /// **'오래 안 한 곡'**
  String get sortLongAgo;

  /// No description provided for @addSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 추가'**
  String get addSong;

  /// No description provided for @editSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 수정'**
  String get editSong;

  /// No description provided for @deleteSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 삭제'**
  String get deleteSong;

  /// No description provided for @deleteSongConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 곡을 라이브러리에서 삭제할까요?'**
  String deleteSongConfirm(String title);

  /// No description provided for @songInUse.
  ///
  /// In ko, this message translates to:
  /// **'콘티에 쓰인 곡은 삭제할 수 없어요.'**
  String get songInUse;

  /// No description provided for @songTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 이름'**
  String get songTitle;

  /// No description provided for @bpm.
  ///
  /// In ko, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @timeSignature.
  ///
  /// In ko, this message translates to:
  /// **'박자'**
  String get timeSignature;

  /// No description provided for @tags.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분 (예: 감사, 빠른 곡)'**
  String get tagsHint;

  /// No description provided for @originalLinks.
  ///
  /// In ko, this message translates to:
  /// **'원곡 링크'**
  String get originalLinks;

  /// No description provided for @addLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 추가'**
  String get addLink;

  /// No description provided for @linkUrl.
  ///
  /// In ko, this message translates to:
  /// **'주소 (https://...)'**
  String get linkUrl;

  /// No description provided for @linkLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름 (선택)'**
  String get linkLabel;

  /// No description provided for @versions.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get versions;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get version;

  /// No description provided for @addVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 추가'**
  String get addVersion;

  /// No description provided for @editVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 수정'**
  String get editVersion;

  /// No description provided for @deleteVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 삭제'**
  String get deleteVersion;

  /// No description provided for @deleteVersionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 버전을 삭제할까요? 이 버전의 악보와 링크도 함께 삭제돼요.'**
  String deleteVersionConfirm(String title);

  /// No description provided for @versionInUse.
  ///
  /// In ko, this message translates to:
  /// **'콘티에 쓰인 버전은 삭제할 수 없어요.'**
  String get versionInUse;

  /// No description provided for @versionName.
  ///
  /// In ko, this message translates to:
  /// **'가수·버전'**
  String get versionName;

  /// No description provided for @versionNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 마커스워십, 어노인팅 라이브'**
  String get versionNameHint;

  /// No description provided for @unnamedVersion.
  ///
  /// In ko, this message translates to:
  /// **'기본 버전'**
  String get unnamedVersion;

  /// No description provided for @firstVersion.
  ///
  /// In ko, this message translates to:
  /// **'첫 버전'**
  String get firstVersion;

  /// No description provided for @firstVersionHint.
  ///
  /// In ko, this message translates to:
  /// **'가수나 편곡이 다르면 곡 화면에서 버전을 더 추가할 수 있어요. 키와 템포는 콘티에서 그날만 바꿀 수도 있어요.'**
  String get firstVersionHint;

  /// No description provided for @playedLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막에 쓴 버전'**
  String get playedLast;

  /// No description provided for @songHasNoVersion.
  ///
  /// In ko, this message translates to:
  /// **'이 곡에는 버전이 없어요. 곡 화면에서 버전을 추가해 주세요.'**
  String get songHasNoVersion;

  /// No description provided for @changeVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전: {changes}'**
  String changeVersion(String changes);

  /// No description provided for @sheets.
  ///
  /// In ko, this message translates to:
  /// **'악보'**
  String get sheets;

  /// No description provided for @uploadSheet.
  ///
  /// In ko, this message translates to:
  /// **'악보 올리기'**
  String get uploadSheet;

  /// No description provided for @uploadSheetHint.
  ///
  /// In ko, this message translates to:
  /// **'PDF나 사진을 고르면 악보 한 개로 저장돼요.'**
  String get uploadSheetHint;

  /// No description provided for @preparingSheet.
  ///
  /// In ko, this message translates to:
  /// **'악보 준비 중…'**
  String get preparingSheet;

  /// No description provided for @sheetPreparationTimeout.
  ///
  /// In ko, this message translates to:
  /// **'악보를 읽는 데 시간이 오래 걸려요. 파일을 기기에 저장한 뒤 다시 골라 주세요.'**
  String get sheetPreparationTimeout;

  /// No description provided for @sheetLabel.
  ///
  /// In ko, this message translates to:
  /// **'악보 이름 (예: 코드, 드럼)'**
  String get sheetLabel;

  /// No description provided for @uploading.
  ///
  /// In ko, this message translates to:
  /// **'올리는 중'**
  String get uploading;

  /// No description provided for @pages.
  ///
  /// In ko, this message translates to:
  /// **'{count}쪽'**
  String pages(int count);

  /// No description provided for @history.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get history;

  /// No description provided for @playedTimes.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}회'**
  String playedTimes(int count);

  /// No description provided for @neverPlayed.
  ///
  /// In ko, this message translates to:
  /// **'아직 안 했어요'**
  String get neverPlayed;

  /// No description provided for @lastPlayed.
  ///
  /// In ko, this message translates to:
  /// **'마지막 {ago}'**
  String lastPlayed(String ago);

  /// No description provided for @usualKey.
  ///
  /// In ko, this message translates to:
  /// **'주로 {key}'**
  String usualKey(String key);

  /// No description provided for @nextPlanned.
  ///
  /// In ko, this message translates to:
  /// **'다음 예정 {date}'**
  String nextPlanned(String date);

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String daysAgo(int n);

  /// No description provided for @weeksAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}주 전'**
  String weeksAgo(int n);

  /// No description provided for @monthsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}개월 전'**
  String monthsAgo(int n);

  /// No description provided for @yearsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}년 전'**
  String yearsAgo(int n);

  /// No description provided for @stats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get stats;

  /// No description provided for @topSongs.
  ///
  /// In ko, this message translates to:
  /// **'많이 한 곡'**
  String get topSongs;

  /// No description provided for @notPlayedSince.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 넘게 안 한 곡'**
  String notPlayedSince(int months);

  /// No description provided for @period3m.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get period3m;

  /// No description provided for @period6m.
  ///
  /// In ko, this message translates to:
  /// **'6개월'**
  String get period6m;

  /// No description provided for @period1y.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get period1y;

  /// No description provided for @periodAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get periodAll;

  /// No description provided for @timesShort.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String timesShort(int count);

  /// No description provided for @viewSheet.
  ///
  /// In ko, this message translates to:
  /// **'악보 보기'**
  String get viewSheet;

  /// No description provided for @viewSheets.
  ///
  /// In ko, this message translates to:
  /// **'악보 보기'**
  String get viewSheets;

  /// No description provided for @annotate.
  ///
  /// In ko, this message translates to:
  /// **'필기'**
  String get annotate;

  /// No description provided for @zoomIn.
  ///
  /// In ko, this message translates to:
  /// **'확대'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In ko, this message translates to:
  /// **'축소'**
  String get zoomOut;

  /// No description provided for @fitSheet.
  ///
  /// In ko, this message translates to:
  /// **'화면 맞춤'**
  String get fitSheet;

  /// No description provided for @sheetPage.
  ///
  /// In ko, this message translates to:
  /// **'악보 페이지'**
  String get sheetPage;

  /// No description provided for @doneAnnotating.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get doneAnnotating;

  /// No description provided for @pen.
  ///
  /// In ko, this message translates to:
  /// **'펜'**
  String get pen;

  /// No description provided for @highlighter.
  ///
  /// In ko, this message translates to:
  /// **'형광펜'**
  String get highlighter;

  /// No description provided for @eraser.
  ///
  /// In ko, this message translates to:
  /// **'지우개'**
  String get eraser;

  /// No description provided for @inkForMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 보기'**
  String get inkForMe;

  /// No description provided for @inkForTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 공용'**
  String get inkForTeam;

  /// No description provided for @showTeamInk.
  ///
  /// In ko, this message translates to:
  /// **'팀 필기 보이기'**
  String get showTeamInk;

  /// No description provided for @showMyInk.
  ///
  /// In ko, this message translates to:
  /// **'내 필기 보이기'**
  String get showMyInk;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get redo;

  /// No description provided for @stageMode.
  ///
  /// In ko, this message translates to:
  /// **'무대 모드'**
  String get stageMode;

  /// No description provided for @copyPreviousInk.
  ///
  /// In ko, this message translates to:
  /// **'지난 필기 가져오기'**
  String get copyPreviousInk;

  /// No description provided for @copiedInk.
  ///
  /// In ko, this message translates to:
  /// **'필기 {count}개를 가져왔어요'**
  String copiedInk(int count);

  /// No description provided for @noPreviousInk.
  ///
  /// In ko, this message translates to:
  /// **'같은 악보로 한 지난 예배에 내 필기가 없어요.'**
  String get noPreviousInk;

  /// No description provided for @noSheetForSong.
  ///
  /// In ko, this message translates to:
  /// **'이 곡에는 악보가 없어요'**
  String get noSheetForSong;

  /// No description provided for @pageOf.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String pageOf(int current, int total);

  /// No description provided for @inkColor.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get inkColor;

  /// No description provided for @unsavedInk.
  ///
  /// In ko, this message translates to:
  /// **'저장 대기 {count}'**
  String unsavedInk(int count);

  /// No description provided for @rotation.
  ///
  /// In ko, this message translates to:
  /// **'로테이션'**
  String get rotation;

  /// No description provided for @rotationList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get rotationList;

  /// No description provided for @rotationTable.
  ///
  /// In ko, this message translates to:
  /// **'표'**
  String get rotationTable;

  /// No description provided for @openPlaces.
  ///
  /// In ko, this message translates to:
  /// **'빈 자리 {count}'**
  String openPlaces(int count);

  /// No description provided for @myServing.
  ///
  /// In ko, this message translates to:
  /// **'내 섬김'**
  String get myServing;

  /// No description provided for @noServing.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 섬김이 없어요.'**
  String get noServing;

  /// No description provided for @accept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get decline;

  /// No description provided for @declineReason.
  ///
  /// In ko, this message translates to:
  /// **'못 하는 이유 (선택)'**
  String get declineReason;

  /// No description provided for @statusDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In ko, this message translates to:
  /// **'응답 대기'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get statusAccepted;

  /// No description provided for @statusDeclined.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get statusDeclined;

  /// No description provided for @autoAssign.
  ///
  /// In ko, this message translates to:
  /// **'자동 배정'**
  String get autoAssign;

  /// No description provided for @autoAssignDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}자리를 초안으로 채웠어요. 확인하고 고친 뒤 보내세요.'**
  String autoAssignDone(int count);

  /// No description provided for @sendDrafts.
  ///
  /// In ko, this message translates to:
  /// **'보내기 ({count})'**
  String sendDrafts(int count);

  /// No description provided for @sendDraftsConfirm.
  ///
  /// In ko, this message translates to:
  /// **'초안 {count}건을 보낼까요? 배정된 사람에게 알림이 가요.'**
  String sendDraftsConfirm(int count);

  /// No description provided for @sent.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 보냈어요'**
  String sent(int count);

  /// No description provided for @addPerson.
  ///
  /// In ko, this message translates to:
  /// **'사람 추가'**
  String get addPerson;

  /// No description provided for @replacePerson.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람으로 바꾸기'**
  String get replacePerson;

  /// No description provided for @removePerson.
  ///
  /// In ko, this message translates to:
  /// **'빼기'**
  String get removePerson;

  /// No description provided for @needed.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String needed(int count);

  /// No description provided for @setNeeded.
  ///
  /// In ko, this message translates to:
  /// **'필요 인원'**
  String get setNeeded;

  /// No description provided for @defaultNeeded.
  ///
  /// In ko, this message translates to:
  /// **'기본 필요 인원'**
  String get defaultNeeded;

  /// No description provided for @defaultNeededHint.
  ///
  /// In ko, this message translates to:
  /// **'새로 만드는 예배에 이 인원이 들어가요.'**
  String get defaultNeededHint;

  /// No description provided for @unavailableThatDay.
  ///
  /// In ko, this message translates to:
  /// **'그날 안 돼요'**
  String get unavailableThatDay;

  /// No description provided for @alreadyServing.
  ///
  /// In ko, this message translates to:
  /// **'이미 섬김'**
  String get alreadyServing;

  /// No description provided for @requestSwap.
  ///
  /// In ko, this message translates to:
  /// **'대타 요청'**
  String get requestSwap;

  /// No description provided for @swapMessage.
  ///
  /// In ko, this message translates to:
  /// **'남길 말 (선택)'**
  String get swapMessage;

  /// No description provided for @swapRequested.
  ///
  /// In ko, this message translates to:
  /// **'같은 파트 팀원들에게 대타를 요청했어요'**
  String get swapRequested;

  /// No description provided for @cancelSwap.
  ///
  /// In ko, this message translates to:
  /// **'대타 요청 취소'**
  String get cancelSwap;

  /// No description provided for @swapOpen.
  ///
  /// In ko, this message translates to:
  /// **'대타 구함'**
  String get swapOpen;

  /// No description provided for @takeSwap.
  ///
  /// In ko, this message translates to:
  /// **'대신 섬기기'**
  String get takeSwap;

  /// No description provided for @swapTaken.
  ///
  /// In ko, this message translates to:
  /// **'섬김을 넘겨받았어요'**
  String get swapTaken;

  /// No description provided for @blockouts.
  ///
  /// In ko, this message translates to:
  /// **'불가능 날짜'**
  String get blockouts;

  /// No description provided for @myBlockouts.
  ///
  /// In ko, this message translates to:
  /// **'내 불가능 날짜'**
  String get myBlockouts;

  /// No description provided for @teamBlockouts.
  ///
  /// In ko, this message translates to:
  /// **'팀원 불가능 날짜'**
  String get teamBlockouts;

  /// No description provided for @addBlockout.
  ///
  /// In ko, this message translates to:
  /// **'날짜 추가'**
  String get addBlockout;

  /// No description provided for @blockoutNote.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택, 리더만 봐요)'**
  String get blockoutNote;

  /// No description provided for @noBlockouts.
  ///
  /// In ko, this message translates to:
  /// **'등록된 날짜가 없어요.'**
  String get noBlockouts;

  /// No description provided for @servingPeople.
  ///
  /// In ko, this message translates to:
  /// **'섬기는 사람'**
  String get servingPeople;

  /// No description provided for @notifAssignmentRequested.
  ///
  /// In ko, this message translates to:
  /// **'{session} {part} 섬김 요청'**
  String notifAssignmentRequested(String session, String part);

  /// No description provided for @notifAssignmentDeclined.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {session} {part} 섬김을 거절했어요'**
  String notifAssignmentDeclined(String name, String session, String part);

  /// No description provided for @notifAssignmentRemoved.
  ///
  /// In ko, this message translates to:
  /// **'{session} {part} 섬김에서 빠졌어요'**
  String notifAssignmentRemoved(String session, String part);

  /// No description provided for @notifAssignmentNudge.
  ///
  /// In ko, this message translates to:
  /// **'{session} {part} 섬김 요청에 아직 답하지 않았어요'**
  String notifAssignmentNudge(String session, String part);

  /// No description provided for @notifSwapRequested.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {session} {part} 대타를 구해요'**
  String notifSwapRequested(String name, String session, String part);

  /// No description provided for @notifSwapFilled.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {session} {part}을(를) 맡았어요'**
  String notifSwapFilled(String name, String session, String part);

  /// No description provided for @notifServiceReminder.
  ///
  /// In ko, this message translates to:
  /// **'내일 {session} {part} 섬김이 있어요'**
  String notifServiceReminder(String session, String part);

  /// No description provided for @notifRehearsalScheduled.
  ///
  /// In ko, this message translates to:
  /// **'연습 일정: {when}'**
  String notifRehearsalScheduled(String when);

  /// No description provided for @notifRehearsalReminder.
  ///
  /// In ko, this message translates to:
  /// **'곧 연습이에요: {when}'**
  String notifRehearsalReminder(String when);

  /// No description provided for @rehearsals.
  ///
  /// In ko, this message translates to:
  /// **'연습'**
  String get rehearsals;

  /// No description provided for @addRehearsal.
  ///
  /// In ko, this message translates to:
  /// **'연습 추가'**
  String get addRehearsal;

  /// No description provided for @noRehearsals.
  ///
  /// In ko, this message translates to:
  /// **'잡힌 연습이 없어요.'**
  String get noRehearsals;

  /// No description provided for @rsvpGoing.
  ///
  /// In ko, this message translates to:
  /// **'참석'**
  String get rsvpGoing;

  /// No description provided for @rsvpLate.
  ///
  /// In ko, this message translates to:
  /// **'지각'**
  String get rsvpLate;

  /// No description provided for @rsvpNotGoing.
  ///
  /// In ko, this message translates to:
  /// **'불참'**
  String get rsvpNotGoing;

  /// No description provided for @attendanceCheck.
  ///
  /// In ko, this message translates to:
  /// **'출석 체크'**
  String get attendanceCheck;

  /// No description provided for @present.
  ///
  /// In ko, this message translates to:
  /// **'출석'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In ko, this message translates to:
  /// **'결석'**
  String get absent;

  /// No description provided for @calendarSubscribe.
  ///
  /// In ko, this message translates to:
  /// **'캘린더에 구독'**
  String get calendarSubscribe;

  /// No description provided for @calendarHint.
  ///
  /// In ko, this message translates to:
  /// **'내 섬김과 연습 일정이 캘린더에 자동으로 들어가요.'**
  String get calendarHint;

  /// No description provided for @openInCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 앱에서 열기'**
  String get openInCalendar;

  /// No description provided for @newCalendarUrl.
  ///
  /// In ko, this message translates to:
  /// **'주소 새로 만들기'**
  String get newCalendarUrl;

  /// No description provided for @newCalendarUrlHint.
  ///
  /// In ko, this message translates to:
  /// **'새로 만들면 예전 주소로는 더 이상 보이지 않아요.'**
  String get newCalendarUrlHint;

  /// No description provided for @googleCalendarHint.
  ///
  /// In ko, this message translates to:
  /// **'구글 캘린더는 웹에서 \'다른 캘린더 > URL로 추가\'에 붙여넣어요. 반영되기까지 몇 시간 걸릴 수 있어요.'**
  String get googleCalendarHint;

  /// No description provided for @navChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get navChat;

  /// No description provided for @announcements.
  ///
  /// In ko, this message translates to:
  /// **'공지'**
  String get announcements;

  /// No description provided for @newAnnouncement.
  ///
  /// In ko, this message translates to:
  /// **'공지 쓰기'**
  String get newAnnouncement;

  /// No description provided for @editAnnouncement.
  ///
  /// In ko, this message translates to:
  /// **'공지 수정'**
  String get editAnnouncement;

  /// No description provided for @deleteAnnouncement.
  ///
  /// In ko, this message translates to:
  /// **'공지 삭제'**
  String get deleteAnnouncement;

  /// No description provided for @announcementTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get announcementTitle;

  /// No description provided for @announcementBody.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get announcementBody;

  /// No description provided for @pinAnnouncement.
  ///
  /// In ko, this message translates to:
  /// **'맨 위에 고정'**
  String get pinAnnouncement;

  /// No description provided for @pinned.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get pinned;

  /// No description provided for @noAnnouncements.
  ///
  /// In ko, this message translates to:
  /// **'아직 공지가 없어요.'**
  String get noAnnouncements;

  /// No description provided for @newBadge.
  ///
  /// In ko, this message translates to:
  /// **'새 글'**
  String get newBadge;

  /// No description provided for @channels.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get channels;

  /// No description provided for @archivedChannel.
  ///
  /// In ko, this message translates to:
  /// **'지난 예배 (읽기만 가능)'**
  String get archivedChannel;

  /// No description provided for @newChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 만들기'**
  String get newChannel;

  /// No description provided for @channelName.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름'**
  String get channelName;

  /// No description provided for @channelPartsHint.
  ///
  /// In ko, this message translates to:
  /// **'이 파트를 맡은 사람들이 들어와요. 리더는 모든 채널을 봐요.'**
  String get channelPartsHint;

  /// No description provided for @noMessages.
  ///
  /// In ko, this message translates to:
  /// **'첫 메시지를 남겨보세요.'**
  String get noMessages;

  /// No description provided for @messageHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get send;

  /// No description provided for @mute.
  ///
  /// In ko, this message translates to:
  /// **'알림 끄기'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In ko, this message translates to:
  /// **'알림 켜기'**
  String get unmute;

  /// No description provided for @deleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 삭제'**
  String get deleteMessage;

  /// No description provided for @deletedMessage.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 메시지예요'**
  String get deletedMessage;

  /// No description provided for @newPoll.
  ///
  /// In ko, this message translates to:
  /// **'투표 만들기'**
  String get newPoll;

  /// No description provided for @pollQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get pollQuestion;

  /// No description provided for @pollOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지 {n}'**
  String pollOption(int n);

  /// No description provided for @addOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get addOption;

  /// No description provided for @multipleChoice.
  ///
  /// In ko, this message translates to:
  /// **'여러 개 고를 수 있게'**
  String get multipleChoice;

  /// No description provided for @anonymousPoll.
  ///
  /// In ko, this message translates to:
  /// **'익명 투표'**
  String get anonymousPoll;

  /// No description provided for @vote.
  ///
  /// In ko, this message translates to:
  /// **'투표하기'**
  String get vote;

  /// No description provided for @votes.
  ///
  /// In ko, this message translates to:
  /// **'{count}표'**
  String votes(int count);

  /// No description provided for @pollClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감된 투표'**
  String get pollClosed;

  /// No description provided for @anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymous;

  /// No description provided for @notifChatTitle.
  ///
  /// In ko, this message translates to:
  /// **'{channel}'**
  String notifChatTitle(String channel);

  /// No description provided for @notifAnnouncementTitle.
  ///
  /// In ko, this message translates to:
  /// **'공지: {title}'**
  String notifAnnouncementTitle(String title);

  /// No description provided for @pollPreview.
  ///
  /// In ko, this message translates to:
  /// **'투표: {question}'**
  String pollPreview(String question);

  /// No description provided for @liveStart.
  ///
  /// In ko, this message translates to:
  /// **'라이브하기'**
  String get liveStart;

  /// No description provided for @liveNeedsConnection.
  ///
  /// In ko, this message translates to:
  /// **'라이브를 시작하려면 인터넷에 연결해 주세요.'**
  String get liveNeedsConnection;

  /// No description provided for @liveLeave.
  ///
  /// In ko, this message translates to:
  /// **'라이브 나가기'**
  String get liveLeave;

  /// No description provided for @liveWatching.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 함께'**
  String liveWatching(int count);

  /// No description provided for @liveFollow.
  ///
  /// In ko, this message translates to:
  /// **'따라가기'**
  String get liveFollow;

  /// No description provided for @liveFollowHint.
  ///
  /// In ko, this message translates to:
  /// **'끄면 다른 사람이 넘겨도 내 화면은 그대로예요.'**
  String get liveFollowHint;

  /// No description provided for @sendCue.
  ///
  /// In ko, this message translates to:
  /// **'큐 보내기'**
  String get sendCue;

  /// No description provided for @cueAgain.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더'**
  String get cueAgain;

  /// No description provided for @cueChorus.
  ///
  /// In ko, this message translates to:
  /// **'후렴으로'**
  String get cueChorus;

  /// No description provided for @cueBridge.
  ///
  /// In ko, this message translates to:
  /// **'브릿지로'**
  String get cueBridge;

  /// No description provided for @cueEnding.
  ///
  /// In ko, this message translates to:
  /// **'엔딩'**
  String get cueEnding;

  /// No description provided for @cueKeyUp.
  ///
  /// In ko, this message translates to:
  /// **'키 업'**
  String get cueKeyUp;

  /// No description provided for @cueSofter.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get cueSofter;

  /// No description provided for @cueFaster.
  ///
  /// In ko, this message translates to:
  /// **'빠르게'**
  String get cueFaster;

  /// No description provided for @cueSlower.
  ///
  /// In ko, this message translates to:
  /// **'천천히'**
  String get cueSlower;

  /// No description provided for @cueNextSong.
  ///
  /// In ko, this message translates to:
  /// **'다음 곡'**
  String get cueNextSong;

  /// No description provided for @cueCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get cueCustom;

  /// No description provided for @cueTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 사람'**
  String get cueTo;

  /// No description provided for @cueEveryone.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get cueEveryone;

  /// No description provided for @notificationsSection.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationsSection;

  /// No description provided for @allSetlists.
  ///
  /// In ko, this message translates to:
  /// **'모든 예배 콘티 받기'**
  String get allSetlists;

  /// No description provided for @allSetlistsHint.
  ///
  /// In ko, this message translates to:
  /// **'섬기지 않는 예배의 콘티 공지도 알려 줘요.'**
  String get allSetlistsHint;

  /// No description provided for @pushSection.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get pushSection;

  /// No description provided for @pushSetlists.
  ///
  /// In ko, this message translates to:
  /// **'콘티 공지'**
  String get pushSetlists;

  /// No description provided for @pushServing.
  ///
  /// In ko, this message translates to:
  /// **'섬김 요청과 대타'**
  String get pushServing;

  /// No description provided for @pushRehearsals.
  ///
  /// In ko, this message translates to:
  /// **'연습'**
  String get pushRehearsals;

  /// No description provided for @pushAnnouncements.
  ///
  /// In ko, this message translates to:
  /// **'공지'**
  String get pushAnnouncements;

  /// No description provided for @pushChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get pushChat;

  /// No description provided for @pushJoining.
  ///
  /// In ko, this message translates to:
  /// **'팀 가입'**
  String get pushJoining;

  /// No description provided for @pushOffHint.
  ///
  /// In ko, this message translates to:
  /// **'꺼도 알림 목록과 채팅의 안 읽은 표시는 그대로예요.'**
  String get pushOffHint;

  /// No description provided for @offline.
  ///
  /// In ko, this message translates to:
  /// **'오프라인'**
  String get offline;

  /// No description provided for @offlineShowingSaved.
  ///
  /// In ko, this message translates to:
  /// **'오프라인이에요. 이 기기에 저장해 둔 내용을 보여 줘요.'**
  String get offlineShowingSaved;

  /// No description provided for @offlineNotesWaiting.
  ///
  /// In ko, this message translates to:
  /// **'필기 {count}개는 연결되면 올라가요.'**
  String offlineNotesWaiting(int count);

  /// No description provided for @notesWaiting.
  ///
  /// In ko, this message translates to:
  /// **'필기 {count}개 대기'**
  String notesWaiting(int count);

  /// No description provided for @unsentNotesSignOut.
  ///
  /// In ko, this message translates to:
  /// **'아직 올라가지 않은 필기가 {count}개 있어요. 로그아웃하면 이 필기는 사라져요.'**
  String unsentNotesSignOut(int count);

  /// No description provided for @open.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get open;

  /// No description provided for @pushThisDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 푸시 받기'**
  String get pushThisDevice;

  /// No description provided for @pushBlocked.
  ///
  /// In ko, this message translates to:
  /// **'기기나 브라우저 설정에서 이 앱의 알림이 꺼져 있어요.'**
  String get pushBlocked;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @nextService.
  ///
  /// In ko, this message translates to:
  /// **'다음 예배'**
  String get nextService;

  /// No description provided for @tomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 후'**
  String inDays(int count);

  /// No description provided for @setlistComing.
  ///
  /// In ko, this message translates to:
  /// **'콘티 준비 중'**
  String get setlistComing;

  /// No description provided for @moreSongs.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}곡'**
  String moreSongs(int count);

  /// No description provided for @partChatsToJoin.
  ///
  /// In ko, this message translates to:
  /// **'이 파트가 들어갈 채팅방'**
  String get partChatsToJoin;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @todo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get todo;

  /// No description provided for @nothingToDo.
  ///
  /// In ko, this message translates to:
  /// **'할 일이 없어요.'**
  String get nothingToDo;

  /// No description provided for @rehearsalRsvpTodo.
  ///
  /// In ko, this message translates to:
  /// **'{title} 연습에 오나요?'**
  String rehearsalRsvpTodo(String title);

  /// No description provided for @teamRehearsal.
  ///
  /// In ko, this message translates to:
  /// **'팀 연습'**
  String get teamRehearsal;

  /// No description provided for @newAnnouncementTodo.
  ///
  /// In ko, this message translates to:
  /// **'새 공지가 있어요'**
  String get newAnnouncementTodo;

  /// No description provided for @joinRequestsCount.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청 {count}명'**
  String joinRequestsCount(int count);

  /// No description provided for @readiness.
  ///
  /// In ko, this message translates to:
  /// **'준비 현황'**
  String get readiness;

  /// No description provided for @setlistPublishedCount.
  ///
  /// In ko, this message translates to:
  /// **'콘티 공지됨 {count}곡'**
  String setlistPublishedCount(int count);

  /// No description provided for @setlistDraftCount.
  ///
  /// In ko, this message translates to:
  /// **'콘티 초안 {count}곡'**
  String setlistDraftCount(int count);

  /// No description provided for @setlistNone.
  ///
  /// In ko, this message translates to:
  /// **'콘티 없음'**
  String get setlistNone;

  /// No description provided for @placesFilled.
  ///
  /// In ko, this message translates to:
  /// **'수락 {accepted}/{needed}'**
  String placesFilled(int accepted, int needed);

  /// No description provided for @placesUnset.
  ///
  /// In ko, this message translates to:
  /// **'필요 인원 미정'**
  String get placesUnset;

  /// No description provided for @waitingCount.
  ///
  /// In ko, this message translates to:
  /// **'응답 대기 {count}'**
  String waitingCount(int count);

  /// No description provided for @declinedCount.
  ///
  /// In ko, this message translates to:
  /// **'거절 {count}'**
  String declinedCount(int count);

  /// No description provided for @unsentCount.
  ///
  /// In ko, this message translates to:
  /// **'보내지 않음 {count}'**
  String unsentCount(int count);

  /// No description provided for @rehearsalComing.
  ///
  /// In ko, this message translates to:
  /// **'연습 참석 {count}/{total}'**
  String rehearsalComing(int count, int total);

  /// No description provided for @noAnswerCount.
  ///
  /// In ko, this message translates to:
  /// **'미응답 {count}'**
  String noAnswerCount(int count);

  /// No description provided for @noRehearsal.
  ///
  /// In ko, this message translates to:
  /// **'연습 없음'**
  String get noRehearsal;

  /// No description provided for @mySchedule.
  ///
  /// In ko, this message translates to:
  /// **'내 일정'**
  String get mySchedule;

  /// No description provided for @noScheduleSoon.
  ///
  /// In ko, this message translates to:
  /// **'앞으로 4주 동안 잡힌 일정이 없어요.'**
  String get noScheduleSoon;

  /// No description provided for @teamNews.
  ///
  /// In ko, this message translates to:
  /// **'팀 소식'**
  String get teamNews;

  /// No description provided for @noNews.
  ///
  /// In ko, this message translates to:
  /// **'새 소식이 없어요.'**
  String get noNews;

  /// No description provided for @servingLoad.
  ///
  /// In ko, this message translates to:
  /// **'섬김 분배'**
  String get servingLoad;

  /// No description provided for @servingLoadHint.
  ///
  /// In ko, this message translates to:
  /// **'최근 8주 동안 섬긴 횟수예요. 한 사람에게 몰리지 않는지 봐 주세요.'**
  String get servingLoadHint;

  /// No description provided for @songNotes.
  ///
  /// In ko, this message translates to:
  /// **'곡 참고'**
  String get songNotes;

  /// No description provided for @mostPlayedRecently.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월 많이 한 곡'**
  String get mostPlayedRecently;

  /// No description provided for @notPlayedLately.
  ///
  /// In ko, this message translates to:
  /// **'오래 안 한 곡'**
  String get notPlayedLately;

  /// No description provided for @rehearsalAt.
  ///
  /// In ko, this message translates to:
  /// **'연습 {when}'**
  String rehearsalAt(String when);

  /// No description provided for @moreCues.
  ///
  /// In ko, this message translates to:
  /// **'큐 더보기'**
  String get moreCues;

  /// No description provided for @hideCues.
  ///
  /// In ko, this message translates to:
  /// **'큐 숨기기'**
  String get hideCues;

  /// No description provided for @showCues.
  ///
  /// In ko, this message translates to:
  /// **'큐 보이기'**
  String get showCues;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ko, this message translates to:
  /// **'계정과 프로필, 채팅 메시지, 필기, 편성 및 개인 설정이 영구 삭제돼요. 다른 팀원들과 공유한 곡·악보·예배 기록은 팀에 남아요. 기기에만 저장된 필기도 삭제돼요.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountUnderstand.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 계정과 개인 데이터는 복구할 수 없다는 점을 이해했어요.'**
  String get deleteAccountUnderstand;

  /// No description provided for @accountNeedsOwner.
  ///
  /// In ko, this message translates to:
  /// **'아래 팀의 유일한 관리자예요. 팀 화면에서 다른 팀원에게 관리자 권한을 넘긴 뒤 계정을 삭제해 주세요.'**
  String get accountNeedsOwner;

  /// No description provided for @deleteSoloTeams.
  ///
  /// In ko, this message translates to:
  /// **'혼자 남아 있는 팀({teams})과 그 팀의 모든 곡·악보·일정도 삭제돼요.'**
  String deleteSoloTeams(String teams);

  /// No description provided for @inTeamTimezone.
  ///
  /// In ko, this message translates to:
  /// **'팀 시간대: {timezone}'**
  String inTeamTimezone(String timezone);

  /// No description provided for @demoBanner.
  ///
  /// In ko, this message translates to:
  /// **'데모 · 이 기기에만 저장돼요'**
  String get demoBanner;

  /// No description provided for @demoReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get demoReset;

  /// No description provided for @demoStart.
  ///
  /// In ko, this message translates to:
  /// **'데모 시작하기'**
  String get demoStart;

  /// No description provided for @demoLiveHint.
  ///
  /// In ko, this message translates to:
  /// **'데모에서는 이 기기에서 라이브 화면을 미리 볼 수 있어요.'**
  String get demoLiveHint;

  /// No description provided for @demoVideo.
  ///
  /// In ko, this message translates to:
  /// **'3분 소개 영상'**
  String get demoVideo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
