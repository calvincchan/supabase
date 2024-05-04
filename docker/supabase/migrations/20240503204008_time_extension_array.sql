-- convert column "iaa_time_extension" from iaa_time_extension_enum to iaa_time_extension_enum[]
-- convert NULL to empty array
ALTER TABLE "public"."case"
ALTER COLUMN iaa_time_extension
SET DATA TYPE iaa_time_extension_enum[] USING ARRAY[iaa_time_extension]::iaa_time_extension_enum[];

UPDATE "public"."case"
SET
  iaa_time_extension = ARRAY[]::iaa_time_extension_enum[]
WHERE
  iaa_time_extension = ARRAY[NULL]::iaa_time_extension_enum[];

ALTER TABLE "public"."case"
ALTER COLUMN iaa_time_extension
SET DEFAULT '{}'::iaa_time_extension_enum[];

ALTER TABLE "public"."case"
ALTER COLUMN iaa_time_extension
SET NOT NULL;