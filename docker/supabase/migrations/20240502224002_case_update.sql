ALTER TABLE "public"."case"
DROP CONSTRAINT "case_case_status_check";

ALTER TABLE "public"."case"
ADD COLUMN "student_preferred_name" TEXT NOT NULL DEFAULT ''::TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "gls_handlers" TEXT NOT NULL DEFAULT ''::TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "information_release_form_attachments" jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE "public"."case"
ADD COLUMN "parent_consent_form_attachments" jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE "public"."case"
ADD COLUMN "termination_form_attachments" jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE "public"."session"
ADD COLUMN "time_frame_until" TIMESTAMP WITH TIME ZONE;

-- Update the case handlers and gls_handlers columns
CREATE
OR REPLACE FUNCTION public.trigger_set_handlers () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
DECLARE
  handler_string TEXT;
  gls_string TEXT;
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

  -- gls handlers only
  SELECT STRING_AGG(b.name, '|' ORDER BY b.name ASC) INTO gls_string
  FROM case_handler AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id AND b."role" = 'Li Ren GLS'::role_enum;

  UPDATE "case" SET handlers = COALESCE(handler_string, ''), gls_handlers = COALESCE(gls_string, '') WHERE id = p_case_id;

  RETURN NEW;
END;
$function$;