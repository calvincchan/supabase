ALTER TABLE "public"."case"
ALTER COLUMN "core_needs"
SET NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "diagnosis"
SET NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "iaa"
SET NOT NULL;