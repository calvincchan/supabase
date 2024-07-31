--
-- Instead of always setting the created_by field to the current user, we will only set it if it is null.
--
CREATE
OR REPLACE FUNCTION public.trigger_set_created_meta () RETURNS TRIGGER LANGUAGE plpgsql AS $function$
BEGIN
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  IF NEW.created_by_name IS NULL THEN
    NEW.created_by_name := get_name();
  END IF;
  RETURN NEW;
END;
$function$