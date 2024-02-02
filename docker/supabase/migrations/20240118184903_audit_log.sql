create schema if not exists "audit";

ALTER SCHEMA "audit" OWNER TO "postgres";

create type "audit"."operation" as enum ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE');

create sequence "audit"."record_version_id_seq";

create table "audit"."record_version" (
    "id" bigint not null default nextval('audit.record_version_id_seq'::regclass),
    "record_id" uuid,
    "old_record_id" uuid,
    "op" audit.operation not null,
    "ts" timestamp with time zone not null default now(),
    "table_oid" oid not null,
    "table_schema" name not null,
    "table_name" name not null,
    "record" jsonb,
    "old_record" jsonb,
    "auth_uid" uuid default auth.uid(),
    "auth_role" text default auth.role()
);


alter table "audit"."record_version" enable row level security;

alter sequence "audit"."record_version_id_seq" owned by "audit"."record_version"."id";

CREATE INDEX case_id ON audit.record_version USING hash (((record ->> 'case_id'::text))) WHERE ((record ->> 'case_id'::text) IS NOT NULL);

CREATE INDEX record_version_old_record_id ON audit.record_version USING btree (old_record_id) WHERE (old_record_id IS NOT NULL);

CREATE UNIQUE INDEX record_version_pkey ON audit.record_version USING btree (id);

CREATE INDEX record_version_record_id ON audit.record_version USING btree (record_id) WHERE (record_id IS NOT NULL);

CREATE INDEX record_version_table_oid ON audit.record_version USING btree (table_oid);

CREATE INDEX record_version_ts ON audit.record_version USING brin (ts);

alter table "audit"."record_version" add constraint "record_version_pkey" PRIMARY KEY using index "record_version_pkey";

alter table "audit"."record_version" add constraint "record_version_check" CHECK (((COALESCE(record_id, old_record_id) IS NOT NULL) OR (op = 'TRUNCATE'::audit.operation))) not valid;

alter table "audit"."record_version" validate constraint "record_version_check";

alter table "audit"."record_version" add constraint "record_version_check1" CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation])) = (record_id IS NOT NULL))) not valid;

alter table "audit"."record_version" validate constraint "record_version_check1";

alter table "audit"."record_version" add constraint "record_version_check2" CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation])) = (record IS NOT NULL))) not valid;

alter table "audit"."record_version" validate constraint "record_version_check2";

alter table "audit"."record_version" add constraint "record_version_check3" CHECK (((op = ANY (ARRAY['UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (old_record_id IS NOT NULL))) not valid;

alter table "audit"."record_version" validate constraint "record_version_check3";

alter table "audit"."record_version" add constraint "record_version_check4" CHECK (((op = ANY (ARRAY['UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (old_record IS NOT NULL))) not valid;

alter table "audit"."record_version" validate constraint "record_version_check4";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION audit.disable_tracking(regclass)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION audit.enable_tracking(regclass)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION audit.insert_update_delete_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION audit.primary_key_columns(entity_oid oid)
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION audit.to_record_id(entity_oid oid, pkey_cols text[], rec jsonb)
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION audit.truncate_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

create policy "Insert only"
on "audit"."record_version"
as permissive
for all
to public
using (true)
with check (false);

create or replace view "public"."case_oplog" as  SELECT rv.id,
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
   FROM (audit.record_version rv
     LEFT JOIN team_member tm ON ((rv.auth_uid = tm.id)))
  WHERE (rv.table_oid = ANY (ARRAY[('"case"'::regclass)::oid, ('progress_note'::regclass)::oid, ('reminder'::regclass)::oid, ('session'::regclass)::oid, ('case_handler'::regclass)::oid, ('target'::regclass)::oid]));


create or replace view "public"."team_member_oplog" as  SELECT rv.id,
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
   FROM (audit.record_version rv
     LEFT JOIN team_member tm ON ((rv.auth_uid = tm.id)))
  WHERE (rv.table_oid = ('team_member'::regclass)::oid);


CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public."case" FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public."case" FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.case_handler FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.case_handler FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.profile FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.profile FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.progress_note FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.progress_note FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.reminder FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.reminder FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.session FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.session FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.target FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.target FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.team_member FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.team_member FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();
