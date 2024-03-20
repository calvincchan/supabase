DROP POLICY "Enable read access for all users" ON "public"."case_handler";

DROP POLICY "Enable read access for all users" ON "public"."page";

DROP POLICY "Enable read for allowed roles" ON "public"."remark";

DROP POLICY "Enable read access for all users" ON "public"."reminder";

CREATE POLICY "Enable select for all users" ON "public"."case_handler" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "Enable select for all users" ON "public"."page" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "Enable select for allowed roles" ON "public"."remark" AS permissive FOR
SELECT
  TO authenticated USING (is_allowed ('remark:list'::permission_enum));

CREATE POLICY "Enable select for all users" ON "public"."reminder" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);