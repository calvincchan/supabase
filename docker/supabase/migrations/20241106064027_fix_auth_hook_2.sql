-- set the function security to invoker
DROP FUNCTION IF EXISTS public.custom_access_token_hook (jsonb);

SET
  check_function_bodies = OFF;

CREATE
OR REPLACE FUNCTION public.custom_access_token_hook (_event jsonb) RETURNS jsonb LANGUAGE plpgsql STABLE AS $function$
  declare
    _claims jsonb;
    _user_role "public"."role_enum";

  begin
    -- Get the user's role, first from team_member, then from pending_member
    select COALESCE(
      (select role from "public"."team_member" where id = (_event->>'user_id')::uuid),
      (select role from "public"."pending_member" where id = _event->'claims'->>'email')
    ) into _user_role;

    _claims := _event->'claims';

    if _user_role is not null then
      -- Set the claim
      _claims := jsonb_set(_claims, '{user_role}', to_jsonb(_user_role));
    else
      _claims := jsonb_set(_claims, '{user_role}', 'null');
    end if;

    -- Update the 'claims' object in the original event
    _event := jsonb_set(_event, '{claims}', _claims);

    -- Return the modified or original event
    return _event;
  end;
$function$;

-- must grant usage first
GRANT usage ON SCHEMA public TO supabase_auth_admin;

GRANT ALL ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;

GRANT ALL ON TABLE public.team_member TO supabase_auth_admin;

GRANT ALL ON TABLE public.pending_member TO supabase_auth_admin;

-- update RLS
DROP POLICY "Enable select for supabase_auth_admin" ON "public"."team_member";

CREATE POLICY "Enable select for supabase_auth_admin" ON "public"."team_member" FOR
SELECT
  TO "supabase_auth_admin" USING (TRUE);

DROP POLICY "Enable select for supabase_auth_admin" ON "public"."pending_member";

CREATE POLICY "Enable select for supabase_auth_admin" ON "public"."pending_member" FOR
SELECT
  TO "supabase_auth_admin" USING (TRUE);