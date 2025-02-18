--
-- Merge session_collaborator table into session table
--
-- Remove all policies for session_collaborator table
DROP POLICY IF EXISTS "Enable select for all users" ON "public"."session_collaborator";

DROP POLICY IF EXISTS "Enable insert for allowed roles" ON "public"."session_collaborator";

DROP POLICY IF EXISTS "Enable update for creator and allowed roles" ON "public"."session_collaborator";

DROP POLICY IF EXISTS "Enable delete for creator and allowed roles" ON "public"."session_collaborator";

ALTER TABLE "public"."session_collaborator" DISABLE ROW LEVEL SECURITY;

-- Add a new column "collaborators" in session table. This column will store an array of uuid.
ALTER TABLE "public"."session"
ADD COLUMN collaborator_users UUID[] DEFAULT '{}'::UUID[] NOT NULL;

-- Migrate data from session_collaborator to session:
-- For each session, select matching rows in session_collaborator table where session_id = session.id, and pass the list of user_id to session.collaborators
UPDATE "public"."session"
SET
  collaborator_users = (
    SELECT
      ARRAY_AGG(user_id)
    FROM
      public.session_collaborator
    WHERE
      session_id = SESSION.id
  );

-- Drop the session_collaborator table
DROP TRIGGER "session_collaborator_i_u_d" ON "public"."session_collaborator";

DROP FUNCTION "trigger_set_session_collaborators";

-- Drop the view my_session
DROP VIEW "public"."my_session";

-- Drop the table session_collaborator
DROP TABLE "public"."session_collaborator";