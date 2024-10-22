CREATE
OR REPLACE FUNCTION public.trigger_set_created_meta () RETURNS TRIGGER LANGUAGE plpgsql AS $function$BEGIN
  NEW.created_by := auth.uid();
  NEW.created_by_name := get_name();
  RETURN NEW;
END;$function$;

CREATE
OR REPLACE FUNCTION public.trigger_set_updated_meta () RETURNS TRIGGER LANGUAGE plpgsql AS $function$BEGIN
  NEW.updated_at := now();
  NEW.updated_by := auth.uid();
  NEW.updated_by_name := get_name();
  RETURN NEW;
END;$function$;