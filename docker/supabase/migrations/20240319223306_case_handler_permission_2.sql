INSERT INTO
  "role_permission"
VALUES
  ('Li Ren Leadership', 'case_handler:edit'),
  ('Li Ren GLS', 'case_handler:edit'),
  ('Li Ren Leadership', 'case_handler:create'),
  ('Li Ren GLS', 'case_handler:create'),
  ('Li Ren Leadership', 'case_handler:delete'),
  ('Li Ren GLS', 'case_handler:delete');

CREATE POLICY "Enable insert for allowed roles" ON "public"."case_handler" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (
    is_allowed ('case_handler:create'::permission_enum)
  );

CREATE POLICY "Enable update for allowed roles" ON "public"."case_handler" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (is_allowed ('case_handler:edit'::permission_enum));

CREATE POLICY "Enable delete for allowed roles" ON "public"."case_handler" AS permissive FOR DELETE TO authenticated USING (
  is_allowed ('case_handler:delete'::permission_enum)
);

DROP POLICY "Enable full access for all users" ON "public"."case_handler";

CREATE POLICY "Enable read access for all users" ON "public"."case_handler" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);