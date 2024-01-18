-- migrate:up


--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;

--
-- Name: operation; Type: TYPE; Schema: audit; Owner: -
--

CREATE TYPE audit.operation AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE'
);

--
-- Name: disable_tracking(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.disable_tracking(regclass) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
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


--
-- Name: enable_tracking(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.enable_tracking(regclass) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
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


--
-- Name: insert_update_delete_trigger(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.insert_update_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: primary_key_columns(oid); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.primary_key_columns(entity_oid oid) RETURNS text[]
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
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


--
-- Name: to_record_id(oid, text[], jsonb); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.to_record_id(entity_oid oid, pkey_cols text[], rec jsonb) RETURNS uuid
    LANGUAGE sql STABLE
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


--
-- Name: truncate_trigger(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.truncate_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
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

--
-- Name: record_version; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.record_version (
    id bigint NOT NULL,
    record_id uuid,
    old_record_id uuid,
    op audit.operation NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL,
    table_oid oid NOT NULL,
    table_schema name NOT NULL,
    table_name name NOT NULL,
    record jsonb,
    old_record jsonb,
    auth_uid uuid DEFAULT auth.uid(),
    auth_role text DEFAULT auth.role(),
    CONSTRAINT record_version_check CHECK (((COALESCE(record_id, old_record_id) IS NOT NULL) OR (op = 'TRUNCATE'::audit.operation))),
    CONSTRAINT record_version_check1 CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation])) = (record_id IS NOT NULL))),
    CONSTRAINT record_version_check2 CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation])) = (record IS NOT NULL))),
    CONSTRAINT record_version_check3 CHECK (((op = ANY (ARRAY['UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (old_record_id IS NOT NULL))),
    CONSTRAINT record_version_check4 CHECK (((op = ANY (ARRAY['UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (old_record IS NOT NULL)))
);


--
-- Name: record_version_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.record_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: record_version_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.record_version_id_seq OWNED BY audit.record_version.id;

--
-- Name: record_version id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.record_version ALTER COLUMN id SET DEFAULT nextval('audit.record_version_id_seq'::regclass);


--
-- Name: record_version record_version_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.record_version
    ADD CONSTRAINT record_version_pkey PRIMARY KEY (id);


--
-- Name: case_id; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX case_id ON audit.record_version USING hash (((record ->> 'case_id'::text))) WHERE ((record ->> 'case_id'::text) IS NOT NULL);


--
-- Name: record_version_old_record_id; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX record_version_old_record_id ON audit.record_version USING btree (old_record_id) WHERE (old_record_id IS NOT NULL);


--
-- Name: record_version_record_id; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX record_version_record_id ON audit.record_version USING btree (record_id) WHERE (record_id IS NOT NULL);


--
-- Name: record_version_table_oid; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX record_version_table_oid ON audit.record_version USING btree (table_oid);


--
-- Name: record_version_ts; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX record_version_ts ON audit.record_version USING brin (ts);


--
-- Name: record_version Insert only; Type: POLICY; Schema: audit; Owner: -
--

CREATE POLICY "Insert only" ON audit.record_version USING (true) WITH CHECK (false);


--
-- Name: record_version; Type: ROW SECURITY; Schema: audit; Owner: -
--

ALTER TABLE audit.record_version ENABLE ROW LEVEL SECURITY;


--
-- Name: case audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public."case" FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: case_handler audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.case_handler FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: profile audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.profile FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: progress_note audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.progress_note FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: reminder audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.reminder FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: session audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.session FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: target audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.target FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: team_member audit_i_u_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_u_d AFTER INSERT OR DELETE OR UPDATE ON public.team_member FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger();


--
-- Name: case audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public."case" FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: case_handler audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.case_handler FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: profile audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.profile FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: progress_note audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.progress_note FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: reminder audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.reminder FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: session audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.session FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: target audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.target FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: team_member audit_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_t AFTER TRUNCATE ON public.team_member FOR EACH STATEMENT EXECUTE FUNCTION audit.truncate_trigger();


--
-- Name: case_oplog; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.case_oplog AS
 SELECT rv.id,
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
     LEFT JOIN public.team_member tm ON ((rv.auth_uid = tm.id)))
  WHERE (rv.table_oid = ANY (ARRAY[('public."case"'::regclass)::oid, ('public.progress_note'::regclass)::oid, ('public.reminder'::regclass)::oid, ('public.session'::regclass)::oid, ('public.case_handler'::regclass)::oid, ('public.target'::regclass)::oid]));

--
-- Name: team_member_oplog; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.team_member_oplog AS
 SELECT rv.id,
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
     LEFT JOIN public.team_member tm ON ((rv.auth_uid = tm.id)))
  WHERE (rv.table_oid = ('public.team_member'::regclass)::oid);


-- migrate:down

DROP SCHEMA audit;
DROP VIEW public.case_oplog;
DROP VIEW public.team_member_oplog;