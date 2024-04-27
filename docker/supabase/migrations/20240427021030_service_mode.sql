DROP POLICY "Enable select for authenticated users" ON "public"."team_member";

DROP FUNCTION IF EXISTS "public"."is_manager" ();

ALTER TABLE "public"."team_member"
ADD COLUMN "service" BOOLEAN NOT NULL DEFAULT FALSE;

CREATE POLICY "Enable select for authenticated users" ON "public"."team_member" AS permissive FOR
SELECT
  TO authenticated,
  service_role USING (
    (
      (service = FALSE)
      OR (id = auth.uid ())
    )
  );