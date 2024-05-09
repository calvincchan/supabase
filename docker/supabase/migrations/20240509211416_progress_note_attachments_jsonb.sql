ALTER TABLE "public"."progress_note"
ADD COLUMN "attachments" jsonb NOT NULL DEFAULT '[]'::jsonb;

-- for each row in progress_note_attachments table, insert into progress_note.attachments
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT * FROM progress_note_attachment
  LOOP
    UPDATE progress_note
    SET attachments = attachments || jsonb_build_object(
      'id', r.id,
      'name', r.name,
      'size', r.size,
      'type', r.type,
      'created_at', r.created_at
    )
    WHERE id = r.note_id;
  END LOOP;
END $$;