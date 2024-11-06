

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "audit";


ALTER SCHEMA "audit" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "audit"."operation" AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE'
);


ALTER TYPE "audit"."operation" OWNER TO "postgres";


CREATE TYPE "public"."core_needs_enum" AS ENUM (
    'Learning',
    'Learning (IAA only)',
    'Social emotional',
    'Behavioural',
    'Physical',
    'Giftedness',
    'Others'
);


ALTER TYPE "public"."core_needs_enum" OWNER TO "postgres";


CREATE TYPE "public"."diagnosis_enum" AS ENUM (
    'Anxiety',
    'Attention (ADHD; ADD)',
    'Autism Spectrum Disorder (ASD)',
    'Depression',
    'Dyslexia',
    'Dyscalculia',
    'Dysgraphia',
    'Dyspraxia',
    'Eating disorders',
    'Executive Functioning skills',
    'Obsessive Compulsive Disorder',
    'Post-traumatic Stress Disorder',
    'Sensory Processing Disorder',
    'Social Communication Disorder',
    'Others'
);


ALTER TYPE "public"."diagnosis_enum" OWNER TO "postgres";


CREATE TYPE "public"."grade_enum" AS ENUM (
    'Y1',
    'Y2',
    'FY',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12'
);


ALTER TYPE "public"."grade_enum" OWNER TO "postgres";


CREATE TYPE "public"."iaa_enum" AS ENUM (
    'Separate room',
    'Time extension',
    'Word processor',
    'Oral exams (25%)',
    'Listening exam',
    'Scribing',
    'Paper size',
    'Breaks',
    'Others'
);


ALTER TYPE "public"."iaa_enum" OWNER TO "postgres";


CREATE TYPE "public"."iaa_time_extension_enum" AS ENUM (
    '10%',
    '25%',
    '50%',
    'Subjects ALL',
    'Subjects ONLY'
);


ALTER TYPE "public"."iaa_time_extension_enum" OWNER TO "postgres";


CREATE TYPE "public"."iaa_word_processor_enum" AS ENUM (
    'With spellchecker',
    'Without spellchecker',
    'Subjects ALL',
    'Subjects ONLY'
);


ALTER TYPE "public"."iaa_word_processor_enum" OWNER TO "postgres";


CREATE TYPE "public"."permission_enum" AS ENUM (
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
    'target:list',
    'case_handler:list',
    'case_handler:create',
    'case_handler:edit',
    'case_handler:delete',
    'page:list',
    'page:create',
    'page:edit',
    'page:delete',
    'specialist:list',
    'specialist:create',
    'specialist:edit',
    'specialist:delete',
    'pending_member:list',
    'pending_member:create',
    'pending_member:edit',
    'pending_member:delete',
    'team_member:list',
    'team_member:create',
    'team_member:edit',
    'team_member:delete',
    'team_member:ban',
    'team_member:unban',
    'rollover_job:list',
    'rollover_job:create'
);


ALTER TYPE "public"."permission_enum" OWNER TO "postgres";


CREATE TYPE "public"."role_enum" AS ENUM (
    'IT Admin',
    'GLL',
    'Nurse',
    'Li Ren Leadership',
    'Li Ren GLS',
    'Li Ren Contact'
);


ALTER TYPE "public"."role_enum" OWNER TO "postgres";


CREATE TYPE "public"."specialist_enum" AS ENUM (
    'Clinical Psychologist',
    'Educational Psychologist',
    'Psychiatrist',
    'Occupational Therapist',
    'Speech Therapist',
    'Counselor',
    'Family Therapist',
    'Other Therapist',
    'Others'
);


ALTER TYPE "public"."specialist_enum" OWNER TO "postgres";


CREATE TYPE "public"."target_type_enum" AS ENUM (
    'Academic',
    'Social Emotional',
    'Behavioural',
    'Others'
);


ALTER TYPE "public"."target_type_enum" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."disable_tracking"("regclass") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
declare
    statement_row text = format(
        'drop trigger if exists audit_i_u_d on %s;',
        $1
    );

    statement_stmt text = format(
        'drop trigger if exists audit_t on %s;',
        $1
    );
begin
    execute statement_row;
    execute statement_stmt;
end;
$_$;


ALTER FUNCTION "audit"."disable_tracking"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."enable_tracking"("regclass") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
declare
    statement_row text = format('
        create trigger audit_i_u_d
            after insert or update or delete
            on %s
            for each row
            execute procedure audit.insert_update_delete_trigger();',
        $1
    );

    statement_stmt text = format('
        create trigger audit_t
            after truncate
            on %s
            for each statement
            execute procedure audit.truncate_trigger();',
        $1
    );

    pkey_cols text[] = audit.primary_key_columns($1);
begin
    if pkey_cols = array[]::text[] then
        raise exception 'Table % can not be audited because it has no primary key', $1;
    end if;

    if not exists(select 1 from pg_trigger where tgrelid = $1 and tgname = 'audit_i_u_d') then
        execute statement_row;
    end if;

    if not exists(select 1 from pg_trigger where tgrelid = $1 and tgname = 'audit_t') then
        execute statement_stmt;
    end if;
end;
$_$;


ALTER FUNCTION "audit"."enable_tracking"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."insert_update_delete_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
    pkey_cols text[] = audit.primary_key_columns(TG_RELID);

    record_jsonb jsonb = to_jsonb(new);
    record_id uuid = audit.to_record_id(TG_RELID, pkey_cols, record_jsonb);

    old_record_jsonb jsonb = to_jsonb(old);
    old_record_id uuid = audit.to_record_id(TG_RELID, pkey_cols, old_record_jsonb);
begin

    insert into audit.record_version(
        record_id,
        old_record_id,
        op,
        table_oid,
        table_schema,
        table_name,
        record,
        old_record
    )
    select
        record_id,
        old_record_id,
        TG_OP::audit.operation,
        TG_RELID,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        record_jsonb,
        old_record_jsonb;

    return coalesce(new, old);
end;
$$;


ALTER FUNCTION "audit"."insert_update_delete_trigger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."primary_key_columns"("entity_oid" "oid") RETURNS "text"[]
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
    -- Looks up the names of a table's primary key columns
    select
        coalesce(
            array_agg(pa.attname::text order by pa.attnum),
            array[]::text[]
        ) column_names
    from
        pg_index pi
        join pg_attribute pa
            on pi.indrelid = pa.attrelid
            and pa.attnum = any(pi.indkey)

    where
        indrelid = $1
        and indisprimary
$_$;


