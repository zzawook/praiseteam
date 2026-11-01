-- Local development only (runs on `supabase db reset`).
-- The hosted project sets these Vault secrets once, by hand.
select vault.create_secret(
  'http://supabase_kong_praiseteam:8000/functions/v1/push',
  'push_function_url',
  'Local push function URL (reachable from the db container)'
);
select vault.create_secret(
  'local-dev-push-secret',
  'push_webhook_secret',
  'Must equal PUSH_WEBHOOK_SECRET in supabase/functions/.env'
);
