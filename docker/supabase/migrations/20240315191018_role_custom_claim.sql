CREATE TYPE "public"."permission_enum" AS ENUM(
  'case:audit',
  'case:create',
  'case:edit',
  'case:list',
  'dashboard:list',
  'my_case:list',
  'progress_note:create',
  'progress_note:delete',
  'progress_note:edit',
  'progress_note:list',
  'remark:list',
  'reminder:create',
  'reminder:delete',
  'reminder:edit',
  'reminder:list',
  'safeguarding_note:create',
  'safeguarding_note:delete',
  'safeguarding_note:edit',
  'safeguarding_note:insert',
  'safeguarding_note:list',
  'safeguarding_note:read_all',
  'session:create',
  'session:delete',
  'session:edit',
  'session:list',
  'target:create',
  'target:delete',
  'target:edit',
  'target:list'
);

CREATE TABLE
  "public"."role_permission" (
    "role" role_enum NOT NULL,
    "permission" permission_enum NOT NULL
  );

ALTER TABLE "public"."role_permission" OWNER TO "postgres";

ALTER TABLE "public"."role_permission" ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX role_permission_pkey ON public.role_permission USING btree (ROLE, permission);

ALTER TABLE "public"."role_permission"
ADD CONSTRAINT "role_permission_pkey" PRIMARY KEY USING INDEX "role_permission_pkey";

GRANT DELETE ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT INSERT ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT REFERENCES ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT
SELECT
  ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT TRIGGER ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT
TRUNCATE ON TABLE "public"."team_member" TO "supabase_auth_admin";

GRANT
UPDATE ON TABLE "public"."team_member" TO "supabase_auth_admin";

CREATE POLICY "Enable read access for authenticated" ON "public"."role_permission" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);

-- add custom_access_token_hook function for adding user_role claim at login
CREATE
OR REPLACE FUNCTION "public"."custom_access_token_hook" (_event jsonb) RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER AS $function$
  declare
    claims jsonb;
    user_role public.role_enum;
  begin
    -- Check if the user is marked as admin in the profiles table
    select role into user_role from public.team_member where id = (_event->>'user_id')::uuid;

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
$function$;

ALTER FUNCTION "public"."custom_access_token_hook" (_event jsonb) OWNER TO "postgres";

-- update is_creator function
DROP FUNCTION IF EXISTS "public"."is_creator" ();

CREATE
OR REPLACE FUNCTION "public"."is_creator" (created_by UUID) RETURNS BOOLEAN LANGUAGE plpgsql AS $function$
BEGIN
  RETURN created_by = auth.uid();
END;
$function$;

ALTER FUNCTION "public"."is_creator" OWNER TO "postgres";

-- add function "is_allowed"
CREATE FUNCTION "public"."is_allowed" (requested_permission permission_enum) RETURNS BOOLEAN LANGUAGE plpgsql AS $function$
declare
  bind_permissions int;
begin
  select count(*)
  from public.role_permission
  where permission = requested_permission
    and role = (auth.jwt() ->> 'user_role')::public.role_enum
  into bind_permissions;

  return bind_permissions > 0;
end;
$function$;

CREATE POLICY "Enable supabase_auth_admin to read user roles" ON "public"."team_member" AS permissive FOR
SELECT
  TO supabase_auth_admin USING (TRUE);