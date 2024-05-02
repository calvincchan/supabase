-- store a copy of the start date of the recurrence
ALTER TABLE "public"."session"
ADD COLUMN "recurrence_start_date" TIMESTAMP WITH TIME ZONE;

-- drop column "time_frame_until"
ALTER TABLE "public"."session"
DROP COLUMN "time_frame_until";

-- fix the recurrence parent with null value
UPDATE "public"."session"
SET
  recurrence_parent = id
WHERE
  time_frame = 'B'
  AND recurrence_parent IS NULL;

-- update the recurrence start date with the start date of the recurrence parent
UPDATE "public"."session" a
SET
  recurrence_start_date = (
    SELECT
      start_date
    FROM
      "public"."session"
    WHERE
      id = a.recurrence_parent
    LIMIT
      1
  )
WHERE
  time_frame = 'B'
  AND recurrence_parent IS NOT NULL;