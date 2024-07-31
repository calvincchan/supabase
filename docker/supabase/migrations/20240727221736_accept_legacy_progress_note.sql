CREATE
OR REPLACE FUNCTION public.accept_legacy_progress_note (p_id BIGINT) RETURNS void LANGUAGE plpgsql AS $function$
DECLARE
  legacy_record legacy_progress_note%ROWTYPE;
  v_progress_note_id BIGINT;
  v_name TEXT;
BEGIN
  -- Fetch the record from legacy_progress_note
  SELECT * INTO legacy_record FROM legacy_progress_note WHERE id = p_id;

  -- Check if the record exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Record with id % does not exist in legacy_progress_note', p_id;
  END IF;

  -- get name of entered_by, if not found that use legacy_record.entered_by
  SELECT name INTO v_name FROM team_member WHERE id = legacy_record.entered_by_uuid;
  IF NOT FOUND THEN
    v_name := legacy_record.entered_by;
  END IF;

  -- Insert the record into progress_note, and get the inserted id
  INSERT INTO progress_note (case_id, content, tags, created_at, created_by, created_by_name, updated_at, updated_by, updated_by_name, imported_at, imported_by, imported_by_name, import_record_id)
  VALUES (legacy_record.case_id, legacy_record.content, legacy_record.tags, legacy_record.entered_at_date, legacy_record.entered_by_uuid, v_name, legacy_record.entered_at_date, legacy_record.entered_by_uuid, v_name, NOW(), auth.uid(), get_name(), p_id)
  RETURNING id INTO v_progress_note_id;

  -- Update the legacy record to status 'Accepted', set accepted_at and accepted_by
  UPDATE legacy_progress_note
  SET status = 'Accepted', accepted_at = NOW(), accepted_by = auth.uid(), accepted_by_name = get_name()
  WHERE id = p_id;
END;
$function$