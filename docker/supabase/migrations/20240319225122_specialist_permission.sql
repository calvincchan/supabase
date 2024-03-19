ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'specialist:list';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'specialist:create';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'specialist:edit';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'specialist:delete';