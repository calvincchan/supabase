CREATE TABLE
  "public"."pending_member" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" CHARACTER(1) DEFAULT 'B'::bpchar,
    "invited_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "activated_at" TIMESTAMP WITH TIME ZONE
  );

ALTER TABLE "public"."pending_member" OWNER TO "postgres";

ALTER TABLE "public"."pending_member" ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX pending_member_pkey ON public.pending_member USING btree (id);

ALTER TABLE "public"."pending_member"
ADD CONSTRAINT "pending_member_pkey" PRIMARY KEY USING INDEX "pending_member_pkey";

SET
  check_function_bodies = OFF;

CREATE
OR REPLACE FUNCTION public.team_member_i_u_from_sso () RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE
    new_name text;
    new_role character(1);
BEGIN
    IF NEW.is_sso_user = TRUE THEN
        -- The first sso user will be a manager
        IF NOT EXISTS (SELECT 1 FROM public.team_member LIMIT 1) THEN
            INSERT INTO public.team_member(id, name, email, role, last_sign_in_at)
            VALUES (NEW.id, '(new sso user)', NEW.email, 'A', NEW.last_sign_in_at);
        ELSE
            -- Check if the user is already a team member
            IF EXISTS (SELECT 1 FROM public.team_member WHERE email = NEW.email) THEN
                -- Update the last_sign_in_at
                UPDATE public.team_member
                SET last_sign_in_at = NEW.last_sign_in_at
                WHERE email = NEW.email;
            ELSE
                -- Check if the user is invited
                IF EXISTS (SELECT 1 FROM public.pending_member WHERE id = NEW.email) THEN
                    -- Insert the user into team_member and update the invite status
                    SELECT name, role INTO new_name, new_role FROM public.pending_member WHERE id = NEW.email;
                    INSERT INTO public.team_member(id, name, email, role, last_sign_in_at)
                    VALUES (NEW.id, new_name, NEW.email, new_role, NEW.last_sign_in_at);
                    UPDATE public.pending_member SET activated_at = NOW() WHERE id = NEW.email;
                ELSE
                    -- throw error
                    RAISE EXCEPTION 'SSO user % is not invited', NEW.email;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$function$;

GRANT DELETE ON TABLE "public"."pending_member" TO "anon";

GRANT INSERT ON TABLE "public"."pending_member" TO "anon";

GRANT REFERENCES ON TABLE "public"."pending_member" TO "anon";

GRANT
SELECT
  ON TABLE "public"."pending_member" TO "anon";

GRANT TRIGGER ON TABLE "public"."pending_member" TO "anon";

GRANT
TRUNCATE ON TABLE "public"."pending_member" TO "anon";

GRANT
UPDATE ON TABLE "public"."pending_member" TO "anon";

GRANT DELETE ON TABLE "public"."pending_member" TO "authenticated";

GRANT INSERT ON TABLE "public"."pending_member" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."pending_member" TO "authenticated";

GRANT
SELECT
  ON TABLE "public"."pending_member" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."pending_member" TO "authenticated";

GRANT
TRUNCATE ON TABLE "public"."pending_member" TO "authenticated";

GRANT
UPDATE ON TABLE "public"."pending_member" TO "authenticated";

GRANT DELETE ON TABLE "public"."pending_member" TO "postgres";

GRANT INSERT ON TABLE "public"."pending_member" TO "postgres";

GRANT REFERENCES ON TABLE "public"."pending_member" TO "postgres";

GRANT
SELECT
  ON TABLE "public"."pending_member" TO "postgres";

GRANT TRIGGER ON TABLE "public"."pending_member" TO "postgres";

GRANT
TRUNCATE ON TABLE "public"."pending_member" TO "postgres";

GRANT
UPDATE ON TABLE "public"."pending_member" TO "postgres";

GRANT DELETE ON TABLE "public"."pending_member" TO "service_role";

GRANT INSERT ON TABLE "public"."pending_member" TO "service_role";

GRANT REFERENCES ON TABLE "public"."pending_member" TO "service_role";

GRANT
SELECT
  ON TABLE "public"."pending_member" TO "service_role";

GRANT TRIGGER ON TABLE "public"."pending_member" TO "service_role";

GRANT
TRUNCATE ON TABLE "public"."pending_member" TO "service_role";

GRANT
UPDATE ON TABLE "public"."pending_member" TO "service_role";

CREATE POLICY "Enable all operations for managers" ON "public"."pending_member" AS permissive FOR ALL TO authenticated USING (is_manager ())
WITH
  CHECK (TRUE);

-- Create triggers on auth.users
CREATE TRIGGER users_i_u
AFTER INSERT
OR
UPDATE ON auth.users FOR EACH ROW
EXECUTE FUNCTION public.team_member_i_u_from_sso ();