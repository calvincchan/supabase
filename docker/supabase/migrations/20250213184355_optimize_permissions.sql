--
-- revoke permissions from IT Admin role
--
DELETE FROM public.role_permission
WHERE
  ROLE = 'IT Admin'
  AND permission IN ('case:list', 'my_case:list', 'dashboard:list');

DROP POLICY "Enable select for all users" ON "public"."case";

-- fix case list permission
CREATE POLICY "Enable select for allowed roles" ON "public"."case" FOR
SELECT
  TO "authenticated" USING (is_allowed ('case:list'::permission_enum));