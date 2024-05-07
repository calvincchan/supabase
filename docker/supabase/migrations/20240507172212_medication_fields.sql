ALTER TABLE "public"."case"
ADD COLUMN "medication_current" TEXT NOT NULL DEFAULT ''::TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "medication_past" TEXT NOT NULL DEFAULT ''::TEXT;