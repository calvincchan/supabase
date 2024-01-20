-- migrate:up

-- Create pending_member table
CREATE TABLE public.pending_member (
  id text NOT NULL,
  name text NOT NULL,
  role character(1) DEFAULT 'B'::bpchar,
  invited_at timestamp with time zone DEFAULT now() NOT NULL,
  activated_at timestamp with time zone,
  CONSTRAINT pending_member_pkey PRIMARY KEY (id)
);

-- Create trigger function
CREATE OR REPLACE FUNCTION public.team_member_i_u_from_sso()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
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
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE public.pending_member ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Enable all operations for managers" ON public.pending_member TO authenticated USING (public.is_manager()) WITH CHECK (true);

-- Create triggers on auth.users
CREATE TRIGGER users_i_u
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.team_member_i_u_from_sso();

-- migrate:down

-- Drop the trigger
DROP TRIGGER IF EXISTS users_i_u ON auth.users;

-- Drop the trigger function
DROP FUNCTION IF EXISTS public.team_member_i_u_from_sso();

-- Drop the pending_member table
DROP TABLE IF EXISTS public.pending_member;
