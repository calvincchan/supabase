-- Remove trigger and function that create placeholder target entry
DROP TRIGGER IF EXISTS "insert_target" ON "public"."case";

DROP FUNCTION IF EXISTS public.insert_into_target;

-- Add the new column
ALTER TABLE "public"."target"
ADD COLUMN "case_id" INTEGER;

-- Copy the values from the id column
UPDATE "public"."target"
SET
  "case_id" = "id";

-- Now add the NOT NULL constraint
ALTER TABLE "public"."target"
ALTER COLUMN "case_id"
SET NOT NULL;

-- New foreign key constraint
ALTER TABLE "public"."target"
DROP CONSTRAINT "target_id_fkey";

ALTER TABLE "public"."target"
ADD CONSTRAINT "public_target_case_id_fkey" FOREIGN KEY (case_id) REFERENCES "case" (id) ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."target" VALIDATE CONSTRAINT "public_target_case_id_fkey";

-- Create the enum type
CREATE TYPE target_type_enum AS ENUM(
  'Academic',
  'Social Emotional',
  'Behavioural',
  'Others'
);

-- Add the new column for target_type with default value "Others"
ALTER TABLE "public"."target"
ADD COLUMN "target_type" target_type_enum NOT NULL DEFAULT 'Others';

-- Convert the existing values to new "content" text column
ALTER TABLE "public"."target"
ADD COLUMN "content" TEXT NOT NULL DEFAULT '';

UPDATE "public"."target"
SET
  "content" = "targets";

-- Drop the old columns
ALTER TABLE "public"."target"
DROP COLUMN "targets";

-- Delete rows where "content" == '{}' or empty string
DELETE FROM "public"."target"
WHERE
  "content" = '{}'
  OR "content" = '';