-- handle "U" -> "X" status change
CREATE
OR REPLACE FUNCTION public.trigger_on_session_status () RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $function$
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
$function$;

-- note: SECURITY DEFINER is added to allow the update of the "case" table
CREATE
OR REPLACE FUNCTION public.trigger_set_next_upcoming_session () RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $function$
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
$function$;