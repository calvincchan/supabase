--- Update safeguarding_note permissions for GLS
DELETE FROM role_permission
WHERE
  permission IN (
    'safeguarding_note:create',
    'safeguarding_note:delete',
    'safeguarding_note:edit',
    'safeguarding_note:list',
    'safeguarding_note:read_all'
  );

INSERT INTO
  role_permission (ROLE, permission)
VALUES
  ('Li Ren Leadership', 'safeguarding_note:create'),
  ('GLL', 'safeguarding_note:create'),
  ('Li Ren GLS', 'safeguarding_note:create'),
  ('Li Ren Contact', 'safeguarding_note:create'),
  ('Li Ren Leadership', 'safeguarding_note:delete'),
  ('GLL', 'safeguarding_note:delete'),
  ('Li Ren GLS', 'safeguarding_note:delete'),
  ('Li Ren Contact', 'safeguarding_note:delete'),
  ('Li Ren Leadership', 'safeguarding_note:edit'),
  ('GLL', 'safeguarding_note:edit'),
  ('Li Ren GLS', 'safeguarding_note:edit'),
  ('Li Ren Contact', 'safeguarding_note:edit'),
  ('Li Ren Leadership', 'safeguarding_note:list'),
  ('GLL', 'safeguarding_note:list'),
  ('Li Ren GLS', 'safeguarding_note:list'),
  ('Li Ren Contact', 'safeguarding_note:list'),
  ('Li Ren Leadership', 'safeguarding_note:read_all'),
  ('GLL', 'safeguarding_note:read_all'),
  ('Li Ren GLS', 'safeguarding_note:read_all');

--- Enable realtime for safeguarding_note
SELECT
  add_table_to_publication_if_not_exists (
    'public',
    'safeguarding_note',
    'supabase_realtime'
  );