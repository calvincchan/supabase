ALTER TYPE "public"."iaa_enum"
RENAME TO "iaa_enum__old_version_to_be_dropped";

CREATE TYPE "public"."iaa_enum" AS ENUM(
  'Separate room',
  'Time extension',
  'Word processor',
  'Oral exams (25%)',
  'Listening exam',
  'Scribing',
  'Paper size',
  'Breaks',
  'Others'
);

-- disable default
ALTER TABLE "public"."case"
ALTER COLUMN "iaa"
DROP DEFAULT;

-- change "public"."case" table "iaa" column to array of "iaa_enum"
ALTER TABLE "public"."case"
ALTER COLUMN "iaa"
SET DATA TYPE "public"."iaa_enum" [] USING "iaa"::TEXT::"public"."iaa_enum" [];

-- restore default
ALTER TABLE "public"."case"
ALTER COLUMN "iaa"
SET DEFAULT '{}'::iaa_enum[];

-- drop the old enum type
DROP TYPE "public"."iaa_enum__old_version_to_be_dropped";