-- convert all foreign keys to use auth.users instead of public.team_member
-- public.legacy_progress_note
ALTER TABLE "public"."legacy_progress_note"
DROP CONSTRAINT "public_legacy_progress_note_entered_by_uuid_fkey";

ALTER TABLE "public"."legacy_progress_note"
ADD CONSTRAINT "legacy_progress_note_entered_by_uuid_fkey" FOREIGN KEY (entered_by_uuid) REFERENCES auth.users (id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."legacy_progress_note" VALIDATE CONSTRAINT "legacy_progress_note_entered_by_uuid_fkey";

-- public.session_collaborator
ALTER TABLE "public"."session_collaborator"
DROP CONSTRAINT "public_session_collaborator_user_id_fkey";

ALTER TABLE "public"."session_collaborator"
ADD CONSTRAINT "session_collaborator_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users (id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."session_collaborator" VALIDATE CONSTRAINT "session_collaborator_user_id_fkey";

-- public.page
ALTER TABLE "public"."page"
DROP CONSTRAINT "page_created_by_fkey";

ALTER TABLE "public"."page"
DROP CONSTRAINT "page_updated_by_fkey";

ALTER TABLE "public"."page"
ADD CONSTRAINT "page_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users (id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."page" VALIDATE CONSTRAINT "page_created_by_fkey";

ALTER TABLE "public"."page"
ADD CONSTRAINT "page_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES auth.users (id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."page" VALIDATE CONSTRAINT "page_updated_by_fkey";