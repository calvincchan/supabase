DROP VIEW IF EXISTS "public"."my_case";

CREATE OR REPLACE VIEW
  "public"."my_case" AS
SELECT
  a.id,
  a.created_at,
  a.student_name,
  a.student_no,
  a.updated_at,
  a.updated_by,
  a.is_archived,
  a.archived_at,
  a.archived_by,
  a.case_status,
  a.updated_by_name,
  a.grade,
  a.homeroom,
  a.created_by,
  a.created_by_name,
  a.tier,
  a.core_needs,
  a.last_session_at,
  a.next_session_at,
  a.last_session_by,
  a.last_session_by_name,
  a.handlers,
  a.gls,
  a.student_first_name,
  a.student_last_name,
  a.background,
  a.student_other_name,
  a.student_preferred_name,
  a.case_no
FROM
  (
    "case" a
    JOIN case_handler b ON ((a.id = b.case_id))
  )
WHERE
  (b.user_id = auth.uid ());