UPDATE "public"."case"
SET
  grade = ''
WHERE
  grade IS NULL;

UPDATE "public"."case"
SET
  homeroom = ''
WHERE
  homeroom IS NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "grade"
SET DEFAULT ''::CHARACTER VARYING;

ALTER TABLE "public"."case"
ALTER COLUMN "grade"
SET NOT NULL;

ALTER TABLE "public"."case"
ALTER COLUMN "homeroom"
SET DEFAULT ''::CHARACTER VARYING;

ALTER TABLE "public"."case"
ALTER COLUMN "homeroom"
SET NOT NULL;