ALTER FUNCTION "audit"."primary_key_columns"("entity_oid" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."to_record_id"("entity_oid" "oid", "pkey_cols" "text"[], "rec" "jsonb") RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $_$
    select
        case
            when rec is null then null
            when pkey_cols = array[]::text[] then extensions.uuid_generate_v4()
            else (
                select
                    extensions.uuid_generate_v5(
                        'fd62bc3d-8d6e-43c2-919c-802ba3762271',
                        ( jsonb_build_array(to_jsonb($1)) || jsonb_agg($3 ->> key_) )::text
                    )
                from
                    unnest($2) x(key_)
            )
        end
$_$;


ALTER FUNCTION "audit"."to_record_id"("entity_oid" "oid", "pkey_cols" "text"[], "rec" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "audit"."truncate_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
    insert into audit.record_version(
        op,
        table_oid,
        table_schema,
        table_name
    )
    select
        TG_OP::audit.operation,
        TG_RELID,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME;

    return coalesce(old, new);
end;
$$;


ALTER FUNCTION "audit"."truncate_trigger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."accept_legacy_progress_note"("p_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  legacy_record legacy_progress_note%ROWTYPE;
  v_progress_note_id BIGINT;
  v_name TEXT;
BEGIN
  -- Fetch the record from legacy_progress_note
  SELECT * INTO legacy_record FROM legacy_progress_note WHERE id = p_id;

  -- Check if the record exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Record with id % does not exist in legacy_progress_note', p_id;
  END IF;

  -- get name of entered_by, if not found that use legacy_record.entered_by
  SELECT name INTO v_name FROM team_member WHERE id = legacy_record.entered_by_uuid;
  IF NOT FOUND THEN
    v_name := legacy_record.entered_by;
  END IF;

  -- Insert the record into progress_note, and get the inserted id
  INSERT INTO progress_note (case_id, content, tags, created_at, created_by, created_by_name, updated_at, updated_by, updated_by_name, imported_at, imported_by, imported_by_name, import_record_id)
  VALUES (legacy_record.case_id, legacy_record.content, legacy_record.tags, legacy_record.entered_at_date, legacy_record.entered_by_uuid, v_name, legacy_record.entered_at_date, legacy_record.entered_by_uuid, v_name, NOW(), auth.uid(), get_name(), p_id)
  RETURNING id INTO v_progress_note_id;

  -- Update the legacy record to status 'Accepted', set accepted_at and accepted_by
  UPDATE legacy_progress_note
  SET status = 'Accepted', accepted_at = NOW(), accepted_by = auth.uid(), accepted_by_name = get_name()
  WHERE id = p_id;
END;
$$;


ALTER FUNCTION "public"."accept_legacy_progress_note"("p_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_table_to_publication_if_not_exists"("schema_name" "text", "table_name" "text", "publication_name" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = publication_name
        AND tablename = table_name
        AND schemaname = schema_name
    ) THEN
        EXECUTE format('ALTER PUBLICATION %I ADD TABLE %I.%I', publication_name, schema_name, table_name);
    END IF;
END;
$$;


ALTER FUNCTION "public"."add_table_to_publication_if_not_exists"("schema_name" "text", "table_name" "text", "publication_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ban_user"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."ban_user"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."custom_access_token_hook"("_event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."custom_access_token_hook"("_event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_next_upcoming_session"("p_case_id" bigint) RETURNS timestamp with time zone
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  closest_start_date TIMESTAMP WITH TIME ZONE;
BEGIN
  SELECT start_date INTO closest_start_date
  FROM session
  WHERE case_id = p_case_id AND status = 'U' AND start_date >= CURRENT_DATE
  ORDER BY start_date ASC
  LIMIT 1;

  RETURN closest_start_date;
END;
$$;


ALTER FUNCTION "public"."find_next_upcoming_session"("p_case_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_case_gls_details"("p_case_id" bigint) RETURNS TABLE("user_id" "uuid", "case_id" bigint, "name" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.user_id, a.case_id, b.name
  FROM case_gls AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id
  ORDER BY b.name;
END;
$$;


ALTER FUNCTION "public"."get_case_gls_details"("p_case_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_case_handler_details"("p_case_id" bigint) RETURNS TABLE("user_id" "uuid", "case_id" bigint, "name" "text", "is_main_handler" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.user_id, a.case_id, b.name, a.is_main_handler
  FROM case_handler AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id
  ORDER BY b.name;END;
$$;


ALTER FUNCTION "public"."get_case_handler_details"("p_case_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_cases_by_handler"("p_user_id" "uuid") RETURNS TABLE("id" bigint, "student_name" "text", "student_no" "text", "next_session_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.student_name, a.student_no, a.next_session_at
  FROM "case" AS a
  JOIN "case_handler" AS b ON a.id = b.case_id
  WHERE b.user_id = p_user_id
  ORDER BY a.next_session_at;
END;
$$;


ALTER FUNCTION "public"."get_cases_by_handler"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_managed_grades"() RETURNS "public"."grade_enum"[]
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_grades grade_enum[];
BEGIN
  SELECT managed_grades INTO v_grades
   FROM team_member WHERE id = auth.uid();
  RETURN v_grades;
END;
$$;


ALTER FUNCTION "public"."get_managed_grades"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_name"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_name TEXT;
BEGIN
  SELECT name INTO v_name FROM team_member WHERE id = auth.uid();
  RETURN v_name;
END;
$$;


ALTER FUNCTION "public"."get_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_role"() RETURNS "public"."role_enum"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_role role_enum;
BEGIN
  SELECT role INTO v_role FROM team_member WHERE id = auth.uid();
  RETURN v_role;
END;
$$;


ALTER FUNCTION "public"."get_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_session_collaborator_details"("p_session_id" bigint) RETURNS TABLE("user_id" "uuid", "session_id" bigint, "name" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.user_id, a.session_id, b.name
  FROM session_collaborator AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.session_id = p_session_id
  ORDER BY b.name;
END;
$$;


ALTER FUNCTION "public"."get_session_collaborator_details"("p_session_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_session_collaborator"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO "public"."session_collaborator" ("session_id", "user_id")
  VALUES (NEW.id, NEW.created_by);
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."insert_session_collaborator"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.team_member (id, email, name, role)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'role');
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."insert_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_allowed"("requested_permission" "public"."permission_enum") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."is_allowed"("requested_permission" "public"."permission_enum") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_case_handler"("p_case_id" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN (
    SELECT EXISTS(
      SELECT 1 FROM case_handler WHERE case_id = p_case_id AND user_id = auth.uid()
    )
  );
END;
$$;


ALTER FUNCTION "public"."is_case_handler"("p_case_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_creator"("created_by" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN created_by = auth.uid();
END;
$$;


ALTER FUNCTION "public"."is_creator"("created_by" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_completed_meta"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.is_completed = TRUE THEN
    NEW.completed_at := now();
    NEW.completed_by := auth.uid();
    SELECT get_name() INTO NEW.completed_by_name;
  ELSE
    NEW.completed_at := null;
    NEW.completed_by := null;
    NEW.completed_by_name := null;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_completed_meta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_main_handler"("p_case_id" bigint, "p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Set all rows with the given p_case_id to is_main_handler = false
  UPDATE case_handler
  SET is_main_handler = false
  WHERE case_id = p_case_id;

  -- Set the row with the given p_case_id and p_user_id to is_main_handler = true
  UPDATE case_handler
  SET is_main_handler = true
  WHERE case_id = p_case_id AND user_id = p_user_id;
END;
$$;


ALTER FUNCTION "public"."set_main_handler"("p_case_id" bigint, "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_not_null_default_empty_string"("column_name" "text", "table_name" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  EXECUTE format('UPDATE %I SET %I = '''' WHERE %I IS NULL', table_name, column_name, column_name);
  EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET DEFAULT ''''', table_name, column_name);
  EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET NOT NULL', table_name, column_name);
END;
$$;


ALTER FUNCTION "public"."set_not_null_default_empty_string"("column_name" "text", "table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."should_apply_grade_filter"() RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN (auth.jwt() ->> 'user_role') = 'GLL';
END;
$$;


ALTER FUNCTION "public"."should_apply_grade_filter"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."team_member_i_u_from_sso"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_name text;
    new_role public.role_enum;
BEGIN
    IF NEW.is_sso_user = TRUE THEN
        -- The first sso user will be a manager
        IF NOT EXISTS (SELECT 1 FROM public.team_member LIMIT 1) THEN
            INSERT INTO public.team_member(id, name, email, role, last_sign_in_at)
            VALUES (NEW.id, '(new sso user)', NEW.email, 'IT Admin'::public.role_enum, NEW.last_sign_in_at);
        ELSE
            -- Check if the user is already a team member
            IF EXISTS (SELECT 1 FROM public.team_member WHERE email = NEW.email) THEN
                -- Update the last_sign_in_at
                UPDATE public.team_member
                SET last_sign_in_at = NEW.last_sign_in_at
                WHERE email = NEW.email;
            ELSE
                -- Check if the user is invited
                IF EXISTS (SELECT 1 FROM public.pending_member WHERE id = NEW.email) THEN
                    -- Insert the user into team_member and update the invite status
                    SELECT name, role INTO new_name, new_role FROM public.pending_member WHERE id = NEW.email;
                    INSERT INTO public.team_member(id, name, email, role, last_sign_in_at)
                    VALUES (NEW.id, new_name, NEW.email, new_role, NEW.last_sign_in_at);
                    UPDATE public.pending_member SET activated_at = NOW() WHERE id = NEW.email;
                ELSE
                    -- throw error
                    RAISE EXCEPTION 'SSO user % is not invited', NEW.email;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."team_member_i_u_from_sso"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_on_session_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF OLD.status = 'U' AND (NEW.status = 'I' OR NEW.status = 'X') THEN
    UPDATE "case" SET last_session_at = NOW(), last_session_by = auth.uid(), last_session_by_name = get_name() WHERE id = NEW.case_id;
    NEW.started_at = NOW();
    NEW.started_by = auth.uid();
    SELECT get_name() INTO NEW.started_by_name;
  END IF;
  IF (OLD.status = 'U' OR OLD.status = 'I') AND NEW.status = 'X' THEN
    UPDATE "case" SET last_session_at = NOW(), last_session_by = auth.uid(), last_session_by_name = get_name() WHERE id = NEW.case_id;
    NEW.completed_at = NOW();
    NEW.completed_by = auth.uid();
    SELECT get_name() INTO NEW.completed_by_name;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_on_session_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_case_gls"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  gls_string TEXT;
  p_case_id BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    p_case_id := OLD.case_id;
  ELSE
    p_case_id := NEW.case_id;
  END IF;

  -- all handlers
  SELECT STRING_AGG(b.name, '|' ORDER BY b.name ASC) INTO gls_string
  FROM case_gls AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id;

  UPDATE "case" SET gls = COALESCE(gls_string, '') WHERE id = p_case_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_case_gls"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_created_meta"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
  NEW.created_by := auth.uid();
  NEW.created_by_name := get_name();
  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."trigger_set_created_meta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_handlers"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  handler_string TEXT;
  p_case_id BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    p_case_id := OLD.case_id;
  ELSE
    p_case_id := NEW.case_id;
  END IF;

  -- all handlers
  SELECT STRING_AGG(b.name, '|' ORDER BY a.is_main_handler DESC, b.name ASC) INTO handler_string
  FROM case_handler AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id;

  UPDATE "case" SET handlers = COALESCE(handler_string, '') WHERE id = p_case_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_handlers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_main_handler"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  main_handler_exists BOOLEAN;
BEGIN
  -- Check if there is another row with the same case_id and is_main_handler = true
  SELECT EXISTS (
    SELECT 1
    FROM case_handler
    WHERE case_id = NEW.case_id AND is_main_handler = true
  ) INTO main_handler_exists;

  -- If no other row with is_main_handler = true exists, set the current row's is_main_handler to true
  IF NOT main_handler_exists THEN
    NEW.is_main_handler := true;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_main_handler"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_next_upcoming_session"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  p_case_id BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    p_case_id := OLD.case_id;
  ELSE
    p_case_id := NEW.case_id;
  END IF;

  UPDATE "case" SET next_session_at = find_next_upcoming_session(p_case_id) WHERE id = p_case_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_next_upcoming_session"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_session_collaborator"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  collaborator_string TEXT;
  p_session_id BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    p_session_id := OLD.session_id;
  ELSE
    p_session_id := NEW.session_id;
  END IF;

  SELECT STRING_AGG(b.name, '|' ORDER BY b.name ASC) INTO collaborator_string
  FROM session_collaborator AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.session_id = p_session_id;

  UPDATE "session" SET collaborators = COALESCE(collaborator_string, '') WHERE id = p_session_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_session_collaborator"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_set_updated_meta"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
  NEW.updated_at := now();
  NEW.updated_by := auth.uid();
  NEW.updated_by_name := get_name();
  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."trigger_set_updated_meta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."unban_user"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."unban_user"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_specialist_name"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        NEW."name" = TRIM(BOTH ' ' FROM UPPER(NEW."last_name") || ' ' || NEW."first_name");
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_specialist_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_student_name"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        NEW."student_name" = TRIM(BOTH ' ' FROM UPPER(NEW."student_last_name") || ' ' || NEW."student_first_name");
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_student_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.team_member
  SET email = NEW.email,
      name = NEW.raw_user_meta_data->>'name',
      role = NEW.raw_user_meta_data->>'role'
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "audit"."record_version" (
    "id" bigint NOT NULL,
    "record_id" "uuid",
    "old_record_id" "uuid",
    "op" "audit"."operation" NOT NULL,
    "ts" timestamp with time zone DEFAULT "now"() NOT NULL,
    "table_oid" "oid" NOT NULL,
    "table_schema" "name" NOT NULL,
    "table_name" "name" NOT NULL,
    "record" "jsonb",
    "old_record" "jsonb",
    "auth_uid" "uuid" DEFAULT "auth"."uid"(),
    "auth_role" "text" DEFAULT "auth"."role"(),
    CONSTRAINT "record_version_check" CHECK (((COALESCE("record_id", "old_record_id") IS NOT NULL) OR ("op" = 'TRUNCATE'::"audit"."operation"))),
    CONSTRAINT "record_version_check1" CHECK ((("op" = ANY (ARRAY['INSERT'::"audit"."operation", 'UPDATE'::"audit"."operation"])) = ("record_id" IS NOT NULL))),
    CONSTRAINT "record_version_check2" CHECK ((("op" = ANY (ARRAY['INSERT'::"audit"."operation", 'UPDATE'::"audit"."operation"])) = ("record" IS NOT NULL))),
    CONSTRAINT "record_version_check3" CHECK ((("op" = ANY (ARRAY['UPDATE'::"audit"."operation", 'DELETE'::"audit"."operation"])) = ("old_record_id" IS NOT NULL))),
    CONSTRAINT "record_version_check4" CHECK ((("op" = ANY (ARRAY['UPDATE'::"audit"."operation", 'DELETE'::"audit"."operation"])) = ("old_record" IS NOT NULL)))
);


ALTER TABLE "audit"."record_version" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "audit"."record_version_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "audit"."record_version_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "audit"."record_version_id_seq" OWNED BY "audit"."record_version"."id";



CREATE TABLE IF NOT EXISTS "public"."case" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "student_name" "text" DEFAULT ''::"text" NOT NULL,
    "student_no" "text" DEFAULT ''::"text" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_archived" boolean,
    "archived_at" timestamp with time zone,
    "archived_by" "uuid",
    "case_status" character(1) DEFAULT 'I'::"bpchar" NOT NULL,
    "updated_by_name" "text",
    "grade" "public"."grade_enum",
    "homeroom" "text" DEFAULT ''::"text" NOT NULL,
    "created_by" "uuid",
    "created_by_name" "text",
    "tier" character(1) DEFAULT '1'::"bpchar",
    "last_session_at" timestamp with time zone,
    "next_session_at" timestamp with time zone,
    "last_session_by" "uuid",
    "last_session_by_name" "text",
    "student_first_name" "text" DEFAULT ''::"text" NOT NULL,
    "student_last_name" "text" DEFAULT ''::"text" NOT NULL,
    "background" "text" DEFAULT ''::"text" NOT NULL,
    "student_other_name" "text" DEFAULT ''::"text" NOT NULL,
    "gender" character(1) DEFAULT '-'::"bpchar" NOT NULL,
    "dob" "date",
    "email" "text" DEFAULT ''::"text" NOT NULL,
    "parent_email" "text" DEFAULT ''::"text" NOT NULL,
    "mother_name" "text" DEFAULT ''::"text" NOT NULL,
    "mother_phone" "text" DEFAULT ''::"text" NOT NULL,
    "mother_email" "text" DEFAULT ''::"text" NOT NULL,
    "father_name" "text" DEFAULT ''::"text" NOT NULL,
    "father_phone" "text" DEFAULT ''::"text" NOT NULL,
    "father_email" "text" DEFAULT ''::"text" NOT NULL,
    "handlers" "text" DEFAULT ''::"text" NOT NULL,
    "custom_1" "text" DEFAULT ''::"text" NOT NULL,
    "custom_2" "text" DEFAULT ''::"text" NOT NULL,
    "custom_3" "text" DEFAULT ''::"text" NOT NULL,
    "custom_4" "text" DEFAULT ''::"text" NOT NULL,
    "custom_5" "text" DEFAULT ''::"text" NOT NULL,
    "case_opened_at" "date",
    "core_needs" "public"."core_needs_enum"[] DEFAULT '{}'::"public"."core_needs_enum"[] NOT NULL,
    "core_needs_others" "text" DEFAULT ''::"text" NOT NULL,
    "diagnosis" "public"."diagnosis_enum"[] DEFAULT '{}'::"public"."diagnosis_enum"[] NOT NULL,
    "diagnosis_others" "text" DEFAULT ''::"text" NOT NULL,
    "giftedness_identification_year" "text" DEFAULT ''::"text" NOT NULL,
    "iaa" "public"."iaa_enum"[] DEFAULT '{}'::"public"."iaa_enum"[] NOT NULL,
    "iaa_listening_exam" "text" DEFAULT ''::"text" NOT NULL,
    "iaa_others" "text" DEFAULT ''::"text" NOT NULL,
    "iaa_time_extension" "public"."iaa_time_extension_enum"[] DEFAULT '{}'::"public"."iaa_time_extension_enum"[] NOT NULL,
    "iaa_time_extension_subjects_only" "text" DEFAULT ''::"text" NOT NULL,
    "iaa_word_processor" "public"."iaa_word_processor_enum"[] DEFAULT '{}'::"public"."iaa_word_processor_enum"[] NOT NULL,
    "iaa_word_processor_subjects_only" "text" DEFAULT ''::"text" NOT NULL,
    "medical_letter" character(1) DEFAULT '-'::"bpchar" NOT NULL,
    "medical_letter_attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "pa_report" character(1) DEFAULT '-'::"bpchar" NOT NULL,
    "pa_report_attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "pa_report_last_report_at" "date",
    "pa_report_next_report_at" "date",
    "safeguarding_concerns" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "safeguarding_concerns_others" "text" DEFAULT ''::"text" NOT NULL,
    "specialists" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "case_no" "text" DEFAULT ''::"text" NOT NULL,
    "student_preferred_name" "text" DEFAULT ''::"text" NOT NULL,
    "information_release_form_attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "parent_consent_form_attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "termination_form_attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "support_frequency_counselling" "text" DEFAULT ''::"text" NOT NULL,
    "support_frequency_learning" "text" DEFAULT ''::"text" NOT NULL,
    "medication_current" "text" DEFAULT ''::"text" NOT NULL,
    "medication_past" "text" DEFAULT ''::"text" NOT NULL,
    "subject_iaa" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "gls" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "case_tier_check" CHECK (("tier" = ANY (ARRAY['1'::"bpchar", '2'::"bpchar", '3'::"bpchar"])))
);


ALTER TABLE "public"."case" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."case_gls" (
    "case_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "public"."case_gls" OWNER TO "postgres";


ALTER TABLE "public"."case_gls" ALTER COLUMN "case_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."case_gls_case_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."case_handler" (
    "case_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid" NOT NULL,
    "is_main_handler" boolean DEFAULT false NOT NULL,
    "created_by" "uuid"
);


ALTER TABLE "public"."case_handler" OWNER TO "postgres";


ALTER TABLE "public"."case" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."case_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."progress_note" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "updated_by" "uuid",
    "case_id" bigint,
    "content" "text",
    "created_by_name" "text",
    "updated_by_name" "text",
    "tags" "bpchar"[] DEFAULT '{}'::"bpchar"[] NOT NULL,
    "attachments" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "import_record_id" bigint,
    "imported_at" timestamp with time zone,
    "imported_by" "uuid",
    "imported_by_name" "text"
);


ALTER TABLE "public"."progress_note" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reminder" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "updated_by" "uuid",
    "updated_by_name" "text",
    "content" "text",
    "due_date" timestamp with time zone,
    "is_completed" boolean DEFAULT false NOT NULL,
    "completed_at" timestamp with time zone,
    "completed_by" "uuid",
    "completed_by_name" "text",
    "case_id" bigint,
    "end_date" "date" NOT NULL,
    "start_date" "date" NOT NULL,
    CONSTRAINT "end_date_check" CHECK (("end_date" >= "start_date"))
);


ALTER TABLE "public"."reminder" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."session" (
    "id" bigint NOT NULL,
    "case_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "updated_by" "uuid",
    "updated_by_name" "text",
    "started_at" timestamp with time zone,
    "started_by" "uuid",
    "started_by_name" "text",
    "completed_at" timestamp with time zone,
    "completed_by" "uuid",
    "completed_by_name" "text",
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "language" character(1) DEFAULT 'E'::"bpchar" NOT NULL,
    "status" character(1) DEFAULT 'U'::"bpchar" NOT NULL,
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone NOT NULL,
    "recurrence_rule" "text" DEFAULT ''::"text" NOT NULL,
    "time_frame" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "mode" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "learning" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "seb" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "counselling" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "cca" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "haoxue" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "non_case" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "parent_session" character(1) DEFAULT ''::"bpchar" NOT NULL,
    "parent_session_note" "text",
    "recurrence_parent" bigint,
    "recurrence_start_date" timestamp with time zone,
    "time_frame_until" timestamp with time zone,
    "collaborators" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."session" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."target" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "updated_by_name" "text",
    "case_id" integer NOT NULL,
    "target_type" "public"."target_type_enum" DEFAULT 'Others'::"public"."target_type_enum" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."target" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_member" (
    "id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "role" "public"."role_enum",
    "email" "text",
    "last_sign_in_at" timestamp with time zone,
    "service" boolean DEFAULT false NOT NULL,
    "banned" boolean DEFAULT false NOT NULL,
    "managed_grades" "public"."grade_enum"[] DEFAULT '{}'::"public"."grade_enum"[] NOT NULL
);


ALTER TABLE "public"."team_member" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."case_oplog" AS
 SELECT "rv"."id",
    "rv"."record_id",
    "rv"."old_record_id",
    "rv"."op",
    "rv"."ts",
    "rv"."record",
    "rv"."old_record",
    "rv"."auth_uid",
    "rv"."auth_role",
    "tm"."name" AS "actor",
    "rv"."table_name"
   FROM ("audit"."record_version" "rv"
     LEFT JOIN "public"."team_member" "tm" ON (("rv"."auth_uid" = "tm"."id")))
  WHERE ("rv"."table_oid" = ANY (ARRAY[('"public"."case"'::"regclass")::"oid", ('"public"."progress_note"'::"regclass")::"oid", ('"public"."reminder"'::"regclass")::"oid", ('"public"."session"'::"regclass")::"oid", ('"public"."case_handler"'::"regclass")::"oid", ('"public"."target"'::"regclass")::"oid"]));


ALTER TABLE "public"."case_oplog" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legacy_progress_note" (
    "id" bigint NOT NULL,
    "case_id" bigint NOT NULL,
    "row_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "entered_at" "text" NOT NULL,
    "entered_by" "text" NOT NULL,
    "content" "text" NOT NULL,
    "status" "text" DEFAULT 'Draft'::"text" NOT NULL,
    "entered_at_date" timestamp with time zone,
    "entered_by_uuid" "uuid",
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "accepted_at" timestamp with time zone,
    "accepted_by" "uuid",
    "accepted_by_name" "text"
);


ALTER TABLE "public"."legacy_progress_note" OWNER TO "postgres";


ALTER TABLE "public"."legacy_progress_note" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."legacy_progress_note_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."legacy_progress_note_job" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'Ready'::"text" NOT NULL,
    "message" "text" DEFAULT ''::"text" NOT NULL,
    "case_id" bigint NOT NULL,
    "filepath" "text" DEFAULT ''::"text" NOT NULL,
    "xml" "text" DEFAULT ''::"text" NOT NULL,
    "item_total" bigint DEFAULT '0'::bigint NOT NULL,
    "dryrun" boolean NOT NULL
);


ALTER TABLE "public"."legacy_progress_note_job" OWNER TO "postgres";


ALTER TABLE "public"."legacy_progress_note_job" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."legacy_progress_note_job_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."my_case" AS
 SELECT "a"."id",
    "a"."created_at",
    "a"."student_name",
    "a"."student_no",
    "a"."updated_at",
    "a"."updated_by",
    "a"."is_archived",
    "a"."archived_at",
    "a"."archived_by",
    "a"."case_status",
    "a"."updated_by_name",
    "a"."grade",
    "a"."homeroom",
    "a"."created_by",
    "a"."created_by_name",
    "a"."tier",
    "a"."core_needs",
    "a"."last_session_at",
    "a"."next_session_at",
    "a"."last_session_by",
    "a"."last_session_by_name",
    "a"."handlers",
    "a"."gls",
    "a"."student_first_name",
    "a"."student_last_name",
    "a"."background",
    "a"."student_other_name",
    "a"."student_preferred_name",
    "a"."case_no"
   FROM ("public"."case" "a"
     JOIN "public"."case_handler" "b" ON (("a"."id" = "b"."case_id")))
  WHERE ("b"."user_id" = "auth"."uid"());


ALTER TABLE "public"."my_case" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_progress_note" AS
 SELECT "a"."id",
    "a"."case_id",
    "a"."created_at",
    "a"."created_by",
    "a"."created_by_name",
    "a"."updated_at",
    "a"."updated_by",
    "a"."updated_by_name",
    "a"."content",
    "a"."tags",
    "a"."attachments"
   FROM ("public"."progress_note" "a"
     JOIN "public"."case_handler" "b" ON (("a"."case_id" = "b"."case_id")))
  WHERE ("b"."user_id" = "auth"."uid"());


ALTER TABLE "public"."my_progress_note" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_reminder" AS
 SELECT "a"."id",
    "a"."case_id",
    "a"."created_at",
    "a"."created_by",
    "a"."created_by_name",
    "a"."updated_at",
    "a"."updated_by",
    "a"."updated_by_name",
    "a"."content",
    "a"."due_date",
    "a"."start_date",
    "a"."end_date"
   FROM ("public"."reminder" "a"
     JOIN "public"."case_handler" "b" ON (("a"."case_id" = "b"."case_id")))
  WHERE ("b"."user_id" = "auth"."uid"());


ALTER TABLE "public"."my_reminder" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."session_collaborator" (
    "session_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL
);


ALTER TABLE "public"."session_collaborator" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_session" AS
 SELECT "a"."id",
    "a"."case_id",
    "a"."created_at",
    "a"."created_by",
    "a"."created_by_name",
    "a"."updated_at",
    "a"."updated_by",
    "a"."updated_by_name",
    "a"."started_at",
    "a"."started_by",
    "a"."started_by_name",
    "a"."completed_at",
    "a"."completed_by",
    "a"."completed_by_name",
    "a"."content",
    "a"."language",
    "a"."status",
    "a"."collaborators",
    "a"."start_date",
    "a"."end_date",
    "a"."recurrence_rule",
    "a"."time_frame",
    "a"."time_frame_until",
    "a"."mode",
    "a"."learning",
    "a"."seb",
    "a"."counselling",
    "a"."cca",
    "a"."haoxue",
    "a"."non_case",
    "a"."parent_session",
    "a"."parent_session_note",
    "a"."recurrence_parent",
    "a"."recurrence_start_date"
   FROM ("public"."session" "a"
     JOIN "public"."session_collaborator" "b" ON (("a"."id" = "b"."session_id")))
  WHERE ("b"."user_id" = "auth"."uid"());


ALTER TABLE "public"."my_session" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."page" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "updated_by" "uuid",
    "updated_by_name" "text",
    "title" "text",
    "content" "text"
);


ALTER TABLE "public"."page" OWNER TO "postgres";


ALTER TABLE "public"."page" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."page_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."page_oplog" AS
 SELECT "rv"."id",
    "rv"."record_id",
    "rv"."old_record_id",
    "rv"."op",
    "rv"."ts",
    "rv"."record",
    "rv"."old_record",
    "rv"."auth_uid",
    "rv"."auth_role",
    "tm"."name" AS "actor",
    "rv"."table_name"
   FROM ("audit"."record_version" "rv"
     LEFT JOIN "public"."team_member" "tm" ON (("rv"."auth_uid" = "tm"."id")))
  WHERE ("rv"."table_oid" = ('"public"."page"'::"regclass")::"oid");


ALTER TABLE "public"."page_oplog" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pending_member" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "role" "public"."role_enum",
    "invited_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "activated_at" timestamp with time zone
);


ALTER TABLE "public"."pending_member" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."progress_note_attachment" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "case_id" bigint NOT NULL,
    "note_id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "size" bigint NOT NULL,
    "type" "text" NOT NULL
);


ALTER TABLE "public"."progress_note_attachment" OWNER TO "postgres";


ALTER TABLE "public"."progress_note" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."progress_note_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."remark" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "original_created_at" timestamp with time zone NOT NULL,
    "original_created_by" "text" NOT NULL,
    "original_updated_at" timestamp with time zone NOT NULL,
    "student_no" "text" NOT NULL,
    "remark_level" smallint NOT NULL,
    "category" "text" NOT NULL,
    "content" "text",
    "attachment" "text",
    "dms_json" "jsonb"
);


ALTER TABLE "public"."remark" OWNER TO "postgres";


ALTER TABLE "public"."remark" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."remark_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."reminder" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."reminder_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."role_permission" (
    "role" "public"."role_enum" NOT NULL,
    "permission" "public"."permission_enum" NOT NULL
);


ALTER TABLE "public"."role_permission" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rollover_job" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_by_name" "text" DEFAULT ''::"text" NOT NULL,
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "item_total" bigint DEFAULT '0'::bigint NOT NULL,
    "item_not_done" integer DEFAULT 0 NOT NULL,
    "item_done_ok" integer DEFAULT 0 NOT NULL,
    "item_done_error" integer DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'Ready'::"text" NOT NULL
);


ALTER TABLE "public"."rollover_job" OWNER TO "postgres";


ALTER TABLE "public"."rollover_job" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."rollover_job_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."rollover_job_item" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "job_id" bigint NOT NULL,
    "case_id" bigint NOT NULL,
    "case_status" "text" DEFAULT ''::"text" NOT NULL,
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "done_ok" boolean,
    "message" "text",
    "student_name" "text" DEFAULT ''::"text" NOT NULL,
    "student_no" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."rollover_job_item" OWNER TO "postgres";


ALTER TABLE "public"."rollover_job_item" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."rollover_job_item_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."safeguarding_note" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "updated_by_name" "text",
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "case_id" bigint
);


ALTER TABLE "public"."safeguarding_note" OWNER TO "postgres";


ALTER TABLE "public"."safeguarding_note" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."safeguarding_note_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."session_collaborator" ALTER COLUMN "session_id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."session_collaborator_session_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."session" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."session_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."specialist" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "updated_by_name" "text",
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "first_name" "text" DEFAULT ''::"text" NOT NULL,
    "last_name" "text" DEFAULT ''::"text" NOT NULL,
    "organization" "text" DEFAULT ''::"text" NOT NULL,
    "contact_number" "text" DEFAULT ''::"text" NOT NULL,
    "website" "text" DEFAULT ''::"text" NOT NULL,
    "type" "public"."specialist_enum" NOT NULL,
    "type_others" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."specialist" OWNER TO "postgres";


ALTER TABLE "public"."specialist" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."specialist_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."target" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."target_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE OR REPLACE VIEW "public"."team_member_oplog" AS
 SELECT "rv"."id",
    "rv"."record_id",
    "rv"."old_record_id",
    "rv"."op",
    "rv"."ts",
    "rv"."record",
    "rv"."old_record",
    "rv"."auth_uid",
    "rv"."auth_role",
    "tm"."name" AS "actor",
    "rv"."table_name"
   FROM ("audit"."record_version" "rv"
     LEFT JOIN "public"."team_member" "tm" ON (("rv"."auth_uid" = "tm"."id")))
  WHERE ("rv"."table_oid" = ('"public"."team_member"'::"regclass")::"oid");


ALTER TABLE "public"."team_member_oplog" OWNER TO "postgres";


ALTER TABLE ONLY "audit"."record_version" ALTER COLUMN "id" SET DEFAULT "nextval"('"audit"."record_version_id_seq"'::"regclass");



ALTER TABLE ONLY "audit"."record_version"
    ADD CONSTRAINT "record_version_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."case_gls"
    ADD CONSTRAINT "case_gls_pkey" PRIMARY KEY ("case_id", "user_id");



ALTER TABLE ONLY "public"."case_handler"
    ADD CONSTRAINT "case_handler_pkey" PRIMARY KEY ("case_id", "user_id");



ALTER TABLE ONLY "public"."case"
    ADD CONSTRAINT "case_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legacy_progress_note_job"
    ADD CONSTRAINT "legacy_progress_note_job_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legacy_progress_note"
    ADD CONSTRAINT "legacy_progress_note_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."page"
    ADD CONSTRAINT "page_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pending_member"
    ADD CONSTRAINT "pending_member_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."progress_note_attachment"
    ADD CONSTRAINT "progress_note_attachment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "progress_note_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."remark"
    ADD CONSTRAINT "remark_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reminder"
    ADD CONSTRAINT "reminder_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permission"
    ADD CONSTRAINT "role_permission_pkey" PRIMARY KEY ("role", "permission");



ALTER TABLE ONLY "public"."rollover_job_item"
    ADD CONSTRAINT "rollover_job_item_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rollover_job"
    ADD CONSTRAINT "rollover_job_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."safeguarding_note"
    ADD CONSTRAINT "safeguarding_note_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."session_collaborator"
    ADD CONSTRAINT "session_collaborator_pkey" PRIMARY KEY ("session_id", "user_id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."specialist"
    ADD CONSTRAINT "specialist_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."case"
    ADD CONSTRAINT "student_no_unique" UNIQUE ("student_no");



ALTER TABLE ONLY "public"."target"
    ADD CONSTRAINT "target_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_member"
    ADD CONSTRAINT "team_member_pkey" PRIMARY KEY ("id");



CREATE INDEX "case_id" ON "audit"."record_version" USING "hash" ((("record" ->> 'case_id'::"text"))) WHERE (("record" ->> 'case_id'::"text") IS NOT NULL);



CREATE INDEX "record_version_old_record_id" ON "audit"."record_version" USING "btree" ("old_record_id") WHERE ("old_record_id" IS NOT NULL);



CREATE INDEX "record_version_record_id" ON "audit"."record_version" USING "btree" ("record_id") WHERE ("record_id" IS NOT NULL);



CREATE INDEX "record_version_table_oid" ON "audit"."record_version" USING "btree" ("table_oid");



CREATE INDEX "record_version_ts" ON "audit"."record_version" USING "brin" ("ts");



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."case" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."case_handler" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."page" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."progress_note" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."reminder" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."target" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."team_member" FOR EACH ROW EXECUTE FUNCTION "audit"."insert_update_delete_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."case" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."case_handler" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."page" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."progress_note" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."reminder" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."session" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."target" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "audit_t" AFTER TRUNCATE ON "public"."team_member" FOR EACH STATEMENT EXECUTE FUNCTION "audit"."truncate_trigger"();



CREATE OR REPLACE TRIGGER "case_gls_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."case_gls" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_case_gls"();



CREATE OR REPLACE TRIGGER "case_handler_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."case_handler" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_handlers"();



CREATE OR REPLACE TRIGGER "case_set_created_meta" BEFORE INSERT ON "public"."case" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "case_set_created_meta" BEFORE INSERT ON "public"."specialist" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "case_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."case" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "case_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."specialist" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "page_set_created_meta" BEFORE INSERT ON "public"."page" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "page_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."page" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "progress_note_set_created_meta" BEFORE INSERT ON "public"."progress_note" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "progress_note_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."progress_note" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "reminder_set_created_meta" BEFORE INSERT ON "public"."reminder" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "reminder_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."reminder" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "safeguarding_note_set_created_meta" BEFORE INSERT ON "public"."safeguarding_note" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "safeguarding_note_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."safeguarding_note" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "session_collaborator_i_u_d" AFTER INSERT OR DELETE OR UPDATE ON "public"."session_collaborator" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_session_collaborator"();



CREATE OR REPLACE TRIGGER "session_i" AFTER INSERT ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "public"."insert_session_collaborator"();



CREATE OR REPLACE TRIGGER "session_set_created_meta" BEFORE INSERT ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "session_set_updated_meta" BEFORE INSERT OR UPDATE ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "set_main_handler_before_insert" BEFORE INSERT ON "public"."case_handler" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_main_handler"();



CREATE OR REPLACE TRIGGER "specialist_i_u" BEFORE INSERT OR UPDATE ON "public"."specialist" FOR EACH ROW EXECUTE FUNCTION "public"."update_specialist_name"();



CREATE OR REPLACE TRIGGER "target_set_created_neta_on_create" BEFORE INSERT ON "public"."target" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_created_meta"();



CREATE OR REPLACE TRIGGER "target_set_updated_meta_on_create" BEFORE INSERT ON "public"."target" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "target_set_updated_meta_on_update" BEFORE UPDATE ON "public"."target" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_updated_meta"();



CREATE OR REPLACE TRIGGER "trigger_on_session_status" BEFORE UPDATE ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_on_session_status"();



CREATE OR REPLACE TRIGGER "trigger_set_next_upcoming_session" AFTER INSERT OR DELETE OR UPDATE ON "public"."session" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_next_upcoming_session"();



CREATE OR REPLACE TRIGGER "update_reminder_is_completed" BEFORE UPDATE ON "public"."reminder" FOR EACH ROW EXECUTE FUNCTION "public"."set_completed_meta"();



CREATE OR REPLACE TRIGGER "update_student_name_trigger" BEFORE INSERT OR UPDATE ON "public"."case" FOR EACH ROW EXECUTE FUNCTION "public"."update_student_name"();



ALTER TABLE ONLY "public"."case"
    ADD CONSTRAINT "case_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."case_handler"
    ADD CONSTRAINT "case_handler_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."case_handler"
    ADD CONSTRAINT "case_handler_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."case_handler"
    ADD CONSTRAINT "case_handler_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."case"
    ADD CONSTRAINT "case_last_session_by_fkey" FOREIGN KEY ("last_session_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."case"
    ADD CONSTRAINT "case_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."legacy_progress_note"
    ADD CONSTRAINT "legacy_progress_note_entered_by_uuid_fkey" FOREIGN KEY ("entered_by_uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."page"
    ADD CONSTRAINT "page_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."page"
    ADD CONSTRAINT "page_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note_attachment"
    ADD CONSTRAINT "progress_note_attachment_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON UPDATE RESTRICT ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note_attachment"
    ADD CONSTRAINT "progress_note_attachment_note_id_fkey" FOREIGN KEY ("note_id") REFERENCES "public"."progress_note"("id") ON UPDATE RESTRICT ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "progress_note_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "progress_note_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "progress_note_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."case_gls"
    ADD CONSTRAINT "public_case_gls_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."case_gls"
    ADD CONSTRAINT "public_case_gls_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."legacy_progress_note"
    ADD CONSTRAINT "public_legacy_progress_note_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."legacy_progress_note_job"
    ADD CONSTRAINT "public_legacy_progress_note_job_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."legacy_progress_note_job"
    ADD CONSTRAINT "public_legacy_progress_note_job_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "public_progress_note_import_record_id_fkey" FOREIGN KEY ("import_record_id") REFERENCES "public"."legacy_progress_note"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."progress_note"
    ADD CONSTRAINT "public_progress_note_imported_by_fkey" FOREIGN KEY ("imported_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."rollover_job"
    ADD CONSTRAINT "public_rollover_job_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."rollover_job_item"
    ADD CONSTRAINT "public_rollover_job_item_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rollover_job_item"
    ADD CONSTRAINT "public_rollover_job_item_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."rollover_job"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_collaborator"
    ADD CONSTRAINT "public_session_collaborator_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."session"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."target"
    ADD CONSTRAINT "public_target_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reminder"
    ADD CONSTRAINT "reminder_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id");



ALTER TABLE ONLY "public"."reminder"
    ADD CONSTRAINT "reminder_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."reminder"
    ADD CONSTRAINT "reminder_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."reminder"
    ADD CONSTRAINT "reminder_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."safeguarding_note"
    ADD CONSTRAINT "safeguarding_note_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."safeguarding_note"
    ADD CONSTRAINT "safeguarding_note_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."safeguarding_note"
    ADD CONSTRAINT "safeguarding_note_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id");



ALTER TABLE ONLY "public"."session_collaborator"
    ADD CONSTRAINT "session_collaborator_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_recurrence_parent_fkey" FOREIGN KEY ("recurrence_parent") REFERENCES "public"."session"("id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_started_by_fkey" FOREIGN KEY ("started_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."specialist"
    ADD CONSTRAINT "specialist_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."specialist"
    ADD CONSTRAINT "specialist_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."target"
    ADD CONSTRAINT "target_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."target"
    ADD CONSTRAINT "target_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."team_member"
    ADD CONSTRAINT "team_member_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Insert only" ON "audit"."record_version" USING (true) WITH CHECK (false);



ALTER TABLE "audit"."record_version" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Disable delete" ON "public"."case" FOR DELETE USING (false);



CREATE POLICY "Enable all for all users" ON "public"."legacy_progress_note" TO "authenticated" USING (true);



CREATE POLICY "Enable all operations for authenticated users" ON "public"."progress_note_attachment" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Enable delete for allowed roles" ON "public"."case_gls" FOR DELETE TO "authenticated" USING ("public"."is_allowed"('case_handler:delete'::"public"."permission_enum"));



CREATE POLICY "Enable delete for allowed roles" ON "public"."case_handler" FOR DELETE TO "authenticated" USING ("public"."is_allowed"('case_handler:delete'::"public"."permission_enum"));



CREATE POLICY "Enable delete for allowed roles" ON "public"."pending_member" FOR DELETE TO "authenticated" USING ("public"."is_allowed"('pending_member:delete'::"public"."permission_enum"));



CREATE POLICY "Enable delete for creator" ON "public"."safeguarding_note" FOR DELETE TO "authenticated" USING ("public"."is_creator"("created_by"));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."page" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('page:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."progress_note" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('progress_note:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."reminder" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('reminder:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."session" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('session:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."session_collaborator" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('session:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."specialist" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('specialist:delete'::"public"."permission_enum")));



CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."target" FOR DELETE TO "authenticated" USING (("public"."is_creator"("created_by") OR "public"."is_allowed"('target:delete'::"public"."permission_enum")));



CREATE POLICY "Enable insert for all users" ON "public"."legacy_progress_note_job" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for allowed roles" ON "public"."case" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('case:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."case_gls" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('case_handler:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."case_handler" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('case_handler:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."page" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('page:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."pending_member" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('pending_member:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."progress_note" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('progress_note:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."reminder" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('reminder:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."safeguarding_note" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('safeguarding_note:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."session" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('session:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."session_collaborator" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('session:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."specialist" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('specialist:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for allowed roles" ON "public"."target" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_allowed"('target:create'::"public"."permission_enum"));



CREATE POLICY "Enable insert for service_role" ON "public"."team_member" FOR INSERT TO "service_role" WITH CHECK (true);



CREATE POLICY "Enable read access for authenticated" ON "public"."role_permission" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."case" FOR SELECT TO "authenticated" USING (
CASE
    WHEN "public"."should_apply_grade_filter"() THEN ("grade" = ANY ("public"."get_managed_grades"()))
    ELSE true
END);



CREATE POLICY "Enable select for all users" ON "public"."case_gls" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."case_handler" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."page" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."progress_note" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."reminder" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."rollover_job" FOR SELECT TO "authenticated" USING ("public"."is_allowed"('rollover_job:list'::"public"."permission_enum"));



CREATE POLICY "Enable select for all users" ON "public"."rollover_job_item" FOR SELECT TO "authenticated" USING ("public"."is_allowed"('rollover_job:list'::"public"."permission_enum"));



CREATE POLICY "Enable select for all users" ON "public"."session" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."session_collaborator" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."specialist" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for all users" ON "public"."target" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable select for allowed roles" ON "public"."pending_member" FOR SELECT TO "authenticated" USING ("public"."is_allowed"('pending_member:list'::"public"."permission_enum"));



CREATE POLICY "Enable select for allowed roles" ON "public"."remark" FOR SELECT TO "authenticated" USING ("public"."is_allowed"('remark:list'::"public"."permission_enum"));



CREATE POLICY "Enable select for authenticated users" ON "public"."team_member" FOR SELECT TO "authenticated", "service_role" USING ((("service" = false) OR ("id" = "auth"."uid"())));



CREATE POLICY "Enable select for creator and allowed roles" ON "public"."safeguarding_note" FOR SELECT TO "authenticated" USING (
CASE
    WHEN "public"."is_allowed"('safeguarding_note:read_all'::"public"."permission_enum") THEN true
    ELSE "public"."is_creator"("created_by")
END);



CREATE POLICY "Enable select for supabase_auth_admin" ON "public"."pending_member" FOR SELECT TO "supabase_auth_admin" USING (true);



CREATE POLICY "Enable select for supabase_auth_admin" ON "public"."team_member" FOR SELECT TO "supabase_auth_admin" USING (true);



CREATE POLICY "Enable supabase_auth_admin to read user roles" ON "public"."team_member" FOR SELECT TO "supabase_auth_admin" USING (true);



CREATE POLICY "Enable update for all users" ON "public"."legacy_progress_note_job" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Enable update for allowed roles" ON "public"."case_gls" FOR UPDATE TO "authenticated" USING (true) WITH CHECK ("public"."is_allowed"('case_handler:edit'::"public"."permission_enum"));



CREATE POLICY "Enable update for allowed roles" ON "public"."case_handler" FOR UPDATE TO "authenticated" USING (true) WITH CHECK ("public"."is_allowed"('case_handler:edit'::"public"."permission_enum"));



CREATE POLICY "Enable update for allowed roles" ON "public"."pending_member" FOR UPDATE TO "authenticated" USING (true) WITH CHECK ("public"."is_allowed"('pending_member:edit'::"public"."permission_enum"));



CREATE POLICY "Enable update for allowed roles" ON "public"."team_member" FOR UPDATE TO "authenticated" USING (true) WITH CHECK ("public"."is_allowed"('team_member:edit'::"public"."permission_enum"));



CREATE POLICY "Enable update for creator" ON "public"."safeguarding_note" FOR UPDATE USING (true) WITH CHECK ("public"."is_creator"("created_by"));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."case" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('case:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."page" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('page:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."progress_note" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('progress_note:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."reminder" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('reminder:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."session" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('session:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."session_collaborator" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('session:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."specialist" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('specialist:edit'::"public"."permission_enum")));



CREATE POLICY "Enable update for creator and allowed roles" ON "public"."target" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (("public"."is_creator"("created_by") OR "public"."is_allowed"('target:edit'::"public"."permission_enum")));



ALTER TABLE "public"."case" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."case_gls" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."case_handler" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."legacy_progress_note" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."legacy_progress_note_job" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."page" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pending_member" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."progress_note" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."progress_note_attachment" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."remark" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reminder" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permission" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rollover_job" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rollover_job_item" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."safeguarding_note" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."session" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."session_collaborator" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."specialist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."target" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."team_member" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."accept_legacy_progress_note"("p_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."accept_legacy_progress_note"("p_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_legacy_progress_note"("p_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_table_to_publication_if_not_exists"("schema_name" "text", "table_name" "text", "publication_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_table_to_publication_if_not_exists"("schema_name" "text", "table_name" "text", "publication_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_table_to_publication_if_not_exists"("schema_name" "text", "table_name" "text", "publication_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ban_user"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ban_user"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ban_user"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("_event" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("_event" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("_event" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."find_next_upcoming_session"("p_case_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."find_next_upcoming_session"("p_case_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_next_upcoming_session"("p_case_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_case_gls_details"("p_case_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_case_gls_details"("p_case_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_case_gls_details"("p_case_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_case_handler_details"("p_case_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_case_handler_details"("p_case_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_case_handler_details"("p_case_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_cases_by_handler"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_cases_by_handler"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_cases_by_handler"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_managed_grades"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_managed_grades"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_managed_grades"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_session_collaborator_details"("p_session_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_session_collaborator_details"("p_session_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_session_collaborator_details"("p_session_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."insert_session_collaborator"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_session_collaborator"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_session_collaborator"() TO "service_role";



GRANT ALL ON FUNCTION "public"."insert_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_allowed"("requested_permission" "public"."permission_enum") TO "anon";
GRANT ALL ON FUNCTION "public"."is_allowed"("requested_permission" "public"."permission_enum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_allowed"("requested_permission" "public"."permission_enum") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_case_handler"("p_case_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."is_case_handler"("p_case_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_case_handler"("p_case_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_creator"("created_by" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_creator"("created_by" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_creator"("created_by" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_completed_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_completed_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_completed_meta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_main_handler"("p_case_id" bigint, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."set_main_handler"("p_case_id" bigint, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_main_handler"("p_case_id" bigint, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_not_null_default_empty_string"("column_name" "text", "table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_not_null_default_empty_string"("column_name" "text", "table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_not_null_default_empty_string"("column_name" "text", "table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."should_apply_grade_filter"() TO "anon";
GRANT ALL ON FUNCTION "public"."should_apply_grade_filter"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."should_apply_grade_filter"() TO "service_role";



GRANT ALL ON FUNCTION "public"."team_member_i_u_from_sso"() TO "anon";
GRANT ALL ON FUNCTION "public"."team_member_i_u_from_sso"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."team_member_i_u_from_sso"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_on_session_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_on_session_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_on_session_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_case_gls"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_case_gls"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_case_gls"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_created_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_created_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_created_meta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_handlers"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_handlers"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_handlers"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_main_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_main_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_main_handler"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_next_upcoming_session"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_next_upcoming_session"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_next_upcoming_session"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_session_collaborator"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_session_collaborator"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_session_collaborator"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_updated_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_updated_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_updated_meta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."unban_user"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."unban_user"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unban_user"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_specialist_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_specialist_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_specialist_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_student_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_student_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_student_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user"() TO "service_role";



GRANT ALL ON TABLE "public"."case" TO "anon";
GRANT ALL ON TABLE "public"."case" TO "authenticated";
GRANT ALL ON TABLE "public"."case" TO "service_role";



GRANT ALL ON TABLE "public"."case_gls" TO "anon";
GRANT ALL ON TABLE "public"."case_gls" TO "authenticated";
GRANT ALL ON TABLE "public"."case_gls" TO "service_role";



GRANT ALL ON SEQUENCE "public"."case_gls_case_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."case_gls_case_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."case_gls_case_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."case_handler" TO "anon";
GRANT ALL ON TABLE "public"."case_handler" TO "authenticated";
GRANT ALL ON TABLE "public"."case_handler" TO "service_role";



GRANT ALL ON SEQUENCE "public"."case_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."case_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."case_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."progress_note" TO "anon";
GRANT ALL ON TABLE "public"."progress_note" TO "authenticated";
GRANT ALL ON TABLE "public"."progress_note" TO "service_role";



GRANT ALL ON TABLE "public"."reminder" TO "anon";
GRANT ALL ON TABLE "public"."reminder" TO "authenticated";
GRANT ALL ON TABLE "public"."reminder" TO "service_role";



GRANT ALL ON TABLE "public"."session" TO "anon";
GRANT ALL ON TABLE "public"."session" TO "authenticated";
GRANT ALL ON TABLE "public"."session" TO "service_role";



GRANT ALL ON TABLE "public"."target" TO "anon";
GRANT ALL ON TABLE "public"."target" TO "authenticated";
GRANT ALL ON TABLE "public"."target" TO "service_role";



GRANT ALL ON TABLE "public"."team_member" TO "anon";
GRANT ALL ON TABLE "public"."team_member" TO "authenticated";
GRANT ALL ON TABLE "public"."team_member" TO "service_role";
GRANT ALL ON TABLE "public"."team_member" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."case_oplog" TO "anon";
GRANT ALL ON TABLE "public"."case_oplog" TO "authenticated";
GRANT ALL ON TABLE "public"."case_oplog" TO "service_role";



GRANT ALL ON TABLE "public"."legacy_progress_note" TO "anon";
GRANT ALL ON TABLE "public"."legacy_progress_note" TO "authenticated";
GRANT ALL ON TABLE "public"."legacy_progress_note" TO "service_role";



GRANT ALL ON SEQUENCE "public"."legacy_progress_note_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."legacy_progress_note_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."legacy_progress_note_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."legacy_progress_note_job" TO "anon";
GRANT ALL ON TABLE "public"."legacy_progress_note_job" TO "authenticated";
GRANT ALL ON TABLE "public"."legacy_progress_note_job" TO "service_role";



GRANT ALL ON SEQUENCE "public"."legacy_progress_note_job_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."legacy_progress_note_job_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."legacy_progress_note_job_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."my_case" TO "anon";
GRANT ALL ON TABLE "public"."my_case" TO "authenticated";
GRANT ALL ON TABLE "public"."my_case" TO "service_role";



GRANT ALL ON TABLE "public"."my_progress_note" TO "anon";
GRANT ALL ON TABLE "public"."my_progress_note" TO "authenticated";
GRANT ALL ON TABLE "public"."my_progress_note" TO "service_role";



GRANT ALL ON TABLE "public"."my_reminder" TO "anon";
GRANT ALL ON TABLE "public"."my_reminder" TO "authenticated";
GRANT ALL ON TABLE "public"."my_reminder" TO "service_role";



GRANT ALL ON TABLE "public"."session_collaborator" TO "anon";
GRANT ALL ON TABLE "public"."session_collaborator" TO "authenticated";
GRANT ALL ON TABLE "public"."session_collaborator" TO "service_role";



GRANT ALL ON TABLE "public"."my_session" TO "anon";
GRANT ALL ON TABLE "public"."my_session" TO "authenticated";
GRANT ALL ON TABLE "public"."my_session" TO "service_role";



GRANT ALL ON TABLE "public"."page" TO "anon";
GRANT ALL ON TABLE "public"."page" TO "authenticated";
GRANT ALL ON TABLE "public"."page" TO "service_role";



GRANT ALL ON SEQUENCE "public"."page_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."page_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."page_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."page_oplog" TO "anon";
GRANT ALL ON TABLE "public"."page_oplog" TO "authenticated";
GRANT ALL ON TABLE "public"."page_oplog" TO "service_role";



GRANT ALL ON TABLE "public"."pending_member" TO "anon";
GRANT ALL ON TABLE "public"."pending_member" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_member" TO "service_role";
GRANT ALL ON TABLE "public"."pending_member" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."progress_note_attachment" TO "anon";
GRANT ALL ON TABLE "public"."progress_note_attachment" TO "authenticated";
GRANT ALL ON TABLE "public"."progress_note_attachment" TO "service_role";



GRANT ALL ON SEQUENCE "public"."progress_note_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."progress_note_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."progress_note_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."remark" TO "anon";
GRANT ALL ON TABLE "public"."remark" TO "authenticated";
GRANT ALL ON TABLE "public"."remark" TO "service_role";



GRANT ALL ON SEQUENCE "public"."remark_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."remark_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."remark_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."reminder_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."reminder_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."reminder_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."role_permission" TO "anon";
GRANT ALL ON TABLE "public"."role_permission" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permission" TO "service_role";



GRANT ALL ON TABLE "public"."rollover_job" TO "anon";
GRANT ALL ON TABLE "public"."rollover_job" TO "authenticated";
GRANT ALL ON TABLE "public"."rollover_job" TO "service_role";



GRANT ALL ON SEQUENCE "public"."rollover_job_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."rollover_job_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."rollover_job_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."rollover_job_item" TO "anon";
GRANT ALL ON TABLE "public"."rollover_job_item" TO "authenticated";
GRANT ALL ON TABLE "public"."rollover_job_item" TO "service_role";



GRANT ALL ON SEQUENCE "public"."rollover_job_item_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."rollover_job_item_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."rollover_job_item_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."safeguarding_note" TO "anon";
GRANT ALL ON TABLE "public"."safeguarding_note" TO "authenticated";
GRANT ALL ON TABLE "public"."safeguarding_note" TO "service_role";



GRANT ALL ON SEQUENCE "public"."safeguarding_note_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."safeguarding_note_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."safeguarding_note_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."session_collaborator_session_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."session_collaborator_session_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."session_collaborator_session_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."session_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."session_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."session_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."specialist" TO "anon";
GRANT ALL ON TABLE "public"."specialist" TO "authenticated";
GRANT ALL ON TABLE "public"."specialist" TO "service_role";



GRANT ALL ON SEQUENCE "public"."specialist_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."specialist_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."specialist_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."target_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."target_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."target_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."team_member_oplog" TO "anon";
GRANT ALL ON TABLE "public"."team_member_oplog" TO "authenticated";
GRANT ALL ON TABLE "public"."team_member_oplog" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






RESET ALL;
