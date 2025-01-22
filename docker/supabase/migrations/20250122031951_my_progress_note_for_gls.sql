--- update my_progress_note view to include case_gls
CREATE OR REPLACE VIEW
  public.my_progress_note AS
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
  progress_note a
WHERE
  (
    a.case_id IN (
      SELECT
        case_handler.case_id
      FROM
        case_handler
      WHERE
        case_handler.user_id = uid ()
    )
  )
  OR (
    a.case_id IN (
      SELECT
        case_gls.case_id
      FROM
        case_gls
      WHERE
        case_gls.user_id = uid ()
    )
  );

--- update my_reminder view to include case_gls
CREATE OR REPLACE VIEW
  public.my_reminder AS
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
  reminder a
WHERE
  (
    a.case_id IN (
      SELECT
        case_handler.case_id
      FROM
        case_handler
      WHERE
        case_handler.user_id = uid ()
    )
  )
  OR (
    a.case_id IN (
      SELECT
        case_gls.case_id
      FROM
        case_gls
      WHERE
        case_gls.user_id = uid ()
    )
  );