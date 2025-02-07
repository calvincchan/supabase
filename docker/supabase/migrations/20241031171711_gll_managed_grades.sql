-- Add managed_grades column to team_member table
ALTER TABLE "public"."team_member"
ADD COLUMN "managed_grades" grade_enum[] NOT NULL DEFAULT '{}'::grade_enum[];

-- function to get managed_grades (grade_enum[]) from team_member table
CREATE
OR REPLACE FUNCTION public.get_managed_grades () RETURNS grade_enum[] LANGUAGE plpgsql AS $function$
DECLARE
  v_grades grade_enum[];
BEGIN
  SELECT managed_grades INTO v_grades
   FROM team_member WHERE id = auth.uid();
  RETURN v_grades;
END;
$function$;

-- function to decide if the current user should apply filter
CREATE
OR REPLACE FUNCTION public.should_apply_grade_filter () RETURNS BOOLEAN LANGUAGE plpgsql AS $function$
BEGIN
  RETURN (auth.jwt() ->> 'user_role') = 'GLL';
END;
$function$;

ALTER FUNCTION "public"."get_managed_grades" () OWNER TO "postgres";

ALTER FUNCTION "public"."should_apply_grade_filter" () OWNER TO "postgres";

-- add a policy to filter rows based on the role and managed grades
ALTER POLICY "Enable select for all users" ON "public"."case" TO "authenticated" USING (
  CASE
    WHEN should_apply_grade_filter () THEN (grade = ANY (get_managed_grades ()))
    ELSE TRUE
  END
);