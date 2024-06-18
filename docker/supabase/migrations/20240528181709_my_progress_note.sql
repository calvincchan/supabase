CREATE OR REPLACE VIEW
  "public"."my_progress_note" AS
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
  a.tags,
  a.attachments
FROM
  "progress_note" a
  JOIN case_handler b ON a.case_id = b.case_id
WHERE
  b.user_id = auth.uid ();

ALTER TABLE "public"."my_progress_note" OWNER TO "postgres";