ALTER TABLE "public"."team_member"
ADD COLUMN "banned" BOOLEAN NOT NULL DEFAULT FALSE;

CREATE
OR REPLACE FUNCTION "public"."ban_user" (p_user_id UUID) RETURNS VOID AS $$
BEGIN
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot change active state of your own account.';
  END IF;
  IF public.is_allowed('team_member:delete') THEN
    UPDATE "auth"."users"
    SET "banned_until" = '2999-12-31'::timestamp
    WHERE "id" = p_user_id;

    UPDATE "public"."team_member"
    SET "banned" = true
    WHERE "id" = p_user_id;
  ELSE
    RAISE EXCEPTION 'You do not have permission to change active state an account.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION "public"."ban_user" (UUID) OWNER TO "postgres";

CREATE
OR REPLACE FUNCTION "public"."unban_user" (p_user_id UUID) RETURNS VOID AS $$
BEGIN
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot change active state of your own account.';
  END IF;
  IF public.is_allowed('team_member:delete') THEN
    UPDATE "auth"."users"
    SET "banned_until" = NULL
    WHERE "id" = p_user_id;

    UPDATE "public"."team_member"
    SET "banned" = false
    WHERE "id" = p_user_id;
  ELSE
    RAISE EXCEPTION 'You do not have permission to change active state an account.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION "public"."unban_user" (UUID) OWNER TO "postgres";