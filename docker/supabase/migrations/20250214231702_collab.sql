--
-- Drop all triggers and functions for session and merge them into one trigger and function
--
DROP TRIGGER IF EXISTS "trigger_set_next_upcoming_session" ON "public"."session";

DROP FUNCTION IF EXISTS "trigger_set_next_upcoming_session";

DROP TRIGGER IF EXISTS "session_i" ON "public"."session";

DROP FUNCTION IF EXISTS "public"."insert_session_collaborator";

DROP TRIGGER IF EXISTS "trigger_on_session_status" ON "public"."session";

DROP FUNCTION IF EXISTS "public"."trigger_on_session_status";

---
---
CREATE
OR REPLACE FUNCTION public.process_session () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
DECLARE
  p_collaborators TEXT;
  p_session_id BIGINT;
  p_users UUID[];
BEGIN
  p_session_id := NEW.id;

  -- on insert, set collaborator_users to created_by
  IF TG_OP = 'INSERT' THEN
    NEW.collaborator_users := ARRAY[auth.uid()];
  END IF;

  --- On update:
  --- 1. set session started_at, started_by, started_by_name
  --- 2. set case last_session_at, last_session_by, last_session_by_name
  IF TG_OP = 'UPDATE' THEN
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
  END IF;

  -- On insert and update: set session.collaborators
  If TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    p_users := NEW.collaborator_users;
    --- find the name of all users from team_member table where id is in p_users array
    SELECT STRING_AGG(name, '|' ORDER BY name ASC) INTO p_collaborators
    FROM team_member
    WHERE id = ANY(p_users);
    --- Set session.collaborators with the new value of p_collaborators
    NEW.collaborators := COALESCE(p_collaborators, '');
  END IF;

  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.process_session () OWNER TO postgres;

CREATE TRIGGER session_i_u_d BEFORE INSERT
OR
UPDATE
OR DELETE ON public.session FOR EACH ROW
EXECUTE FUNCTION process_session ();