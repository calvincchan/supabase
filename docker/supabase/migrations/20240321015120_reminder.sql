ALTER TABLE "public"."reminder"
ADD COLUMN "end_date" date NOT NULL;

ALTER TABLE "public"."reminder"
ADD COLUMN "start_date" date NOT NULL;

s