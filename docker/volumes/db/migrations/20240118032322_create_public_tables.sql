-- migrate:up

--
-- Name: find_next_upcoming_session(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_next_upcoming_session(p_case_id bigint) RETURNS timestamp with time zone
    LANGUAGE plpgsql
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


--
-- Name: get_case_handler_details(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_case_handler_details(p_case_id bigint) RETURNS TABLE(user_id uuid, case_id bigint, name text, is_main_handler boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.user_id, a.case_id, b.name, a.is_main_handler
  FROM case_handler AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id
  ORDER BY b.name;END;
$$;


--
-- Name: get_cases_by_handler(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_cases_by_handler(p_user_id uuid) RETURNS TABLE(id bigint, student_name text, student_no text, next_session_at timestamp with time zone)
    LANGUAGE plpgsql
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


--
-- Name: get_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_name() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_name TEXT;
BEGIN
  SELECT name INTO v_name FROM team_member WHERE id = auth.uid();
  RETURN v_name;
END;
$$;


--
-- Name: get_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_role() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_role CHAR(1);
BEGIN
  SELECT role INTO v_role FROM team_member WHERE auth.uid() = p_user_id;
  RETURN v_role;
END;
$$;


--
-- Name: insert_into_target(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_into_target() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO "target" ("id")
    VALUES (NEW."id");
    RETURN NEW;
END;
$$;


--
-- Name: insert_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.team_member (id, email, name, role)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'role');
  RETURN NEW;
END;
$$;


--
-- Name: is_case_handler(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_case_handler(p_case_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (
    SELECT EXISTS(
      SELECT 1 FROM case_handler WHERE case_id = p_case_id AND user_id = auth.uid()
    )
  );
END;
$$;


--
-- Name: is_creator(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_creator() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN created_by = auth.uid();
END;
$$;


--
-- Name: is_manager(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_manager() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (
    SELECT EXISTS(
      SELECT 1 FROM team_member WHERE id = auth.uid() AND role = 'A'
    )
  );
END;
$$;


--
-- Name: set_completed_meta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_completed_meta() RETURNS trigger
    LANGUAGE plpgsql
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


--
-- Name: set_main_handler(bigint, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_main_handler(p_case_id bigint, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
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


--
-- Name: trigger_on_session_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_on_session_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.status = 'U' AND NEW.status = 'I' THEN
    UPDATE "case" SET last_session_at = NOW(), last_session_by = auth.uid(), last_session_by_name = get_name() WHERE id = NEW.case_id;
    NEW.started_at = NOW();
    NEW.started_by = auth.uid();
    SELECT get_name() INTO NEW.started_by_name;
  END IF;
  IF OLD.status = 'I' AND NEW.status = 'X' THEN
    UPDATE "case" SET last_session_at = NOW(), last_session_by = auth.uid(), last_session_by_name = get_name() WHERE id = NEW.case_id;
    NEW.completed_at = NOW();
    NEW.completed_by = auth.uid();
    SELECT get_name() INTO NEW.completed_by_name;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: trigger_set_created_meta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_created_meta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.created_by := auth.uid();
  SELECT get_name() INTO NEW.created_by_name;
  RETURN NEW;
END;
$$;


--
-- Name: trigger_set_handlers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_handlers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  handlers_string TEXT;
  p_case_id BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    p_case_id := OLD.case_id;
  ELSE
    p_case_id := NEW.case_id;
  END IF;

  SELECT STRING_AGG(b.name, '|' ORDER BY a.is_main_handler DESC, b.name ASC) INTO handlers_string
  FROM case_handler AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id;

  UPDATE "case" SET handlers = COALESCE(handlers_string, '') WHERE id = p_case_id;

  RETURN NEW;
END;
$$;


--
-- Name: trigger_set_main_handler(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_main_handler() RETURNS trigger
    LANGUAGE plpgsql
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


--
-- Name: trigger_set_next_upcoming_session(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_next_upcoming_session() RETURNS trigger
    LANGUAGE plpgsql
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


--
-- Name: trigger_set_updated_meta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_updated_meta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  NEW.updated_by := auth.uid();
  SELECT get_name() INTO NEW.updated_by_name;
  RETURN NEW;
END;
$$;


--
-- Name: update_student_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_student_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        NEW."student_name" = TRIM(BOTH ' ' FROM UPPER(NEW."student_last_name") || ' ' || NEW."student_first_name");
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: update_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: case; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."case" (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_name text DEFAULT ''::text NOT NULL,
    student_no text,
    updated_at timestamp with time zone,
    updated_by uuid,
    is_archived boolean,
    archived_at timestamp with time zone,
    archived_by uuid,
    case_status character(1) DEFAULT 'I'::bpchar,
    updated_by_name text,
    grade character varying(10),
    homeroom character varying(100),
    created_by uuid,
    created_by_name text,
    tier character(1) DEFAULT '1'::bpchar,
    last_session_at timestamp with time zone,
    next_session_at timestamp with time zone,
    last_session_by uuid,
    last_session_by_name text,
    student_first_name text DEFAULT ''::text NOT NULL,
    student_last_name text DEFAULT ''::text NOT NULL,
    background text,
    student_other_name text DEFAULT ''::text NOT NULL,
    gender character(1),
    dob date,
    email text,
    parent_email text,
    mother_name text,
    mother_phone text,
    mother_email text,
    father_name text,
    father_phone text,
    father_email text,
    handlers text DEFAULT ''::text NOT NULL,
    CONSTRAINT case_case_status_check CHECK ((case_status = ANY (ARRAY['I'::bpchar, 'C'::bpchar, 'N'::bpchar, 'A'::bpchar, 'R'::bpchar, 'X'::bpchar])))
);


--
-- Name: case_handler; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_handler (
    case_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_id uuid NOT NULL,
    is_main_handler boolean DEFAULT false NOT NULL,
    created_by uuid
);


--
-- Name: TABLE case_handler; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.case_handler IS 'One User to many Case relationship';


--
-- Name: case_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public."case" ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.case_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: progress_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.progress_note (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    case_id bigint,
    content text,
    created_by_name text,
    updated_by_name text,
    tags bpchar[]
);


--
-- Name: reminder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reminder (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    created_by_name text,
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    updated_by_name text,
    content text,
    due_date timestamp with time zone,
    is_completed boolean DEFAULT false NOT NULL,
    completed_at timestamp with time zone,
    completed_by uuid,
    completed_by_name text,
    case_id bigint
);


--
-- Name: session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session (
    id bigint NOT NULL,
    case_id bigint,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    created_by_name text,
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    updated_by_name text,
    started_at timestamp with time zone,
    started_by uuid,
    started_by_name text,
    completed_at timestamp with time zone,
    completed_by uuid,
    completed_by_name text,
    content text DEFAULT ''::text NOT NULL,
    language character(1) DEFAULT '''E'''::bpchar NOT NULL,
    status character(1) DEFAULT 'U'::bpchar NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    recurrence_rule text DEFAULT ''::text NOT NULL,
    time_frame character(1) DEFAULT ''::bpchar NOT NULL,
    time_frame_until timestamp with time zone,
    mode character(1) DEFAULT ''::bpchar NOT NULL,
    learning character(1) DEFAULT ''::bpchar NOT NULL,
    seb character(1) DEFAULT ''::bpchar NOT NULL,
    counselling character(1) DEFAULT ''::bpchar NOT NULL,
    cca character(1) DEFAULT ''::bpchar NOT NULL,
    haoxue character(1) DEFAULT ''::bpchar NOT NULL,
    non_case character(1) DEFAULT ''::bpchar NOT NULL,
    parent_session character(1) DEFAULT ''::bpchar NOT NULL,
    parent_session_note text,
    recurrence_parent bigint
);


--
-- Name: target; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.target (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    created_by_name text,
    updated_at timestamp with time zone,
    updated_by uuid,
    updated_by_name text,
    targets text[] DEFAULT '{}'::text[] NOT NULL
);


--
-- Name: team_member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_member (
    id uuid NOT NULL,
    name text NOT NULL,
    role character(1) DEFAULT NULL::bpchar,
    email text,
    last_sign_in_at timestamp with time zone
);


--
-- Name: TABLE team_member; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.team_member IS 'Users who can operate the console.';


--
-- Name: my_case; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.my_case AS
 SELECT a.id,
    a.created_at,
    a.student_name,
    a.student_no,
    a.updated_at,
    a.updated_by,
    a.is_archived,
    a.archived_at,
    a.archived_by,
    a.case_status,
    a.updated_by_name,
    a.grade,
    a.homeroom,
    a.created_by,
    a.created_by_name,
    a.tier,
    a.last_session_at,
    a.next_session_at,
    a.last_session_by,
    a.last_session_by_name,
    a.handlers,
    a.student_first_name,
    a.student_last_name,
    a.background,
    a.student_other_name
   FROM (public."case" a
     JOIN public.case_handler b ON ((a.id = b.case_id)))
  WHERE (b.user_id = auth.uid());


--
-- Name: profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile (
    case_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    date_of_birth date,
    chinese_name text,
    gender character(1),
    CONSTRAINT profile_gender_check CHECK ((gender = ANY (ARRAY['M'::bpchar, 'F'::bpchar, 'U'::bpchar])))
);


--
-- Name: TABLE profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.profile IS 'Additional data about a student.';


--
-- Name: progress_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.progress_note ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.progress_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reminder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.reminder ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.reminder_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.session ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: target_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.target ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.target_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: case_handler case_handler_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_handler
    ADD CONSTRAINT case_handler_pkey PRIMARY KEY (case_id, user_id);


--
-- Name: case case_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."case"
    ADD CONSTRAINT case_pkey PRIMARY KEY (id);


--
-- Name: profile profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (case_id);


--
-- Name: progress_note progress_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progress_note
    ADD CONSTRAINT progress_note_pkey PRIMARY KEY (id);


--
-- Name: reminder reminder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder
    ADD CONSTRAINT reminder_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: target target_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target
    ADD CONSTRAINT target_pkey PRIMARY KEY (id);


--
-- Name: team_member team_member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_pkey PRIMARY KEY (id);


--
-- Name: case case_set_created_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER case_set_created_meta BEFORE INSERT ON public."case" FOR EACH ROW EXECUTE FUNCTION public.trigger_set_created_meta();


--
-- Name: case case_set_updated_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER case_set_updated_meta BEFORE INSERT OR UPDATE ON public."case" FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: case insert_target; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_target AFTER INSERT ON public."case" FOR EACH ROW EXECUTE FUNCTION public.insert_into_target();


--
-- Name: progress_note progress_note_set_created_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER progress_note_set_created_meta BEFORE INSERT ON public.progress_note FOR EACH ROW EXECUTE FUNCTION public.trigger_set_created_meta();


--
-- Name: progress_note progress_note_set_updated_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER progress_note_set_updated_meta BEFORE INSERT OR UPDATE ON public.progress_note FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: reminder reminder_set_created_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reminder_set_created_meta BEFORE INSERT ON public.reminder FOR EACH ROW EXECUTE FUNCTION public.trigger_set_created_meta();


--
-- Name: reminder reminder_set_updated_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reminder_set_updated_meta BEFORE INSERT OR UPDATE ON public.reminder FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: session session_set_created_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER session_set_created_meta BEFORE INSERT ON public.session FOR EACH ROW EXECUTE FUNCTION public.trigger_set_created_meta();


--
-- Name: session session_set_updated_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER session_set_updated_meta BEFORE INSERT OR UPDATE ON public.session FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: case_handler set_handlers_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_handlers_after_delete AFTER DELETE ON public.case_handler FOR EACH ROW EXECUTE FUNCTION public.trigger_set_handlers();


--
-- Name: case_handler set_handlers_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_handlers_after_insert AFTER INSERT ON public.case_handler FOR EACH ROW EXECUTE FUNCTION public.trigger_set_handlers();


--
-- Name: case_handler set_handlers_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_handlers_after_update AFTER UPDATE ON public.case_handler FOR EACH ROW EXECUTE FUNCTION public.trigger_set_handlers();


--
-- Name: case_handler set_main_handler_before_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_main_handler_before_insert BEFORE INSERT ON public.case_handler FOR EACH ROW EXECUTE FUNCTION public.trigger_set_main_handler();


--
-- Name: target target_set_created_neta_on_create; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER target_set_created_neta_on_create BEFORE INSERT ON public.target FOR EACH ROW EXECUTE FUNCTION public.trigger_set_created_meta();


--
-- Name: target target_set_updated_meta_on_create; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER target_set_updated_meta_on_create BEFORE INSERT ON public.target FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: target target_set_updated_meta_on_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER target_set_updated_meta_on_update BEFORE UPDATE ON public.target FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_meta();


--
-- Name: session trigger_on_session_status; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_on_session_status BEFORE UPDATE ON public.session FOR EACH ROW EXECUTE FUNCTION public.trigger_on_session_status();


--
-- Name: session trigger_set_next_upcoming_session; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_set_next_upcoming_session AFTER INSERT OR DELETE OR UPDATE ON public.session FOR EACH ROW EXECUTE FUNCTION public.trigger_set_next_upcoming_session();


--
-- Name: reminder update_reminder_is_completed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_reminder_is_completed BEFORE UPDATE ON public.reminder FOR EACH ROW EXECUTE FUNCTION public.set_completed_meta();


--
-- Name: case update_student_name_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_student_name_trigger BEFORE INSERT OR UPDATE ON public."case" FOR EACH ROW EXECUTE FUNCTION public.update_student_name();


--
-- Name: case case_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."case"
    ADD CONSTRAINT case_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: case_handler case_handler_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_handler
    ADD CONSTRAINT case_handler_case_id_fkey FOREIGN KEY (case_id) REFERENCES public."case"(id) ON DELETE CASCADE;


--
-- Name: case_handler case_handler_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_handler
    ADD CONSTRAINT case_handler_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: case_handler case_handler_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_handler
    ADD CONSTRAINT case_handler_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: case case_last_session_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."case"
    ADD CONSTRAINT case_last_session_by_fkey FOREIGN KEY (last_session_by) REFERENCES auth.users(id);


--
-- Name: case case_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."case"
    ADD CONSTRAINT case_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: profile profile_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_case_id_fkey FOREIGN KEY (case_id) REFERENCES public."case"(id) ON DELETE CASCADE;


--
-- Name: progress_note progress_note_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progress_note
    ADD CONSTRAINT progress_note_case_id_fkey FOREIGN KEY (case_id) REFERENCES public."case"(id) ON DELETE CASCADE;


--
-- Name: progress_note progress_note_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progress_note
    ADD CONSTRAINT progress_note_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: progress_note progress_note_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progress_note
    ADD CONSTRAINT progress_note_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: reminder reminder_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder
    ADD CONSTRAINT reminder_case_id_fkey FOREIGN KEY (case_id) REFERENCES public."case"(id);


--
-- Name: reminder reminder_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder
    ADD CONSTRAINT reminder_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES auth.users(id);


--
-- Name: reminder reminder_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder
    ADD CONSTRAINT reminder_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: reminder reminder_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder
    ADD CONSTRAINT reminder_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: session session_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_case_id_fkey FOREIGN KEY (case_id) REFERENCES public."case"(id);


--
-- Name: session session_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES auth.users(id);


--
-- Name: session session_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: session session_recurrence_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_recurrence_parent_fkey FOREIGN KEY (recurrence_parent) REFERENCES public.session(id);


--
-- Name: session session_started_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_started_by_fkey FOREIGN KEY (started_by) REFERENCES auth.users(id);


--
-- Name: session session_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: target target_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target
    ADD CONSTRAINT target_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: target target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target
    ADD CONSTRAINT target_id_fkey FOREIGN KEY (id) REFERENCES public."case"(id) ON DELETE CASCADE;


--
-- Name: target target_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target
    ADD CONSTRAINT target_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: team_member team_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;



--
-- Name: case Disable delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Disable delete" ON public."case" FOR DELETE USING (false);


--
-- Name: profile Enable all operations for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable all operations for all users" ON public.profile TO authenticated USING (true) WITH CHECK (true);


--
-- Name: target Enable all operations for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable all operations for authenticated users" ON public.target TO authenticated USING (true) WITH CHECK (true);


--
-- Name: progress_note Enable delete for creator and managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for creator and managers" ON public.progress_note FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: reminder Enable delete for creator and managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for creator and managers" ON public.reminder FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: session Enable delete for creator and managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for creator and managers" ON public.session FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: case Enable insert for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for all users" ON public."case" FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: progress_note Enable insert for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for all users" ON public.progress_note FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: reminder Enable insert for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for all users" ON public.reminder FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: session Enable insert for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for all users" ON public.session FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: team_member Enable insert for service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for service_role" ON public.team_member FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: case_handler Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.case_handler TO authenticated USING (true) WITH CHECK (true);


--
-- Name: team_member Enable read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read for authenticated users" ON public.team_member FOR SELECT TO authenticated, anon, service_role USING (true);


--
-- Name: case Enable select for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable select for all users" ON public."case" FOR SELECT TO authenticated USING (true);


--
-- Name: progress_note Enable select for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable select for all users" ON public.progress_note FOR SELECT TO authenticated USING (true);


--
-- Name: reminder Enable select for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable select for all users" ON public.reminder FOR SELECT TO authenticated USING (true);


--
-- Name: session Enable select for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable select for all users" ON public.session FOR SELECT TO authenticated USING (true);


--
-- Name: team_member Enable update for authenticated manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for authenticated manager" ON public.team_member FOR UPDATE TO authenticated USING (true) WITH CHECK ((public.is_manager() OR (auth.uid() = id)));


--
-- Name: case Enable update for creator and managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for creator and managers" ON public."case" FOR UPDATE TO authenticated USING (true) WITH CHECK (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: progress_note Enable update for creator or managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for creator or managers" ON public.progress_note FOR UPDATE TO authenticated USING (true) WITH CHECK (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: reminder Enable update for creator or managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for creator or managers" ON public.reminder FOR UPDATE TO authenticated USING (true) WITH CHECK (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: session Enable update for creator or managers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for creator or managers" ON public.session FOR UPDATE USING (true) WITH CHECK (((auth.uid() = created_by) OR public.is_manager()));


--
-- Name: case; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public."case" ENABLE ROW LEVEL SECURITY;

--
-- Name: case_handler; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.case_handler ENABLE ROW LEVEL SECURITY;

--
-- Name: profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;

--
-- Name: progress_note; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.progress_note ENABLE ROW LEVEL SECURITY;

--
-- Name: reminder; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reminder ENABLE ROW LEVEL SECURITY;

--
-- Name: session; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session ENABLE ROW LEVEL SECURITY;

--
-- Name: target; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.target ENABLE ROW LEVEL SECURITY;

--
-- Name: team_member; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.team_member ENABLE ROW LEVEL SECURITY;



-- migrate:down

