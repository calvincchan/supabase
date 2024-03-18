INSERT INTO
  "public"."role_permission" ("role", "permission")
VALUES
  ('IT Admin', 'dashboard:list'),
  ('IT Admin', 'case:list'),
  ('IT Admin', 'my_case:list'),
  ('GLL', 'safeguarding_note:read_all'),
  ('GLL', 'dashboard:list'),
  ('GLL', 'case:list'),
  ('GLL', 'my_case:list'),
  ('GLL', 'progress_note:list'),
  ('GLL', 'progress_note:create'),
  ('GLL', 'progress_note:edit'),
  ('GLL', 'progress_note:delete'),
  ('GLL', 'reminder:list'),
  ('GLL', 'reminder:create'),
  ('GLL', 'reminder:edit'),
  ('GLL', 'reminder:delete'),
  ('GLL', 'session:list'),
  ('GLL', 'session:create'),
  ('GLL', 'session:edit'),
  ('GLL', 'session:delete'),
  ('GLL', 'target:list'),
  ('GLL', 'target:create'),
  ('GLL', 'target:edit'),
  ('GLL', 'target:delete'),
  ('GLL', 'remark:list'),
  ('GLL', 'safeguarding_note:list'),
  ('Nurse', 'dashboard:list'),
  ('Nurse', 'case:list'),
  ('Nurse', 'case:edit'),
  ('Nurse', 'my_case:list'),
  ('Nurse', 'progress_note:list'),
  ('Nurse', 'progress_note:create'),
  ('Nurse', 'reminder:list'),
  ('Nurse', 'reminder:create'),
  ('Nurse', 'session:list'),
  ('Nurse', 'session:create'),
  ('Nurse', 'target:list'),
  ('Nurse', 'target:create'),
  ('Nurse', 'remark:list'),
  ('Li Ren Leadership', 'safeguarding_note:read_all'),
  ('Li Ren Leadership', 'dashboard:list'),
  ('Li Ren Leadership', 'case:list'),
  ('Li Ren Leadership', 'case:create'),
  ('Li Ren Leadership', 'case:edit'),
  ('Li Ren Leadership', 'case:audit'),
  ('Li Ren Leadership', 'my_case:list'),
  ('Li Ren Leadership', 'progress_note:list'),
  ('Li Ren Leadership', 'progress_note:create'),
  ('Li Ren Leadership', 'progress_note:edit'),
  ('Li Ren Leadership', 'progress_note:delete'),
  ('Li Ren Leadership', 'reminder:list'),
  ('Li Ren Leadership', 'reminder:create'),
  ('Li Ren Leadership', 'reminder:edit'),
  ('Li Ren Leadership', 'reminder:delete'),
  ('Li Ren Leadership', 'session:list'),
  ('Li Ren Leadership', 'session:create'),
  ('Li Ren Leadership', 'session:edit'),
  ('Li Ren Leadership', 'session:delete'),
  ('Li Ren Leadership', 'target:list'),
  ('Li Ren Leadership', 'target:create'),
  ('Li Ren Leadership', 'target:edit'),
  ('Li Ren Leadership', 'target:delete'),
  ('Li Ren Leadership', 'remark:list'),
  ('Li Ren Leadership', 'safeguarding_note:list'),
  ('Li Ren GLS', 'dashboard:list'),
  ('Li Ren GLS', 'case:list'),
  ('Li Ren GLS', 'case:create'),
  ('Li Ren GLS', 'case:edit'),
  ('Li Ren GLS', 'case:audit'),
  ('Li Ren GLS', 'my_case:list'),
  ('Li Ren GLS', 'progress_note:list'),
  ('Li Ren GLS', 'progress_note:create'),
  ('Li Ren GLS', 'reminder:list'),
  ('Li Ren GLS', 'reminder:create'),
  ('Li Ren GLS', 'session:list'),
  ('Li Ren GLS', 'session:create'),
  ('Li Ren GLS', 'target:list'),
  ('Li Ren GLS', 'target:create'),
  ('Li Ren GLS', 'remark:list'),
  ('Li Ren GLS', 'safeguarding_note:list'),
  ('Li Ren GLS', 'safeguarding_note:create'),
  ('Li Ren Contact', 'dashboard:list'),
  ('Li Ren Contact', 'case:list'),
  ('Li Ren Contact', 'case:create'),
  ('Li Ren Contact', 'my_case:list'),
  ('Li Ren Contact', 'progress_note:list'),
  ('Li Ren Contact', 'progress_note:create'),
  ('Li Ren Contact', 'reminder:list'),
  ('Li Ren Contact', 'reminder:create'),
  ('Li Ren Contact', 'session:list'),
  ('Li Ren Contact', 'session:create'),
  ('Li Ren Contact', 'target:list'),
  ('Li Ren Contact', 'target:create'),
  ('Li Ren Contact', 'remark:list'),
  ('Li Ren Contact', 'safeguarding_note:list'),
  ('Li Ren Contact', 'safeguarding_note:create');

