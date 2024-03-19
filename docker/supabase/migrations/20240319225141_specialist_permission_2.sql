INSERT INTO
  "role_permission"
VALUES
  ('GLL', 'specialist:list'),
  ('Nurse', 'specialist:list'),
  ('Li Ren Leadership', 'specialist:list'),
  ('Li Ren GLS', 'specialist:list'),
  ('Li Ren Contact', 'specialist:list'),
  ('Li Ren Leadership', 'specialist:create'),
  ('Li Ren Contact', 'specialist:create'),
  ('Li Ren GLS', 'specialist:create'),
  ('Li Ren Leadership', 'specialist:edit'),
  ('Li Ren GLS', 'specialist:edit'),
  ('Li Ren Contact', 'specialist:edit'),
  ('Li Ren Leadership', 'specialist:delete'),
  ('Li Ren GLS', 'specialist:delete'),
  ('Li Ren Contact', 'specialist:delete');

DROP POLICY "Enable select for all users" ON "public"."specialist";

DROP POLICY "Enable insert for all users" ON "public"."specialist";

DROP POLICY "Enable update for creator, LR-GLS, LR-Leadership" ON "public"."specialist";

DROP POLICY "Enable delete for creator, LR-GLS, LR-Leadership" ON "public"."specialist";

CREATE POLICY "Enable insert for allowed roles" ON "public"."specialist" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('specialist:create'::permission_enum));

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."specialist" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('specialist:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."specialist" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('specialist:delete'::permission_enum)
  )
);

CREATE POLICY "Enable select for all users" ON "public"."specialist" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);