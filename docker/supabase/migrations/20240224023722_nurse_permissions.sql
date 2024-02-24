DROP POLICY "Enable update for creator and LR-Leadership, LR-GLS" ON "public"."case";

CREATE POLICY "Enable update for creator and LR-Leadership, LR-GLS, Nurse" ON "public"."case" AS permissive FOR
UPDATE TO authenticated USING (TRUE)
WITH
  CHECK (
    (
      (auth.uid () = created_by)
      OR (
        get_role () = ANY (
          ARRAY[
            'Li Ren GLS'::role_enum,
            'Li Ren Leadership'::role_enum,
            'Nurse'::role_enum
          ]
        )
      )
    )
  );