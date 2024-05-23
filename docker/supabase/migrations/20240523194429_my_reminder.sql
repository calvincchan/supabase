CREATE OR REPLACE VIEW
  "public"."my_reminder" AS
SELECT
  a.id,
  a.case_id,
  a.created_at,
  a.created_by,
  a.created_by_name,
  a.updated_at,
  a.updated_by,
  a.updated_by_name,
  a.content,
  a.due_date,
  a.start_date,
  a.end_date
FROM
  "reminder" a
  JOIN case_handler b ON a.case_id = b.case_id
WHERE
  b.user_id = auth.uid ();

ALTER TABLE "public"."my_reminder" OWNER TO "postgres";