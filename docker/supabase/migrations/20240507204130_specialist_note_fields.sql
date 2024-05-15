-- add a new column "specialist_tmp" of jsonb to the "public"."case" table
ALTER TABLE "public"."case"
ADD COLUMN "specialist_tmp" jsonb DEFAULT NULL;

-- convert the existing "specialists" (array of int8) to the new "specialist_tmp" (jsonb) for each row.
-- example: [1,2,3] to [1,2,3]
-- example: [10, 11] to [10, 11]
-- example: [] to []
UPDATE "public"."case"
SET
  "specialist_tmp" = TO_JSONB("specialists");

-- reformat "specialist_tmp"
-- example: from [1,2,3] to [{"specialist_id": 1},{"specialist_id":2},{"specialist_id":3}]
-- example: from [10, 11] to [{"specialist_id":10},{"specialist_id":11}]
-- example: from [] to []
UPDATE "public"."case"
SET
  specialist_tmp = q1.new_value
FROM
  (
    SELECT
      id,
      (
        SELECT
          JSONB_AGG(JSONB_BUILD_OBJECT('id', se))
        FROM
          JSONB_ARRAY_ELEMENTS(specialist_tmp) AS se
      ) AS new_value
    FROM
      "public"."case"
  ) q1
WHERE
  "public"."case".id = q1.id;

-- set all null values to empty array
UPDATE "public"."case"
SET
  specialist_tmp = '[]'::jsonb
WHERE
  specialist_tmp IS NULL;

-- change the column "specialists" to jsonb not null with default '{}'::jsonb
-- use the new column "specialist_tmp" as the source value for every row
ALTER TABLE "public"."case"
ALTER COLUMN "specialists"
DROP DEFAULT;

ALTER TABLE "public"."case"
ALTER COLUMN "specialists"
SET DATA TYPE jsonb USING "specialist_tmp";

ALTER TABLE "public"."case"
ALTER COLUMN "specialists"
SET DEFAULT '[]'::jsonb;

ALTER TABLE "public"."case"
ALTER COLUMN "specialists"
SET NOT NULL;

-- drop the column "specialist_tmp"
ALTER TABLE "public"."case"
DROP COLUMN "specialist_tmp";