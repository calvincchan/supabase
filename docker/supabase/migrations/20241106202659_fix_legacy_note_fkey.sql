-- convert all foreign keys to use auth.users instead of public.team_member
-- public.legacy_progress_note
ALTER TABLE "public"."legacy_progress_note"
DROP CONSTRAINT "legacy_progress_note_entered_by_uuid_fkey";

ALTER TABLE "public"."legacy_progress_note"
ADD CONSTRAINT "public_legacy_progress_note_entered_by_uuid_fkey" FOREIGN KEY (entered_by_uuid) REFERENCES public.team_member (id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."legacy_progress_note" VALIDATE CONSTRAINT "public_legacy_progress_note_entered_by_uuid_fkey";