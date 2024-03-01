ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
DROP DEFAULT;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
DROP DEFAULT;

ALTER TYPE "public"."yes_no_enum"
RENAME TO "yes_no_enum__old_version_to_be_dropped";

CREATE TYPE "public"."yes_no_enum" AS ENUM('Y', 'N', '-');

ALTER TABLE "public"."case"
ALTER COLUMN medical_letter
TYPE "public"."yes_no_enum" USING CASE
  WHEN medical_letter::TEXT IN ('Y', 'N') THEN medical_letter::TEXT::"public"."yes_no_enum"
  ELSE '-'
END;

ALTER TABLE "public"."case"
ALTER COLUMN pa_report
TYPE "public"."yes_no_enum" USING CASE
  WHEN pa_report::TEXT IN ('Y', 'N') THEN pa_report::TEXT::"public"."yes_no_enum"
  ELSE '-'
END;

DROP TYPE "public"."yes_no_enum__old_version_to_be_dropped";

ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET DEFAULT '-'::yes_no_enum;

ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET DEFAULT '-'::yes_no_enum;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET NOT NULL;