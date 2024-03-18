ALTER TABLE "public"."remark"
ALTER COLUMN "content"
DROP NOT NULL;

CREATE POLICY "Enable read access for all users" ON "public"."remark" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);