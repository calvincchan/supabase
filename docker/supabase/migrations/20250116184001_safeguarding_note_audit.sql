--- Enable audit tracking for safeguarding_note table
SELECT
  audit.enable_tracking ('public.safeguarding_note');

--- Create safeguarding_note_oplog view:
--- 1. show all records if user has safeguarding_note:read_all permission
--- 2. show only user's records if user does not have safeguarding_note:read_all permission
CREATE OR REPLACE VIEW
  public.safeguarding_note_oplog AS
SELECT
  rv.id,
  rv.record_id,
  rv.old_record_id,
  rv.op,
  rv.ts,
  rv.record,
  rv.old_record,
  rv.auth_uid,
  rv.auth_role,
  tm.name AS actor,
  rv.table_name
FROM
  audit.record_version rv
  LEFT JOIN team_member tm ON rv.auth_uid = tm.id
WHERE
  rv.table_oid = 'safeguarding_note'::regclass::oid
  AND (
    is_allowed ('safeguarding_note:read_all')
    OR rv.auth_uid = auth.uid ()
  );