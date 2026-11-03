set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.claim_apple_revocations(p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.claim_apple_revocations(p_limit);$function$
;

CREATE OR REPLACE FUNCTION public.finish_apple_revocation(p_id bigint, p_success boolean, p_status integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.finish_apple_revocation(p_id, p_success, p_status);$function$
;

CREATE OR REPLACE FUNCTION public.store_apple_token(p_user_id uuid, p_session_id uuid, p_client_id text, p_token_hash text, p_ciphertext text)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  select private.store_apple_token(p_user_id, p_session_id, p_client_id, p_token_hash, p_ciphertext);
$function$
;


  create table "private"."apple_identity_tokens" (
    "user_id" uuid not null,
    "client_id" text not null,
    "token_hash" text not null,
    "token_ciphertext" text not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "private"."apple_identity_tokens" enable row level security;


  create table "private"."apple_revocation_queue" (
    "id" bigint generated always as identity not null,
    "user_id" uuid not null,
    "client_id" text not null,
    "token_hash" text not null,
    "token_ciphertext" text not null,
    "created_at" timestamp with time zone not null default now(),
    "next_attempt_at" timestamp with time zone not null default now(),
    "attempts" integer not null default 0,
    "last_status" integer
      );


alter table "private"."apple_revocation_queue" enable row level security;

CREATE UNIQUE INDEX apple_identity_tokens_pkey ON private.apple_identity_tokens USING btree (user_id, client_id, token_hash);

CREATE INDEX apple_revocation_due ON private.apple_revocation_queue USING btree (next_attempt_at, id);

CREATE UNIQUE INDEX apple_revocation_queue_pkey ON private.apple_revocation_queue USING btree (id);

CREATE UNIQUE INDEX apple_revocation_queue_user_id_client_id_token_hash_key ON private.apple_revocation_queue USING btree (user_id, client_id, token_hash);

alter table "private"."apple_identity_tokens" add constraint "apple_identity_tokens_pkey" PRIMARY KEY using index "apple_identity_tokens_pkey";

alter table "private"."apple_revocation_queue" add constraint "apple_revocation_queue_pkey" PRIMARY KEY using index "apple_revocation_queue_pkey";

alter table "private"."apple_identity_tokens" add constraint "apple_identity_tokens_client_id_check" CHECK (((length(client_id) >= 1) AND (length(client_id) <= 200))) not valid;

alter table "private"."apple_identity_tokens" validate constraint "apple_identity_tokens_client_id_check";

alter table "private"."apple_identity_tokens" add constraint "apple_identity_tokens_token_ciphertext_check" CHECK (((token_ciphertext ~~ 'v1.%'::text) AND (length(token_ciphertext) < 16384))) not valid;

alter table "private"."apple_identity_tokens" validate constraint "apple_identity_tokens_token_ciphertext_check";

alter table "private"."apple_identity_tokens" add constraint "apple_identity_tokens_token_hash_check" CHECK ((token_hash ~ '^[0-9a-f]{64}$'::text)) not valid;

alter table "private"."apple_identity_tokens" validate constraint "apple_identity_tokens_token_hash_check";

alter table "private"."apple_identity_tokens" add constraint "apple_identity_tokens_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "private"."apple_identity_tokens" validate constraint "apple_identity_tokens_user_id_fkey";

alter table "private"."apple_revocation_queue" add constraint "apple_revocation_queue_user_id_client_id_token_hash_key" UNIQUE using index "apple_revocation_queue_user_id_client_id_token_hash_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION private.claim_apple_revocations(p_limit integer)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with due as (
    select id from private.apple_revocation_queue where next_attempt_at <= now()
    order by next_attempt_at, id limit greatest(1, least(p_limit, 20)) for update skip locked
  ), claimed as (
    update private.apple_revocation_queue q set next_attempt_at = now() + interval '2 minutes', attempts = attempts + 1
    from due where q.id = due.id returning q.id, q.user_id, q.client_id, q.token_ciphertext
  ) select coalesce(jsonb_agg(to_jsonb(claimed)), '[]'::jsonb) from claimed;
$function$
;

CREATE OR REPLACE FUNCTION private.finish_apple_revocation(p_id bigint, p_success boolean, p_status integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if p_success then
    delete from private.apple_revocation_queue where id = p_id;
  else
    update private.apple_revocation_queue
    set last_status = p_status,
        next_attempt_at = now() + make_interval(secs => least(3600, 30 * power(2, least(attempts, 7))::integer))
    where id = p_id;
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION private.queue_apple_revocation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into private.apple_revocation_queue(user_id, client_id, token_hash, token_ciphertext)
  values(old.user_id, old.client_id, old.token_hash, old.token_ciphertext)
  on conflict do nothing;
  return old;
end;
$function$
;

CREATE OR REPLACE FUNCTION private.request_apple_revocation()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_url text := private.vault_secret('apple_revocation_url'); v_secret text := private.vault_secret('push_webhook_secret');
begin
  if v_url is null or v_secret is null or not exists(select 1 from private.apple_revocation_queue where next_attempt_at <= now()) then return; end if;
  perform net.http_post(url := v_url, body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || v_secret), timeout_milliseconds := 60000);
end;
$function$
;

CREATE OR REPLACE FUNCTION private.store_apple_token(p_user_id uuid, p_session_id uuid, p_client_id text, p_token_hash text, p_ciphertext text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  -- Serialize with account deletion. The authenticated session is checked
  -- again after the external Apple exchange, before retaining any token.
  perform u.id from auth.users u join auth.sessions s on s.user_id = u.id
  where u.id = p_user_id and s.id = p_session_id and (s.not_after is null or s.not_after > now())
    and exists(select 1 from auth.identities i where i.user_id = u.id and i.provider = 'apple')
  for key share of u, s;
  if not found then raise exception 'active Apple session required' using errcode = '42501'; end if;
  insert into private.apple_identity_tokens(user_id, client_id, token_hash, token_ciphertext)
  values(p_user_id, p_client_id, p_token_hash, p_ciphertext)
  on conflict(user_id, client_id, token_hash) do update set token_ciphertext = excluded.token_ciphertext;
end;
$function$
;

CREATE TRIGGER apple_token_deleted AFTER DELETE ON private.apple_identity_tokens FOR EACH ROW EXECUTE FUNCTION private.queue_apple_revocation();



-- Privileges and scheduled work are not emitted by the schema diff.
revoke all on private.apple_identity_tokens, private.apple_revocation_queue from public, anon, authenticated, service_role;
revoke all on function private.queue_apple_revocation() from public, anon, authenticated, service_role;
revoke all on function private.store_apple_token(uuid,uuid,text,text,text), private.claim_apple_revocations(integer),
  private.finish_apple_revocation(bigint,boolean,integer), public.store_apple_token(uuid,uuid,text,text,text),
  public.claim_apple_revocations(integer), public.finish_apple_revocation(bigint,boolean,integer)
from public, anon, authenticated, service_role;
grant usage on schema private to service_role;
grant execute on function private.store_apple_token(uuid,uuid,text,text,text), private.claim_apple_revocations(integer),
  private.finish_apple_revocation(bigint,boolean,integer), public.store_apple_token(uuid,uuid,text,text,text),
  public.claim_apple_revocations(integer), public.finish_apple_revocation(bigint,boolean,integer) to service_role;

revoke all on function private.request_apple_revocation() from public, anon, authenticated, service_role;
select cron.schedule('apple-revocation','*/5 * * * *', $$select private.request_apple_revocation()$$);
notify pgrst, 'reload schema';
set check_function_bodies = on;
