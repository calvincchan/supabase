--
-- Instead of always setting the updated_by field to the current user, we will only set it if it is null.
--
CREATE
OR REPLACE FUNCTION public.trigger_set_updated_meta () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
BEGIN
  IF NEW.updated_at IS NULL THEN
    NEW.updated_at := now();
  END IF;
  IF NEW.updated_by IS NULL THEN
    NEW.updated_by := auth.uid();
  END IF;
  IF NEW.updated_by_name IS NULL THEN
    NEW.updated_by_name := get_name();
  END IF;
  RETURN NEW;
END;
$function$