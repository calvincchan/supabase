ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'team_member:list';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'team_member:create';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'team_member:edit';

ALTER TYPE "public"."permission_enum"
ADD VALUE IF NOT EXISTS 'team_member:delete';