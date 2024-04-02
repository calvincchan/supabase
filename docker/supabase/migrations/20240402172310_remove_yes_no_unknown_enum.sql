ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET DATA TYPE CHARACTER(1) USING "medical_letter"::CHARACTER(1);

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET DATA TYPE CHARACTER(1) USING "pa_report"::CHARACTER(1);

ALTER TABLE "public"."case"
ALTER COLUMN "pa_report"
SET DEFAULT '-'::bpchar;

ALTER TABLE "public"."case"
ALTER COLUMN "medical_letter"
SET DEFAULT '-'::bpchar;

DROP TYPE "public"."yes_no_unknown_enum";