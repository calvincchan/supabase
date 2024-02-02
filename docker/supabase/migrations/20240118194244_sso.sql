create table "public"."pending_member" (
    "id" text not null,
    "name" text not null,
    "role" character(1) default 'B'::bpchar,
    "invited_at" timestamp with time zone not null default now(),
    "activated_at" timestamp with time zone
);

ALTER TABLE "public"."pending_member" OWNER TO "postgres";

alter table "public"."pending_member" enable row level security;

CREATE UNIQUE INDEX pending_member_pkey ON public.pending_member USING btree (id);

alter table "public"."pending_member" add constraint "pending_member_pkey" PRIMARY KEY using index "pending_member_pkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.team_member_i_u_from_sso()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

grant delete on table "public"."pending_member" to "anon";

grant insert on table "public"."pending_member" to "anon";

grant references on table "public"."pending_member" to "anon";

grant select on table "public"."pending_member" to "anon";

grant trigger on table "public"."pending_member" to "anon";

grant truncate on table "public"."pending_member" to "anon";

grant update on table "public"."pending_member" to "anon";

grant delete on table "public"."pending_member" to "authenticated";

grant insert on table "public"."pending_member" to "authenticated";

grant references on table "public"."pending_member" to "authenticated";

grant select on table "public"."pending_member" to "authenticated";

grant trigger on table "public"."pending_member" to "authenticated";

grant truncate on table "public"."pending_member" to "authenticated";

grant update on table "public"."pending_member" to "authenticated";

grant delete on table "public"."pending_member" to "postgres";

grant insert on table "public"."pending_member" to "postgres";

grant references on table "public"."pending_member" to "postgres";

grant select on table "public"."pending_member" to "postgres";

grant trigger on table "public"."pending_member" to "postgres";

grant truncate on table "public"."pending_member" to "postgres";

grant update on table "public"."pending_member" to "postgres";

grant delete on table "public"."pending_member" to "service_role";

grant insert on table "public"."pending_member" to "service_role";

grant references on table "public"."pending_member" to "service_role";

grant select on table "public"."pending_member" to "service_role";

grant trigger on table "public"."pending_member" to "service_role";

grant truncate on table "public"."pending_member" to "service_role";

grant update on table "public"."pending_member" to "service_role";

create policy "Enable all operations for managers"
on "public"."pending_member"
as permissive
for all
to authenticated
using (is_manager())
with check (true);

-- Create triggers on auth.users
CREATE TRIGGER users_i_u
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.team_member_i_u_from_sso();
