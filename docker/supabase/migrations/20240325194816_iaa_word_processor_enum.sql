ALTER TYPE "public"."iaa_word_processor_enum"
RENAME TO "iaa_word_processor_enum__old_version_to_be_dropped";

CREATE TYPE "public"."iaa_word_processor_enum" AS ENUM(
  'With spellchecker',
  'Without spellchecker',
  'Subjects ALL',
  'Subjects ONLY'
);

ALTER TABLE "public"."case"
ALTER COLUMN iaa_word_processor
TYPE "public"."iaa_word_processor_enum" USING iaa_word_processor::TEXT::"public"."iaa_word_processor_enum";

DROP TYPE "public"."iaa_word_processor_enum__old_version_to_be_dropped";

ALTER TABLE "public"."case"
ALTER COLUMN iaa_word_processor
TYPE "public"."iaa_word_processor_enum" [] USING COALESCE(
  ARRAY[iaa_word_processor],
  ARRAY[]::"public"."iaa_word_processor_enum" []
);

UPDATE "public"."case"
SET
  iaa_word_processor = ARRAY[]::"public"."iaa_word_processor_enum" []
WHERE
  iaa_word_processor = ARRAY[NULL]::"public"."iaa_word_processor_enum" []