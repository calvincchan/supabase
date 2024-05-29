INSERT INTO
  "public"."role_permission"
VALUES
  ('IT Admin', 'team_member:ban'),
  ('Li Ren Leadership', 'team_member:ban'),
  ('IT Admin', 'team_member:unban'),
  ('Li Ren Leadership', 'team_member:unban');

CREATE
OR REPLACE FUNCTION "public"."ban_user" (p_user_id UUID) RETURNS VOID AS $$
BEGIN
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot ban of your own account.';
  END IF;
  IF public.is_allowed('team_member:ban') THEN
    UPDATE "auth"."users"
    SET "banned_until" = '2999-12-31'::timestamp
    WHERE "id" = p_user_id;

    UPDATE "public"."team_member"
    SET "banned" = true
    WHERE "id" = p_user_id;
  ELSE
    RAISE EXCEPTION 'You do not have permission to ban an account.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE
OR REPLACE FUNCTION "public"."unban_user" (p_user_id UUID) RETURNS VOID AS $$
BEGIN
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot unban your own account.';
  END IF;
  IF public.is_allowed('team_member:unban') THEN
    UPDATE "auth"."users"
    SET "banned_until" = NULL
    WHERE "id" = p_user_id;

    UPDATE "public"."team_member"
    SET "banned" = false
    WHERE "id" = p_user_id;
  ELSE
    RAISE EXCEPTION 'You do not have permission to unban an account.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION "public"."unban_user" (UUID) OWNER TO "postgres";