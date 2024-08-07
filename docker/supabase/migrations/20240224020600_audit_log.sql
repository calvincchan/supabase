CREATE SCHEMA IF NOT EXISTS "audit";

CREATE TYPE "audit"."operation" AS ENUM('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE');

CREATE SEQUENCE "audit"."record_version_id_seq";

CREATE TABLE
  "audit"."record_version" (
    "id" BIGINT NOT NULL DEFAULT NEXTVAL('audit.record_version_id_seq'::regclass),
    "record_id" UUID,
    "old_record_id" UUID,
    "op" audit.operation NOT NULL,
    "ts" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "table_oid" oid NOT NULL,
    "table_schema" NAME NOT NULL,
    "table_name" NAME NOT NULL,
    "record" jsonb,
    "old_record" jsonb,
    "auth_uid" UUID DEFAULT auth.uid (),
    "auth_role" TEXT DEFAULT auth.role ()
  );

ALTER TABLE "audit"."record_version" ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "audit"."record_version_id_seq" OWNED BY "audit"."record_version"."id";

CREATE INDEX case_id ON audit.record_version USING hash (((record ->> 'case_id'::TEXT)))
WHERE
  ((record ->> 'case_id'::TEXT) IS NOT NULL);

CREATE INDEX record_version_old_record_id ON audit.record_version USING btree (old_record_id)
WHERE
  (old_record_id IS NOT NULL);

CREATE UNIQUE INDEX record_version_pkey ON audit.record_version USING btree (id);

CREATE INDEX record_version_record_id ON audit.record_version USING btree (record_id)
WHERE
  (record_id IS NOT NULL);

CREATE INDEX record_version_table_oid ON audit.record_version USING btree (table_oid);

CREATE INDEX record_version_ts ON audit.record_version USING brin (ts);

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_pkey" PRIMARY KEY USING INDEX "record_version_pkey";

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_check" CHECK (
  (
    (COALESCE(record_id, old_record_id) IS NOT NULL)
    OR (op = 'TRUNCATE'::audit.operation)
  )
) NOT VALID;

ALTER TABLE "audit"."record_version" VALIDATE CONSTRAINT "record_version_check";

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_check1" CHECK (
  (
    (
      op = ANY (
        ARRAY[
          'INSERT'::audit.operation,
          'UPDATE'::audit.operation
        ]
      )
    ) = (record_id IS NOT NULL)
  )
) NOT VALID;

ALTER TABLE "audit"."record_version" VALIDATE CONSTRAINT "record_version_check1";

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_check2" CHECK (
  (
    (
      op = ANY (
        ARRAY[
          'INSERT'::audit.operation,
          'UPDATE'::audit.operation
        ]
      )
    ) = (record IS NOT NULL)
  )
) NOT VALID;

ALTER TABLE "audit"."record_version" VALIDATE CONSTRAINT "record_version_check2";

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_check3" CHECK (
  (
    (
      op = ANY (
        ARRAY[
          'UPDATE'::audit.operation,
          'DELETE'::audit.operation
        ]
      )
    ) = (old_record_id IS NOT NULL)
  )
) NOT VALID;

ALTER TABLE "audit"."record_version" VALIDATE CONSTRAINT "record_version_check3";

ALTER TABLE "audit"."record_version"
ADD CONSTRAINT "record_version_check4" CHECK (
  (
    (
      op = ANY (
        ARRAY[
          'UPDATE'::audit.operation,
          'DELETE'::audit.operation
        ]
      )
    ) = (old_record IS NOT NULL)
  )
) NOT VALID;

ALTER TABLE "audit"."record_version" VALIDATE CONSTRAINT "record_version_check4";

CREATE
OR REPLACE FUNCTION audit.disable_tracking (regclass) RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path TO '' AS $function$
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
$function$;

CREATE
OR REPLACE FUNCTION audit.enable_tracking (regclass) RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path TO '' AS $function$
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
$function$;

CREATE
OR REPLACE FUNCTION audit.insert_update_delete_trigger () RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $function$
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
$function$;

CREATE
OR REPLACE FUNCTION audit.primary_key_columns (entity_oid oid) RETURNS TEXT[] LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path TO '' AS $function$
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
$function$;

CREATE
OR REPLACE FUNCTION audit.to_record_id (entity_oid oid, pkey_cols TEXT[], rec jsonb) RETURNS UUID LANGUAGE SQL STABLE AS $function$
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
$function$;

CREATE
OR REPLACE FUNCTION audit.truncate_trigger () RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path TO '' AS $function$
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
$function$;

CREATE POLICY "Insert only" ON "audit"."record_version" AS permissive FOR ALL TO public USING (TRUE)
WITH
  CHECK (FALSE);

-- Create triggers on auth.users
CREATE TRIGGER users_i_u
AFTER INSERT
OR
UPDATE ON auth.users FOR EACH ROW
EXECUTE FUNCTION public.team_member_i_u_from_sso ();

-- CREATE audit related views at last
CREATE OR REPLACE VIEW
  "public"."page_oplog" AS
SELECT
  rv.id,
  rv.record_id,
  rv.old_record_id,
  rv.op,
  rv.ts,
  rv.record,
  rv.old_record,
  rv.auth_uid,
  rv.auth_role,
  tm.name AS actor,
  rv.table_name
FROM
  (
    audit.record_version rv
    LEFT JOIN team_member tm ON ((rv.auth_uid = tm.id))
  )
WHERE
  (rv.table_oid = ('page'::regclass)::oid);

CREATE OR REPLACE VIEW
  "public"."case_oplog" AS
SELECT
  rv.id,
  rv.record_id,
  rv.old_record_id,
  rv.op,
  rv.ts,
  rv.record,
  rv.old_record,
  rv.auth_uid,
  rv.auth_role,
  tm.name AS actor,
  rv.table_name
FROM
  (
    audit.record_version rv
    LEFT JOIN team_member tm ON ((rv.auth_uid = tm.id))
  )
WHERE
  (
    rv.table_oid = ANY (
      ARRAY[
        ('"case"'::regclass)::oid,
        ('progress_note'::regclass)::oid,
        ('reminder'::regclass)::oid,
        ('session'::regclass)::oid,
        ('case_handler'::regclass)::oid,
        ('target'::regclass)::oid
      ]
    )
  );

CREATE OR REPLACE VIEW
  "public"."team_member_oplog" AS
SELECT
  rv.id,
  rv.record_id,
  rv.old_record_id,
  rv.op,
  rv.ts,
  rv.record,
  rv.old_record,
  rv.auth_uid,
  rv.auth_role,
  tm.name AS actor,
  rv.table_name
FROM
  (
    audit.record_version rv
    LEFT JOIN team_member tm ON ((rv.auth_uid = tm.id))
  )
WHERE
  (rv.table_oid = ('team_member'::regclass)::oid);

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public."case" FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public."case" FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.case_handler FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.case_handler FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.page FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.page FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.progress_note FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.progress_note FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.reminder FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.reminder FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.session FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.session FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.target FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.target FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();

CREATE TRIGGER audit_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.team_member FOR EACH ROW
EXECUTE FUNCTION audit.insert_update_delete_trigger ();

CREATE TRIGGER audit_t
AFTER
TRUNCATE ON public.team_member FOR EACH STATEMENT
EXECUTE FUNCTION audit.truncate_trigger ();