DROP VIEW IF EXISTS "public"."my_case";

-- Create a new table to store the Case GLS
CREATE TABLE
  "public"."case_gls" (
    "case_id" BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "user_id" UUID NOT NULL DEFAULT gen_random_uuid ()
  );

ALTER TABLE "public"."case_gls" OWNER TO "postgres";

ALTER TABLE "public"."case_gls" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."case"
DROP COLUMN "gls_handlers";

ALTER TABLE "public"."case"
ADD COLUMN "gls" TEXT NOT NULL DEFAULT ''::TEXT;

CREATE UNIQUE INDEX case_gls_pkey ON public.case_gls USING btree (case_id, user_id);

ALTER TABLE "public"."case_gls"
ADD CONSTRAINT "case_gls_pkey" PRIMARY KEY USING INDEX "case_gls_pkey";

ALTER TABLE "public"."case_gls"
ADD CONSTRAINT "public_case_gls_case_id_fkey" FOREIGN KEY (case_id) REFERENCES "case" (id) ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."case_gls" VALIDATE CONSTRAINT "public_case_gls_case_id_fkey";

ALTER TABLE "public"."case_gls"
ADD CONSTRAINT "public_case_gls_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."case_gls" VALIDATE CONSTRAINT "public_case_gls_user_id_fkey";

CREATE
OR REPLACE FUNCTION public.get_case_gls_details (p_case_id BIGINT) RETURNS TABLE (user_id UUID, case_id BIGINT, NAME TEXT) LANGUAGE plpgsql AS $function$
BEGIN
  RETURN QUERY
  SELECT a.user_id, a.case_id, b.name
  FROM case_gls AS a
  JOIN team_member AS b ON a.user_id = b.id
  WHERE a.case_id = p_case_id
  ORDER BY b.name;
END;
$function$;

CREATE
OR REPLACE FUNCTION public.trigger_set_case_gls () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
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
$function$;

CREATE OR REPLACE VIEW
  "public"."my_case" AS
SELECT
  a.id,
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
  a.gls,
  a.student_first_name,
  a.student_last_name,
  a.background,
  a.student_other_name,
  a.case_no
FROM
  (
    "case" a
    JOIN case_handler b ON ((a.id = b.case_id))
  )
WHERE
  (b.user_id = auth.uid ());

GRANT DELETE ON TABLE "public"."case_gls" TO "anon";

GRANT INSERT ON TABLE "public"."case_gls" TO "anon";

GRANT REFERENCES ON TABLE "public"."case_gls" TO "anon";

GRANT
SELECT
  ON TABLE "public"."case_gls" TO "anon";

GRANT TRIGGER ON TABLE "public"."case_gls" TO "anon";

GRANT
TRUNCATE ON TABLE "public"."case_gls" TO "anon";

GRANT
UPDATE ON TABLE "public"."case_gls" TO "anon";

GRANT DELETE ON TABLE "public"."case_gls" TO "authenticated";

GRANT INSERT ON TABLE "public"."case_gls" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."case_gls" TO "authenticated";

GRANT
SELECT
  ON TABLE "public"."case_gls" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."case_gls" TO "authenticated";

GRANT
TRUNCATE ON TABLE "public"."case_gls" TO "authenticated";

GRANT
UPDATE ON TABLE "public"."case_gls" TO "authenticated";

GRANT DELETE ON TABLE "public"."case_gls" TO "postgres";

GRANT INSERT ON TABLE "public"."case_gls" TO "postgres";

GRANT REFERENCES ON TABLE "public"."case_gls" TO "postgres";

GRANT
SELECT
  ON TABLE "public"."case_gls" TO "postgres";

GRANT TRIGGER ON TABLE "public"."case_gls" TO "postgres";

GRANT
TRUNCATE ON TABLE "public"."case_gls" TO "postgres";

GRANT
UPDATE ON TABLE "public"."case_gls" TO "postgres";

GRANT DELETE ON TABLE "public"."case_gls" TO "service_role";

GRANT INSERT ON TABLE "public"."case_gls" TO "service_role";

GRANT REFERENCES ON TABLE "public"."case_gls" TO "service_role";

GRANT
SELECT
  ON TABLE "public"."case_gls" TO "service_role";

GRANT TRIGGER ON TABLE "public"."case_gls" TO "service_role";

GRANT
TRUNCATE ON TABLE "public"."case_gls" TO "service_role";

GRANT
UPDATE ON TABLE "public"."case_gls" TO "service_role";

CREATE POLICY "Enable delete for allowed roles" ON "public"."case_gls" AS permissive FOR DELETE TO authenticated USING (
  is_allowed ('case_handler:delete'::permission_enum)
);

CREATE POLICY "Enable insert for allowed roles" ON "public"."case_gls" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (
    is_allowed ('case_handler:create'::permission_enum)
  );

CREATE POLICY "Enable select for all users" ON "public"."case_gls" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "Enable update for allowed roles" ON "public"."case_gls" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (is_allowed ('case_handler:edit'::permission_enum));

CREATE TRIGGER case_gls_i_u_d
AFTER INSERT
OR DELETE
OR
UPDATE ON public.case_gls FOR EACH ROW
EXECUTE FUNCTION trigger_set_case_gls ();