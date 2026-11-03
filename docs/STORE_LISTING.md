# Store listing draft — PraiseTeam 0.3.0

Copy these fields into the consoles after the developer accounts are ready.
These are drafts, not an assertion that either store has approved the app.

## Shared details

- Name: **PraiseTeam**
- Android package / Apple bundle: `com.kjaehyeok.praiseteam`
- Category: Productivity
- Price: Free; no ads, purchases or subscriptions in this build.
- Support email: `kjaehyeok21@gmail.com`
- Website: `https://praiseteam-sg.web.app/about.html`
- Support URL: `https://praiseteam-sg.web.app/support.html`
- Privacy URL: `https://praiseteam-sg.web.app/privacy.html`
- Account deletion URL: `https://praiseteam-sg.web.app/delete-account.html`

## Korean

Play short description / App Store subtitle:

> 찬양팀의 콘티, 악보, 로테이션을 한곳에

Full description:

찬양팀의 한 주를 프레이즈 팀에서 함께 준비해 보세요.
흩어진 콘티와 악보, 섬김 일정, 팀 대화를 한곳에서 정리합니다.

예배 준비
예배를 만들고 곡과 편곡 버전을 골라 콘티를 구성하세요. 순서, 키, 템포,
송폼과 메모를 정리하고, 바뀐 내용을 팀원에게 공지할 수 있습니다.

팀의 곡 라이브러리
같은 곡에 여러 편곡 버전을 두고 악보와 참고 영상 링크를 모으세요.
PDF와 악보 이미지를 올리고, 곡을 사용한 예배와 자주 쓴 키를 확인하세요.

로테이션과 연습
예배별 담당자를 편성하고 응답을 확인하세요. 자동 편성으로 초안을 만들고,
불가능한 날짜 등록, 섬김 요청 수락·거절, 대타 요청과 연습 참석 응답을
함께 관리할 수 있습니다.

현장에서 라이브하기
예배에서 라이브하기를 누르면 악보가 열리고 같은 예배의 팀원과 연결됩니다.
페이지를 함께 넘기고 ‘한 번 더’, ‘후렴으로’ 같은 큐를 전하세요.
필요할 때는 따라가기를 끄고 내 페이지를 볼 수 있습니다.

악보 위의 필기
나만 볼 필기와 팀에 공유할 필기를 나누어 남기세요. 미리 저장된 악보는
인터넷이 끊겨도 열리며, 오프라인에서 남긴 필기는 연결이 돌아오면 전송됩니다.

준비의 흐름 안에서 대화
전체, 파트별, 예배별 대화를 나누고 공지와 투표로 의견을 모으세요.
홈에서는 다가오는 예배, 연습, 아직 답하지 않은 요청을 확인할 수 있습니다.

계정으로 로그인한 뒤 팀을 만들거나 초대 코드로 참여하세요.
실시간 동기화, 새 대화와 알림에는 인터넷 연결이 필요합니다.

App Store keywords:

> 찬양,찬양팀,교회,예배,콘티,악보,로테이션,송폼,워십,연습

Release notes:

> 찬양팀의 예배 콘티, 곡과 악보, 로테이션, 라이브 페이지 동기화,
> 필기와 팀 대화를 함께 준비할 수 있습니다.

## English

Play short description:

> Setlists, sheet music, schedules and live coordination for worship teams.

App Store subtitle:

> Prepare worship together

Full description:

Prepare your worship team's week together with PraiseTeam.
Bring setlists, sheet music, serving schedules and team conversations into one place.

Plan services: choose songs and arrangements, organize keys, tempos, song forms
and notes, then publish changes to your team.

Build your song library: keep multiple arrangements of a song with PDFs, sheet
images and reference video links. Review past services and commonly used keys.

Coordinate your rota: create assignment drafts, collect availability, respond
to serving requests, request substitutes and track rehearsal replies.

Go live: open a service's music stand and follow page turns with connected
teammates. Send cues such as “one more time” or “to the chorus”, or turn off
following when you need to read independently.

Annotate your sheets: keep private notes or share them with your team. Previously
saved sheets open offline, and notes made offline upload when the connection returns.

Keep conversations together: use team, part and service chats, announcements and
polls. Home shows upcoming services, rehearsals and requests awaiting your reply.

Sign in to create a team or join with an invitation code. Live synchronization,
new messages and push notifications require internet access.

App Store keywords:

> worship,church,setlist,sheet music,rota,rehearsal,team,music stand,annotations

## Review access and declarations to finish in the consoles

- Arrange a real reviewer-accessible sign-in account and a fictional sample team.
  Store those credentials in the console's private review notes, not Git. The
  development email-login switch is disabled in store builds and must stay off.
- Explain how to join the sample team and where to find a prepared service,
  song, rota, chat and sheet. Google/Apple OAuth and notification delivery still
  need signed-device verification; sample-mode CI does not cover them.
- Complete the current age-rating/content and data-safety questionnaires from
  the final app. Data includes name, email, user/device identifiers, messages,
  uploaded files, schedules/notes and read markers, for account and app functions.
  No advertising, analytics SDK or cross-app tracking is included.
- Review the team-content moderation and contact workflow against each store's
  user-generated-content rules before public submission; approval is not implied
  by passing technical tests.
- Google Play App Signing's production certificate must be registered with the
  Android OAuth client after Play generates it.

## Visual assets

`scripts/store_assets.py` exports the existing app icons and a code-authored
1024×500 feature graphic. Native screenshots are actual app captures with
fictional test data. Keep iPhone and Android captures in their respective slots.
Never use the Simulator ZIP as an installable iPhone/TestFlight artifact.

Specifications checked on 3 November 2026:
[Google Play assets](https://support.google.com/googleplay/android-developer/answer/9866151)
and [Apple screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).
