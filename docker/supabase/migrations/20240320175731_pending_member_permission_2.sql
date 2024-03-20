INSERT INTO
  "role_permission"
VALUES
  ('IT Admin', 'pending_member:list'),
  ('Li Ren Leadership', 'pending_member:list'),
  ('IT Admin', 'pending_member:create'),
  ('Li Ren Leadership', 'pending_member:create'),
  ('IT Admin', 'pending_member:edit'),
  ('Li Ren Leadership', 'pending_member:edit'),
  ('IT Admin', 'pending_member:delete'),
  ('Li Ren Leadership', 'pending_member:delete');

DROP POLICY "Enable all operations for IT-Admin and LR-Leadership" ON "public"."pending_member";

CREATE POLICY "Enable insert for allowed roles" ON "public"."pending_member" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (
    is_allowed ('pending_member:create'::permission_enum)
  );

CREATE POLICY "Enable update for allowed roles" ON "public"."pending_member" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    is_allowed ('pending_member:edit'::permission_enum)
  );

CREATE POLICY "Enable delete for allowed roles" ON "public"."pending_member" AS permissive FOR DELETE TO authenticated USING (
  is_allowed ('pending_member:delete'::permission_enum)
);

CREATE POLICY "Enable select for allowed roles" ON "public"."pending_member" AS permissive FOR
SELECT
  TO authenticated USING (
    is_allowed ('pending_member:list'::permission_enum)
  );