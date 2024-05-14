-- Combine old triggers into one trigger
DROP TRIGGER IF EXISTS "set_handlers_after_delete" ON "public"."case_handler";

DROP TRIGGER IF EXISTS "set_handlers_after_insert" ON "public"."case_handler";

DROP TRIGGER IF EXISTS "set_handlers_after_update" ON "public"."case_handler";

-- remove gls handlers
CREATE
OR REPLACE FUNCTION public.trigger_set_handlers () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
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
$function$;

CREATE TRIGGER case_handler_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.case_handler FOR EACH ROW
EXECUTE FUNCTION trigger_set_handlers ();