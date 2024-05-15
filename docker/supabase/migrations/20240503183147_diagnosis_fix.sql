-- rename the old enum type to be dropped
ALTER TYPE "public"."diagnosis_enum"
RENAME TO "diagnosis_enum__old_version_to_be_dropped";

-- add new enum items "Autism Spectrum Disorder (ASD)", "Depression", "Executive Functioning skills", "Obsessive Compulsive Disorder"
ALTER TYPE "public"."diagnosis_enum__old_version_to_be_dropped"
ADD VALUE 'Autism Spectrum Disorder (ASD)';

ALTER TYPE "public"."diagnosis_enum__old_version_to_be_dropped"
ADD VALUE 'Depression';

ALTER TYPE "public"."diagnosis_enum__old_version_to_be_dropped"
ADD VALUE 'Executive Functioning skills';

ALTER TYPE "public"."diagnosis_enum__old_version_to_be_dropped"
ADD VALUE 'Obsessive Compulsive Disorder';