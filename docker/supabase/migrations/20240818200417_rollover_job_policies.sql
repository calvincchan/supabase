CREATE POLICY "Enable select for all users" ON "public"."rollover_job" AS permissive FOR
SELECT
  TO authenticated USING (is_allowed ('rollover_job:list'::permission_enum));

CREATE POLICY "Enable select for all users" ON "public"."rollover_job_item" AS permissive FOR
SELECT
  TO authenticated USING (is_allowed ('rollover_job:list'::permission_enum));