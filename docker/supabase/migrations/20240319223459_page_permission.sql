ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'page:list';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'page:create';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'page:edit';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'page:delete';