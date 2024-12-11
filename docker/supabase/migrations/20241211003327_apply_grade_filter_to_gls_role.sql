-- HAS_UNTRACKABLE_DEPENDENCIES: Dependencies, i.e. other functions used in the function body, of non-sql functions cannot be tracked. As a result, we cannot guarantee that function dependencies are ordered properly relative to this statement. For adds, this means you need to ensure that all functions this function depends on are created/altered before this statement.
CREATE
OR REPLACE FUNCTION public.should_apply_grade_filter () RETURNS BOOLEAN LANGUAGE plpgsql AS $function$
BEGIN
  RETURN (auth.jwt() ->> 'user_role') IN ('GLL', 'Li Ren GLS');
END;
$function$;