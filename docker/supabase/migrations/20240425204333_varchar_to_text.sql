-- Create the enum type
CREATE TYPE grade_enum AS ENUM(
  'Y1',
  'Y2',
  'FY',
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
  '08',
  '09',
  '10',
  '11',
  '12'
);

DROP VIEW "public"."my_case";

-- Pad the column with 0s on the left to make up to 2 characters
UPDATE "public"."case"
SET
  "grade" = LPAD("grade", 2, '0');

-- set "00" to "FY"
UPDATE "public"."case"
SET
  "grade" = 'FY'
WHERE
  "grade" = '00';

-- Alter "grade" column
ALTER TABLE "public"."case"
ALTER COLUMN "grade"
DROP NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "grade"
DROP DEFAULT;

ALTER TABLE "public"."case"
ALTER COLUMN "grade"
TYPE grade_enum USING "grade"::grade_enum;

ALTER TABLE "public"."case"
ALTER COLUMN "grade"
SET DEFAULT NULL;

-- Alter "homeroom" column
ALTER TABLE "public"."case"
ALTER COLUMN "homeroom"
SET DEFAULT ''::TEXT;

ALTER TABLE "public"."case"
ALTER COLUMN "homeroom"
SET DATA TYPE TEXT USING "homeroom"::TEXT;

-- Add the new column to the vieww
CREATE VIEW
  "public"."my_case" AS
SELECT
  a.id,
  a.created_at,
  a.student_name,
  a.student_no,
  a.updated_at,
  a.updated_by,
  a.is_archived,
  a.archived_at,
  a.archived_by,
  a.case_status,
  a.updated_by_name,
  a.grade,
  a.homeroom,
  a.created_by,
  a.created_by_name,
  a.tier,
  a.last_session_at,
  a.next_session_at,
  a.last_session_by,
  a.last_session_by_name,
  a.handlers,
  a.student_first_name,
  a.student_last_name,
  a.background,
  a.student_other_name,
  a.case_no
FROM
  (
    "case" a
    JOIN case_handler b ON ((a.id = b.case_id))
  )
WHERE
  (b.user_id = auth.uid ());