# PraiseTeam

찬양팀의 예배 일정, 콘티, 곡·악보, 담당자 편성, 채팅을 함께 관리하는 Flutter 앱.
웹과 Android를 지원하며, iOS 배포 설정은 아직 준비 중입니다.

## 구성

- `app/`: Flutter, Riverpod, GoRouter. 한국어·영어를 지원합니다.
- `supabase/migrations/`: PostgreSQL 스키마, RLS 권한, 업무 RPC, 예약 작업.
- `supabase/functions/`: FCM 푸시, 개인 iCalendar 구독, 삭제된 팀의 파일 정리.
- `supabase/tests/database/`: pgTAP 권한·업무 규칙 테스트.
- `e2e/`: 로컬 Supabase와 Chrome을 사용하는 브라우저 시나리오.
- `scripts/deploy.sh`, `docs/DEPLOY.md`: 운영 배포와 백업 절차.

곡은 여러 버전을 갖고, 악보와 링크는 버전에 속합니다. 콘티에는 그날 사용할
버전·키·템포를 저장합니다. 팀 권한과 여러 행이 바뀌는 작업은 DB에서 검증합니다.
날짜 표시와 입력·주간 반복·편성은 모두 팀의 IANA 시간대를 사용하며, 서버에는 UTC로 저장합니다.

## 로컬 실행

Flutter **3.47.9** / Dart **3.13.7**, Supabase CLI **2.98.2**, Docker가 필요합니다.
아래 파일 복사는 새 체크아웃에서 한 번만 합니다. 기존 환경 파일은 덮어쓰지 않습니다.

```sh
cp .env.example .env
supabase start
cp app/env/example.json app/env/local.json
```

`app/env/local.json`의 `SUPABASE_PUBLISHABLE_KEY`에 로컬 프로젝트의 공개 키를 넣습니다.
로컬 개발용 로그인은 `DEV_LOGIN=true`일 때만 표시됩니다. 환경 파일은 Git에서 제외됩니다.

```sh
cd app
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port 3000 --dart-define-from-file=env/local.json
```

모델·Provider를 변경했을 때:

```sh
cd app
flutter gen-l10n
dart run build_runner build
```

## 검증

```sh
(cd app && flutter analyze --no-pub && flutter test --no-pub)
supabase test db --local
deno task check
deno task test
```

Edge Function 검증에는 Deno **2.5.6**을 사용합니다. GitHub Actions는 push와 PR마다
앱 분석·테스트·웹 빌드, 빈 DB에서 전체 마이그레이션과 pgTAP, Edge Function 타입·테스트를 실행합니다.
CI는 로컬 테스트 설정만 사용하며 운영 비밀 값이나 배포 권한이 필요하지 않습니다.

브라우저 테스트는 [e2e/README.md](e2e/README.md)를 참고하세요. 일부 기존 흐름은
빈 DB를 가정하므로, 보존할 데이터가 있는 개발 DB에서는 초기화하지 않습니다.

## 계정 삭제

설정, 팀 가입 전 화면, 승인 대기 화면에서 계정을 삭제할 수 있습니다. 다른 팀원이 있는
팀의 마지막 관리자는 먼저 다른 관리자에게 권한을 넘겨야 합니다. 혼자 남은 팀은 함께 삭제됩니다.
공유된 곡·악보·예배 기록은 남아 있는 팀에 보존되고, 개인 데이터와 Auth 세션은 삭제됩니다.

팀이 사라질 때 PDF 삭제 요청을 DB에 먼저 기록합니다. `storage-cleanup` 함수가
Storage API로 파일을 지우며, 실패한 요청은 5분 간격으로 다시 시도합니다.
이 함수는 DB의 웹훅 비밀 값으로 인증하고, 클라이언트는 삭제할 파일 경로를 지정할 수 없습니다.

운영 반영 순서와 서명 키 관리는 [docs/DEPLOY.md](docs/DEPLOY.md)를 따릅니다.
