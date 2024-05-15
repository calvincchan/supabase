--
-- convert nullable text fields to not null
--
-- case_status
ALTER TABLE "public"."case"
ALTER COLUMN "case_status"
SET NOT NULL;

-- create a function to:
-- 1. set existing rows with null to empty string
-- 2. update a column to not null
-- 3. with a default value ''
CREATE
OR REPLACE FUNCTION set_not_null_default_empty_string (column_name TEXT, table_name TEXT) RETURNS void AS $$
BEGIN
  EXECUTE format('UPDATE %I SET %I = '''' WHERE %I IS NULL', table_name, column_name, column_name);
  EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET DEFAULT ''''', table_name, column_name);
  EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET NOT NULL', table_name, column_name);
END;
$$ LANGUAGE plpgsql;

-- background
SELECT
  set_not_null_default_empty_string ('background', 'case');

-- gender
ALTER TABLE "public"."case"
DROP CONSTRAINT "case_gender_check";

UPDATE "public"."case"
SET
  "gender" = '-'
WHERE
  "gender" = ''
  OR "gender" IS NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "gender"
SET DEFAULT '-';

ALTER TABLE "public"."case"
ALTER COLUMN "gender"
SET NOT NULL;

-- email
SELECT
  set_not_null_default_empty_string ('email', 'case');

-- parent_email
SELECT
  set_not_null_default_empty_string ('parent_email', 'case');

-- mother_name
-- mother_phone
-- mother_email
SELECT
  set_not_null_default_empty_string ('mother_name', 'case');

SELECT
  set_not_null_default_empty_string ('mother_phone', 'case');

SELECT
  set_not_null_default_empty_string ('mother_email', 'case');

-- father_name
-- father_phone
-- father_email
SELECT
  set_not_null_default_empty_string ('father_name', 'case');

SELECT
  set_not_null_default_empty_string ('father_phone', 'case');

SELECT
  set_not_null_default_empty_string ('father_email', 'case');

-- custom_1
-- custom_2
-- custom_3
-- custom_4
-- custom_5
SELECT
  set_not_null_default_empty_string ('custom_1', 'case');

SELECT
  set_not_null_default_empty_string ('custom_2', 'case');

SELECT
  set_not_null_default_empty_string ('custom_3', 'case');

SELECT
  set_not_null_default_empty_string ('custom_4', 'case');

SELECT
  set_not_null_default_empty_string ('custom_5', 'case');

-- core_needs_others
SELECT
  set_not_null_default_empty_string ('core_needs_others', 'case');

-- diagnosis_others
SELECT
  set_not_null_default_empty_string ('diagnosis_others', 'case');

-- giftedness_identification_year
SELECT
  set_not_null_default_empty_string ('giftedness_identification_year', 'case');

-- iaa_listening_exam
SELECT
  set_not_null_default_empty_string ('iaa_listening_exam', 'case');

-- iaa_others
SELECT
  set_not_null_default_empty_string ('iaa_others', 'case');

-- iaa_time_extension_subjects_only
SELECT
  set_not_null_default_empty_string ('iaa_time_extension_subjects_only', 'case');

-- iaa_word_processor_subjects_only
SELECT
  set_not_null_default_empty_string ('iaa_word_processor_subjects_only', 'case');

-- safeguarding_concerns_others
SELECT
  set_not_null_default_empty_string ('safeguarding_concerns_others', 'case');

-- case_no
SELECT
  set_not_null_default_empty_string ('case_no', 'case');

-- iaa_reading_exam
--
-- jsonb should not be null
--
-- medical_letter_attachments
ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter_attachments"
SET NOT NULL;

-- pa_report_attachments
ALTER TABLE "public"."case"
ALTER COLUMN "pa_report_attachments"
SET NOT NULL;