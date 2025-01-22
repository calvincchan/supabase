--- Enable select for all users regardless of grade filter
DROP POLICY "Enable select for all users" ON "public"."case";

CREATE POLICY "Enable select for all users" ON "public"."case" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);