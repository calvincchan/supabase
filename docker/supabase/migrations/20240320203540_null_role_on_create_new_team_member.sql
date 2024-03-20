CREATE
OR REPLACE FUNCTION "public"."custom_access_token_hook" (_event jsonb) RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER AS $function$
  declare
    claims jsonb;
    user_role "public"."role_enum";
  begin
    -- Get the user's role, first from team_member, then from pending_member
    select COALESCE(
      (select role from "public"."team_member" where id = (_event->>'user_id')::uuid),
      (select role from "public"."pending_member" where id = _event->'claims'->>'email')
    ) into user_role;

    claims := _event->'claims';

    if user_role is not null then
      -- Set the claim
      claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
    else
      claims := jsonb_set(claims, '{user_role}', 'null');
    end if;

    -- Update the 'claims' object in the original event
    _event := jsonb_set(_event, '{claims}', claims);

    -- Return the modified or original event
    return _event;
  end;
$function$