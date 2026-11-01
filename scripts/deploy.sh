#!/usr/bin/env bash
# Production deploys, one step at a time (see docs/DEPLOY.md):
#
#   scripts/deploy.sh db                     schema migrations (dry run first, then asks)
#   scripts/deploy.sh functions              Edge Functions, their secrets, Vault secrets for push
#   scripts/deploy.sh fcm <key.json>         turn on push delivery with a Firebase service account
#   scripts/deploy.sh web                    build the web app and publish it on Firebase Hosting
#   scripts/deploy.sh android                build the signed release APK
#
# Secrets stay in .secrets/ (git-ignored) and are never printed.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT_REF=kkolulligxondlpjkzzn
FIREBASE_PROJECT=praiseteam-sg
WEB_APP_URL=https://praiseteam-sg.web.app
SECRETS=.secrets

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [[ $answer == [yY] ]]
}

db() {
  SUPABASE_DB_PASSWORD="$(cat "$SECRETS/supabase-db-password")"
  export SUPABASE_DB_PASSWORD
  supabase db push --linked --dry-run
  confirm "Apply these migrations to production?" || exit 1
  # A migration can move data, so production is dumped first; restoring
  # from these files is the way back.
  local backup
  backup="$SECRETS/backups/$(date -u +%Y%m%dT%H%M%SZ)"
  (umask 077 && mkdir -p "$SECRETS/backups")
  supabase db dump --linked -f "$backup-schema.sql"
  supabase db dump --linked --data-only --use-copy -f "$backup-data.sql"
  supabase db push --linked
}

# Creates or updates one Vault secret. Values here are URL-safe (no quotes).
vault_sql() {
  cat <<SQL
do \$\$ begin
  if exists (select 1 from vault.secrets where name = '$1') then
    perform vault.update_secret((select id from vault.secrets where name = '$1'), '$2');
  else
    perform vault.create_secret('$2', '$1');
  end if;
end \$\$;
SQL
}

functions() {
  # The database calls the push function with a shared secret, so nobody
  # else can make it send. Made once and kept in .secrets/.
  local secret_file="$SECRETS/push-webhook-secret"
  if [[ ! -s $secret_file ]]; then
    (umask 077 && openssl rand -base64 32 | tr '+/' '-_' | tr -d '=\n' >"$secret_file")
  fi
  local secret
  secret="$(cat "$secret_file")"

  supabase secrets set --project-ref "$PROJECT_REF" PUSH_WEBHOOK_SECRET="$secret" WEB_APP_URL="$WEB_APP_URL" >/dev/null
  supabase functions deploy push calendar --project-ref "$PROJECT_REF"
  supabase db query --linked "$(vault_sql push_function_url "https://$PROJECT_REF.supabase.co/functions/v1/push")
$(vault_sql push_webhook_secret "$secret")" >/dev/null
  echo "Functions deployed; Vault secrets push_function_url and push_webhook_secret are set."
}

fcm() {
  local key="${1:?usage: scripts/deploy.sh fcm <service-account.json>}"
  local compact
  compact="$(python3 -c 'import json, sys; print(json.dumps(json.load(open(sys.argv[1]))))' "$key")"
  supabase secrets set --project-ref "$PROJECT_REF" FCM_SERVICE_ACCOUNT="$compact" >/dev/null
  echo "Push delivery is on. Keep the key only in $SECRETS/ and delete other copies."
}

web() {
  if grep -q CONTACT_EMAIL app/web/privacy.html; then
    echo "Put the contact address into app/web/privacy.html (CONTACT_EMAIL, twice) first." >&2
    exit 1
  fi
  (cd app && flutter build web --release --dart-define-from-file=env/prod.json)
  firebase deploy --only hosting --project "$FIREBASE_PROJECT"
}

android() {
  if [[ ! -f app/android/key.properties ]]; then
    echo "app/android/key.properties (the release signing key) is missing; see docs/DEPLOY.md." >&2
    exit 1
  fi
  (cd app && flutter build apk --release --dart-define-from-file=env/prod.json)
  echo "app/build/app/outputs/flutter-apk/app-release.apk"
}

case "${1:-}" in
  db | functions | web | android) "$1" ;;
  fcm) fcm "${2:-}" ;;
  *)
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
