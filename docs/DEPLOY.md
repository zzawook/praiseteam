# 배포 안내

| 무엇 | 어디 |
|---|---|
| 웹 앱 | https://praiseteam-sg.web.app (Firebase Hosting, 프로젝트 `praiseteam-sg`) |
| 앱 소개와 개인정보처리방침 | `/about.html`, `/privacy.html` (웹 앱과 같은 주소) |
| 백엔드 | Supabase 프로젝트 `kkolulligxondlpjkzzn` (싱가포르) |
| 안드로이드 | 릴리스 키로 서명한 APK |

배포 명령은 `scripts/deploy.sh` 하나로 모았어요. 저장소 루트에서 실행해요. 비밀 값은 모두 `.secrets/`에 있고(git 제외), 스크립트는 그 값을 화면에 출력하지 않아요.

## 처음 한 번

### 1. 데이터베이스
```sh
scripts/deploy.sh db
```
적용될 마이그레이션 목록을 먼저 보여 주고, `y`를 눌러야 적용해요. 적용하기 직전에 운영 데이터베이스의 구조와 데이터를 `.secrets/backups/`에 덤프해 둬요(git 제외). 마이그레이션이 데이터를 옮기다 잘못되면 이 파일로 되돌려요.

### 2. Edge Functions와 비밀 값
```sh
scripts/deploy.sh functions
```
이 명령이 하는 일이에요.
- `push`, `calendar`, `storage-cleanup` 함수를 배포해요.
- 함수 비밀 값(`PUSH_WEBHOOK_SECRET`, `WEB_APP_URL`)을 넣어요.
- 데이터베이스 Vault에 푸시 함수 주소와 같은 비밀 값을 넣어요.
- 계정 삭제 후 파일을 정리할 `storage_cleanup_url`도 Vault에 넣어요. 파일 삭제가 실패하면 5분 간격으로 다시 시도해요.

`supabase db query --linked`가 로그인을 요구하면 `supabase login`을 한 뒤 다시 실행해요.

### 3. 웹 배포
```sh
scripts/deploy.sh web
```
개인정보처리방침의 연락처는 kjaehyeok21@gmail.com이에요(`app/web/privacy.html`).

### 4. 푸시 켜기 (Firebase 콘솔)
1. Firebase 콘솔 → 프로젝트 설정 → 서비스 계정 → **새 비공개 키 생성**.
2. 받은 파일을 `.secrets/fcm-service-account.json`으로 옮기고, 다운로드 폴더의 원본은 지워요.
3. 아래를 실행해요.
```sh
scripts/deploy.sh fcm .secrets/fcm-service-account.json
```
키를 넣기 전에도 앱 안 알림은 동작해요. 푸시만 '건너뜀'으로 기록돼요.

### 5. 안드로이드 구글 로그인 (Google Cloud 콘솔)
릴리스 키로 서명한 앱은 디버그 키와 지문이 달라서, OAuth 클라이언트가 하나 더 필요해요.
1. Google Cloud 콘솔 → API 및 서비스 → 사용자 인증 정보 → **사용자 인증 정보 만들기 → OAuth 클라이언트 ID**를 눌러요.
2. 유형은 **Android**로 해요.
3. 패키지 이름은 `com.kjaehyeok.praiseteam`이에요.
4. SHA-1은 `73:D4:DF:BD:E7:CC:5E:C6:4F:FD:E0:83:FA:35:AA:BF:F0:C2:69:34`이에요. 공개해도 되는 값이에요.

### 6. 안드로이드 앱 빌드와 공유
```sh
scripts/deploy.sh android
```
`app/build/app/outputs/flutter-apk/app-release.apk`를 팀원에게 보내요. Firebase App Distribution을 쓰려면 아래처럼 해요.
```sh
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app 1:677984922607:android:b9ce2546084e0fb5cd241a --testers "팀원1@gmail.com,팀원2@gmail.com"
```

### 7. OAuth 동의 화면 게시 (Google Cloud 콘솔)
'테스트' 상태에서는 테스트 사용자로 등록한 구글 계정(최대 100명)만 로그인할 수 있어요. 팀원을 하나씩 등록하기 싫으면 게시해요.
- 앱 홈페이지는 `https://praiseteam-sg.web.app/about.html`, 개인정보처리방침은 `https://praiseteam-sg.web.app/privacy.html`로 넣어요.
- 승인된 도메인에는 `praiseteam-sg.web.app`과 `kkolulligxondlpjkzzn.supabase.co`를 넣어요.
- 기본 범위(이메일, 프로필)만 쓰고 로고를 올리지 않으면, 구글 검토 없이 바로 게시돼요.

### 8. 구글 클라이언트 보안 비밀 교체
웹 OAuth 클라이언트의 보안 비밀이 대화에 한 번 노출됐어요. 팀이 쓰기 전에 바꿔요.
1. 콘솔의 웹 클라이언트에서 새 보안 비밀을 추가해요.
2. `.secrets/google-oauth.env`의 `GOOGLE_WEB_CLIENT_SECRET`을 새 값으로 바꿔요.
3. `echo n | supabase config push`로 바뀔 내용을 먼저 확인한 뒤 `supabase config push`를 실행해요.
4. 이전 보안 비밀을 사용 중지하고 삭제해요.

## 업데이트할 때
| 바뀐 것 | 명령 |
|---|---|
| `supabase/migrations/` | `scripts/deploy.sh db` |
| `supabase/functions/` | `scripts/deploy.sh functions` |
| 앱 | `app/pubspec.yaml`의 `version`을 올리고 `scripts/deploy.sh web`, `scripts/deploy.sh android` |

## 꼭 백업할 것
`.secrets/` 폴더 전체를 비밀번호 관리자나 암호화된 저장소에 따로 보관해요. 특히 아래 두 파일이 중요해요.
- `praiseteam-release.jks`
- `android-key.properties`

이 키를 잃어버리면 이미 설치된 앱을 같은 앱으로 업데이트할 수 없어요.

## 아직 안 한 것
- **iOS:** Apple 개발자 계정, Mac(또는 Codemagic), APNs 키 등록, Sign in with Apple이 필요해요.

## 계정 삭제 기능 업데이트
계정 삭제 기능이 포함된 앱을 배포하기 전에 `scripts/deploy.sh db`와
`scripts/deploy.sh functions`를 먼저 실행해요. 설정, 가입 전 화면, 승인 대기 화면에서
삭제할 수 있어요. 다른 팀원이 있는 팀의 마지막 관리자는 권한을 넘겨야 하고,
혼자 남은 팀은 함께 삭제돼요. 남아 있는 팀의 곡·악보·예배 기록은 유지돼요.
