-- update rows to append 'Autism Spectrum Disorder (ASD)' where "diagnosis" contains 'Autism Spectrum Disorder (ASD) Depression'
-- note: "diagnosis" is an array of "diagnosis_enum__old_version_to_be_dropped"
UPDATE "public"."case"
SET
  "diagnosis" = ARRAY_APPEND(
    "diagnosis",
    'Autism Spectrum Disorder (ASD)'::diagnosis_enum__old_version_to_be_dropped
  )
WHERE
  'Autism Spectrum Disorder (ASD) Depression' = ANY ("diagnosis");

-- remove 'Autism Spectrum Disorder (ASD) Depression'
UPDATE "public"."case"
SET
  "diagnosis" = ARRAY_REMOVE(
    "diagnosis",
    'Autism Spectrum Disorder (ASD) Depression'::diagnosis_enum__old_version_to_be_dropped
  )
WHERE
  'Autism Spectrum Disorder (ASD) Depression' = ANY ("diagnosis");

-- update rows to append 'Executive Functioning skills Obsessive Compulsive Disorder' into 'Executive Functioning skills' where "diagnosis" contains 'Executive Functioning skills Obsessive Compulsive Disorder'
UPDATE "public"."case"
SET
  "diagnosis" = ARRAY_APPEND(
    "diagnosis",
    'Executive Functioning skills'::diagnosis_enum__old_version_to_be_dropped
  )
WHERE
  'Executive Functioning skills Obsessive Compulsive Disorder' = ANY ("diagnosis");

-- remove 'Executive Functioning skills Obsessive Compulsive Disorder'
UPDATE "public"."case"
SET
  "diagnosis" = ARRAY_REMOVE(
    "diagnosis",
    'Executive Functioning skills Obsessive Compulsive Disorder'::diagnosis_enum__old_version_to_be_dropped
  )
WHERE
  'Executive Functioning skills Obsessive Compulsive Disorder' = ANY ("diagnosis");

-- create new clean enum type
CREATE TYPE "public"."diagnosis_enum" AS ENUM(
  'Anxiety',
  'Attention (ADHD; ADD)',
  'Autism Spectrum Disorder (ASD)',
  'Depression',
  'Dyslexia',
  'Dyscalculia',
  'Dysgraphia',
  'Dyspraxia',
  'Eating disorders',
  'Executive Functioning skills',
  'Obsessive Compulsive Disorder',
  'Post-traumatic Stress Disorder',
  'Sensory Processing Disorder',
  'Social Communication Disorder',
  'Others'
);

-- drop default
ALTER TABLE "public"."case"
ALTER COLUMN "diagnosis"
DROP DEFAULT;

-- change the type of "diagnosis" from array of "diagnosis_enum__old_version_to_be_dropped" to array of "diagnosis_enum".
ALTER TABLE "public"."case"
ALTER COLUMN "diagnosis"
SET DATA TYPE "public"."diagnosis_enum" [] USING "diagnosis"::TEXT::"public"."diagnosis_enum" [];

-- restore default
ALTER TABLE "public"."case"
ALTER COLUMN "diagnosis"
SET DEFAULT '{}'::diagnosis_enum[];

DROP TYPE "public"."diagnosis_enum__old_version_to_be_dropped";