DROP POLICY "Enable insert for LR-Leadership, LR-GLS, LR-Contact" ON "public"."case";

DROP POLICY "Enable update for creator and LR-Leadership, LR-GLS, Nurse" ON "public"."case";

DROP POLICY "Enable delete for creator, GLL, LR-Leadership" ON "public"."progress_note";

DROP POLICY "Enable insert for GLL, Nurse, LR-Leadership, LR-GLS, LR-Contact" ON "public"."progress_note";

DROP POLICY "Enable update for creator, GLL, LR-Leadership" ON "public"."progress_note";

DROP POLICY "Enable read access for all users" ON "public"."remark";

DROP POLICY "Enable delete for creator, GLL, LR-Leadership" ON "public"."reminder";

DROP POLICY "Enable insert for GLL, Nurse, LR-Leadership, LR-GLS, LR-Contact" ON "public"."reminder";

DROP POLICY "Enable select for all users" ON "public"."reminder";

DROP POLICY "Enable update for creator, GLL, LR-Leadership" ON "public"."reminder";

DROP POLICY "Enable insert for LR-Contact, LR-GLS" ON "public"."safeguarding_note";

DROP POLICY "Enable select for creator, GLL, LR-Leadership" ON "public"."safeguarding_note";

DROP POLICY "Enable delete for creator, GLL, LR-Leadership" ON "public"."session";

DROP POLICY "Enable insert for GLL, Nurse, LR-Leadership, LR-GLS, LR-Contact" ON "public"."session";

DROP POLICY "Enable update for creator, GLL, LR-Leadership" ON "public"."session";

DROP POLICY "Enable delete for creator, GLL, LR-Leadership" ON "public"."target";

DROP POLICY "Enable insert for GLL, Nurse, LR-Leadership, LR-GLS, LR-Contact" ON "public"."target";

DROP POLICY "Enable update for creator, GLL, LR-Leadership" ON "public"."target";

DROP POLICY "Enable delete for creator" ON "public"."safeguarding_note";

DROP POLICY "Enable update for creator" ON "public"."safeguarding_note";

CREATE POLICY "Enable insert for allowed roles" ON "public"."case" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('case:create'::permission_enum));

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."case" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('case:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."progress_note" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('progress_note:delete'::permission_enum)
  )
);

CREATE POLICY "Enable insert for allowed roles" ON "public"."progress_note" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (
    is_allowed ('progress_note:create'::permission_enum)
  );

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."progress_note" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('progress_note:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable read for allowed roles" ON "public"."remark" AS permissive FOR
SELECT
  TO authenticated USING (is_allowed ('remark:list'::permission_enum));

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."reminder" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('reminder:delete'::permission_enum)
  )
);

CREATE POLICY "Enable insert for allowed roles" ON "public"."reminder" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('reminder:create'::permission_enum));

CREATE POLICY "Enable read access for all users" ON "public"."reminder" AS permissive FOR
SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."reminder" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('reminder:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable insert for allowed roles" ON "public"."safeguarding_note" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (
    is_allowed ('safeguarding_note:create'::permission_enum)
  );

CREATE POLICY "Enable select for creator and allowed roles" ON "public"."safeguarding_note" AS permissive FOR
SELECT
  TO authenticated USING (
    CASE
      WHEN is_allowed ('safeguarding_note:read_all'::permission_enum) THEN TRUE
      ELSE is_creator (created_by)
    END
  );

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."session" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('session:delete'::permission_enum)
  )
);

CREATE POLICY "Enable insert for allowed roles" ON "public"."session" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('session:create'::permission_enum));

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."session" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('session:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable delete for creator and allowed roles" ON "public"."target" AS permissive FOR DELETE TO authenticated USING (
  (
    is_creator (created_by)
    OR is_allowed ('target:delete'::permission_enum)
  )
);

CREATE POLICY "Enable insert for allowed roles" ON "public"."target" AS permissive FOR INSERT TO authenticated
WITH
  CHECK (is_allowed ('target:create'::permission_enum));

CREATE POLICY "Enable update for creator and allowed roles" ON "public"."target" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      is_creator (created_by)
      OR is_allowed ('target:edit'::permission_enum)
    )
  );

CREATE POLICY "Enable delete for creator" ON "public"."safeguarding_note" AS permissive FOR DELETE TO authenticated USING (is_creator (created_by));

CREATE POLICY "Enable update for creator" ON "public"."safeguarding_note" AS permissive FOR
UPDATE TO public USING (TRUE)
WITH
  CHECK (is_creator (created_by));