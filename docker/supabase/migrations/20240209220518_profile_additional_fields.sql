create type "public"."core_needs_enum" as enum ('Learning', 'Learning (IAA only)', 'Social emotional', 'Behavioural', 'Physical', 'Giftedness', 'Others');

create type "public"."diagnosis_enum" as enum ('Anxiety', 'Attention (ADHD; ADD)', 'Autism Spectrum Disorder (ASD) Depression', 'Dyslexia', 'Dyscalculia', 'Dysgraphia', 'Dyspraxia', 'Eating disorders', 'Executive Functioning skills Obsessive Compulsive Disorder', 'Post-traumatic Stress Disorder', 'Sensory Processing Disorder', 'Social Communication Disorder', 'Others');

create type "public"."iaa_enum" as enum ('Separate room', 'Time extension', 'Word processor', 'Oral exams (25%)', 'Listening exam', 'Scribing', 'Paper size', 'Others');

create type "public"."iaa_time_extension_enum" as enum ('10%', '25%', '50%', 'Subjects ALL', 'Subjects ONLY');

create type "public"."iaa_word_processor_enum" as enum ('With spellchecker', 'Without spellchecker', 'Subjects ONLY');

create type "public"."yes_no_enum" as enum ('Y', 'N');

alter table "public"."case" add column "case_opened_at" date;

alter table "public"."case" add column "core_needs" core_needs_enum[] default '{}'::core_needs_enum[];

alter table "public"."case" add column "core_needs_others" text;

alter table "public"."case" add column "diagnosis" diagnosis_enum[] default '{}'::diagnosis_enum[];

alter table "public"."case" add column "diagnosis_others" text;

alter table "public"."case" add column "giftedness_identification_year" text;

alter table "public"."case" add column "iaa" iaa_enum[] default '{}'::iaa_enum[];

alter table "public"."case" add column "iaa_listening_exam" text;

alter table "public"."case" add column "iaa_others" text;

alter table "public"."case" add column "iaa_time_extension" iaa_time_extension_enum;

alter table "public"."case" add column "iaa_time_extension_subjects_only" text;

alter table "public"."case" add column "iaa_word_processor" iaa_word_processor_enum;

alter table "public"."case" add column "iaa_word_processor_subjects_only" text;

alter table "public"."case" add column "medical_letter" yes_no_enum;

alter table "public"."case" add column "medical_letter_attachments" jsonb default '[]'::jsonb;

alter table "public"."case" add column "pa_report" yes_no_enum;

alter table "public"."case" add column "pa_report_attachments" jsonb default '[]'::jsonb;

alter table "public"."case" add column "pa_report_last_report_at" date;

alter table "public"."case" add column "pa_report_next_report_at" date;

alter table "public"."case" add column "safeguarding_concerns" jsonb not null default '{}'::jsonb;

alter table "public"."case" add column "safeguarding_concerns_others" text;


