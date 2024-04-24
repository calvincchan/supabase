UPDATE "public"."case"
SET
  iaa_word_processor = ARRAY[]::iaa_word_processor_enum[]
WHERE
  iaa_word_processor IS NULL;

ALTER TABLE "public"."case"
ALTER COLUMN iaa_word_processor
SET DEFAULT '{}'::iaa_word_processor_enum[];

ALTER TABLE "public"."case"
ALTER COLUMN iaa_word_processor
SET NOT NULL;