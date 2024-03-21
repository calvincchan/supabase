ALTER TABLE "public"."reminder"
ADD CONSTRAINT "end_date_check" CHECK ((end_date >= start_date)) NOT VALID;

ALTER TABLE "public"."reminder" VALIDATE CONSTRAINT "end_date_check";