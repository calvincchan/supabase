ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'pending_member:list';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'pending_member:create';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'pending_member:edit';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'pending_member:delete';