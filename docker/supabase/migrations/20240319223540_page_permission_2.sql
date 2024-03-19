INSERT INTO
  "role_permission"
VALUES
  ('GLL', 'page:list'),
  ('Nurse', 'page:list'),
  ('Li Ren Leadership', 'page:list'),
  ('Li Ren GLS', 'page:list'),
  ('Li Ren Contact', 'page:list'),
  ('GLL', 'page:create'),
  ('Li Ren Leadership', 'page:create'),
  ('GLL', 'page:edit'),
  ('Li Ren Leadership', 'page:edit'),
  ('GLL', 'page:delete'),
  ('Li Ren Leadership', 'page:delete');

DROP POLICY "Enable delete for creator, GLL, LR-Leadership" ON "public"."page";

DROP POLICY "Enable insert for all users" ON "public"."page";

DROP POLICY "Enable select for all users" ON "public"."page";

DROP POLICY "Enable update for creator, GLL, LR-Leadership" ON "public"."page";

CREATE POLICY "Enable insert for allowed roles" ON "public"."page" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('page:create'::permission_enum));

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."page" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('page:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."page" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('page:delete'::permission_enum)
  )
);

CREATE POLICY "Enable read access for all users" ON "public"."page" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);