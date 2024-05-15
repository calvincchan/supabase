UPDATE "public"."progress_note"
SET
  tags = '{}'
WHERE
  tags IS NULL;

ALTER TABLE "public"."progress_note"
ALTER COLUMN "tags"
SET DEFAULT '{}'::bpchar[];

ALTER TABLE "public"."progress_note"
ALTER COLUMN "tags"
SET NOT NULL;