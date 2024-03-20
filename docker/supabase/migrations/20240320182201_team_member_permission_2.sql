INSERT INTO
  "role_permission"
VALUES
  ('IT Admin', 'team_member:list'),
  ('Li Ren Leadership', 'team_member:list'),
  ('IT Admin', 'team_member:create'),
  ('Li Ren Leadership', 'team_member:create'),
  ('IT Admin', 'team_member:edit'),
  ('Li Ren Leadership', 'team_member:edit');

DROP POLICY "Enable read for authenticated users" ON "public"."team_member";

CREATE POLICY "Enable select for authenticated users" ON "public"."team_member" AS permissive FOR
SELECT
  TO authenticated,
  service_role USING (TRUE);

DROP POLICY "Enable update for IT-Admin and LR-Leadership" ON "public"."team_member";

CREATE POLICY "Enable update for allowed roles" ON "public"."team_member" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (is_allowed ('team_member:edit'::permission_enum));