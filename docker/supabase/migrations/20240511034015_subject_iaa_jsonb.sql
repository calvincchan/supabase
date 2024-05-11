ALTER TABLE "public"."case"
ADD COLUMN "subject_iaa" jsonb NOT NULL DEFAULT '[]'::jsonb;

-- for every row, set the value of subject_iaa to an array of objects with the following structure:
-- [{ "id": "all_subjects", "iaa": iaa, "iaa_time_extension": iaa_time_extension[1], "iaa_word_processor": iaa_word_processor[1], "iaa_listening_exam": iaa_listening_exam, "iaa_others": iaa_others }]
-- where iaa, iaa_time_extension, iaa_word_processor, iaa_listening_exam, iaa_others are the values of the corresponding columns in the row
UPDATE "public"."case"
SET
  "subject_iaa" = JSONB_BUILD_ARRAY(
    JSONB_BUILD_OBJECT(
      'id',
      'all_subjects',
      'subject',
      'All Subjects',
      'iaa',
      "iaa",
      'iaa_time_extension',
      COALESCE("iaa_time_extension" [1]::TEXT, ''),
      'iaa_word_processor',
      COALESCE("iaa_word_processor" [1]::TEXT, ''),
      'iaa_listening_exam',
      "iaa_listening_exam",
      'iaa_others',
      "iaa_others"
    )
  )
WHERE
  "iaa" != ARRAY[]::iaa_enum[];

-- note: later on, can we drop the columns iaa, iaa_time_extension, iaa_word_processor, iaa_listening_exam, iaa_others