ALTER TABLE "public"."case"
ADD COLUMN "support_frequency_counselling" TEXT NOT NULL DEFAULT ''::TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "support_frequency_learning" TEXT NOT NULL DEFAULT ''::TEXT;