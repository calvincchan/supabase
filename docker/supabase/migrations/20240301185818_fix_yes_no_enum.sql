ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
DROP DEFAULT;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
DROP DEFAULT;

CREATE TYPE "public"."yes_no_unknown_enum" AS ENUM('Y', 'N', '-');

ALTER TABLE "public"."case"
ALTER COLUMN medical_letter
TYPE "public"."yes_no_unknown_enum" USING CASE
  WHEN medical_letter::TEXT IN ('Y', 'N') THEN medical_letter::TEXT::"public"."yes_no_unknown_enum"
  ELSE '-'
END;

ALTER TABLE "public"."case"
ALTER COLUMN pa_report
TYPE "public"."yes_no_unknown_enum" USING CASE
  WHEN pa_report::TEXT IN ('Y', 'N') THEN pa_report::TEXT::"public"."yes_no_unknown_enum"
  ELSE '-'
END;

DROP TYPE "public"."yes_no_enum";

ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET DEFAULT '-'::yes_no_unknown_enum;

ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET DEFAULT '-'::yes_no_unknown_enum;

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET NOT NULL;