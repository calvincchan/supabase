-- Purpose: Enable realtime on the tables if not already enabled
CREATE
OR REPLACE FUNCTION add_table_to_publication_if_not_exists (
  schema_name TEXT,
  table_name TEXT,
  publication_name TEXT
) RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = publication_name
        AND tablename = table_name
        AND schemaname = schema_name
    ) THEN
        EXECUTE format('ALTER PUBLICATION %I ADD TABLE %I.%I', publication_name, schema_name, table_name);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Enable realtime on the tables
SELECT
  add_table_to_publication_if_not_exists ('public', 'case', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists ('public', 'progress_note', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists ('public', 'reminder', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists ('public', 'session', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists ('public', 'target', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists (
    'public',
    'progress_note_attachment',
    'supabase_realtime'
  );

SELECT
  add_table_to_publication_if_not_exists ('public', 'team_member', 'supabase_realtime');

SELECT
  add_table_to_publication_if_not_exists ('public', 'rollover_job', 'supabase_realtime');