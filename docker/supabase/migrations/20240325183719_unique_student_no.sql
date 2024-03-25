ALTER TABLE "public"."case"
ALTER COLUMN "student_no"
SET DEFAULT '';

ALTER TABLE "public"."case"
ALTER COLUMN "student_no"
SET NOT NULL;

ALTER TABLE "public"."case"
ADD CONSTRAINT "student_no_unique" UNIQUE ("student_no");