CREATE TYPE "public"."core_needs_enum" AS ENUM(
  'Learning',
  'Learning (IAA only)',
  'Social emotional',
  'Behavioural',
  'Physical',
  'Giftedness',
  'Others'
);

CREATE TYPE "public"."diagnosis_enum" AS ENUM(
  'Anxiety',
  'Attention (ADHD; ADD)',
  'Autism Spectrum Disorder (ASD) Depression',
  'Dyslexia',
  'Dyscalculia',
  'Dysgraphia',
  'Dyspraxia',
  'Eating disorders',
  'Executive Functioning skills Obsessive Compulsive Disorder',
  'Post-traumatic Stress Disorder',
  'Sensory Processing Disorder',
  'Social Communication Disorder',
  'Others'
);

CREATE TYPE "public"."iaa_enum" AS ENUM(
  'Separate room',
  'Time extension',
  'Word processor',
  'Oral exams (25%)',
  'Listening exam',
  'Scribing',
  'Paper size',
  'Others'
);

CREATE TYPE "public"."iaa_time_extension_enum" AS ENUM(
  '10%',
  '25%',
  '50%',
  'Subjects ALL',
  'Subjects ONLY'
);

CREATE TYPE "public"."iaa_word_processor_enum" AS ENUM(
  'With spellchecker',
  'Without spellchecker',
  'Subjects ONLY'
);

CREATE TYPE "public"."yes_no_enum" AS ENUM('Y', 'N');

ALTER TABLE "public"."case"
ADD COLUMN "case_opened_at" date;

ALTER TABLE "public"."case"
ADD COLUMN "core_needs" core_needs_enum[] DEFAULT '{}'::core_needs_enum[];

ALTER TABLE "public"."case"
ADD COLUMN "core_needs_others" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "diagnosis" diagnosis_enum[] DEFAULT '{}'::diagnosis_enum[];

ALTER TABLE "public"."case"
ADD COLUMN "diagnosis_others" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "giftedness_identification_year" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "iaa" iaa_enum[] DEFAULT '{}'::iaa_enum[];

ALTER TABLE "public"."case"
ADD COLUMN "iaa_listening_exam" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "iaa_others" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "iaa_time_extension" iaa_time_extension_enum;

ALTER TABLE "public"."case"
ADD COLUMN "iaa_time_extension_subjects_only" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "iaa_word_processor" iaa_word_processor_enum;

ALTER TABLE "public"."case"
ADD COLUMN "iaa_word_processor_subjects_only" TEXT;

ALTER TABLE "public"."case"
ADD COLUMN "medical_letter" yes_no_enum;

ALTER TABLE "public"."case"
ADD COLUMN "medical_letter_attachments" jsonb DEFAULT '[]'::jsonb;

ALTER TABLE "public"."case"
ADD COLUMN "pa_report" yes_no_enum;

ALTER TABLE "public"."case"
ADD COLUMN "pa_report_attachments" jsonb DEFAULT '[]'::jsonb;

ALTER TABLE "public"."case"
ADD COLUMN "pa_report_last_report_at" date;

ALTER TABLE "public"."case"
ADD COLUMN "pa_report_next_report_at" date;

ALTER TABLE "public"."case"
ADD COLUMN "safeguarding_concerns" jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE "public"."case"
ADD COLUMN "safeguarding_concerns_others" TEXT;