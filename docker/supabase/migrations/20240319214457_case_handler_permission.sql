ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'case_handler:list';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'case_handler:create';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'case_handler:edit';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'case_handler:delete';