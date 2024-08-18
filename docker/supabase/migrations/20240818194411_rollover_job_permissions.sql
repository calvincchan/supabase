-- Add new values to permission_enum
ALTER TYPE permission_enum
ADD VALUE 'rollover_job:list';

ALTER TYPE permission_enum
ADD VALUE 'rollover_job:create';