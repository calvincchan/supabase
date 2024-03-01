alter table "public"."case" alter column "medical_letter" drop default;

alter table "public"."case" alter column "pa_report" drop default;

alter type "public"."yes_no_enum" rename to "yes_no_enum__old_version_to_be_dropped";

create type "public"."yes_no_enum" as enum ('Y', 'N', '-');

alter table "public"."case" alter column medical_letter type "public"."yes_no_enum" using medical_letter::text::"public"."yes_no_enum";

alter table "public"."case" alter column pa_report type "public"."yes_no_enum" using pa_report::text::"public"."yes_no_enum";

alter table "public"."case" alter column "medical_letter" set default None;

alter table "public"."case" alter column "pa_report" set default None;

drop type "public"."yes_no_enum__old_version_to_be_dropped";

alter table "public"."case" alter column "medical_letter" set default '-'::yes_no_enum;

alter table "public"."case" alter column "medical_letter" set not null;

alter table "public"."case" alter column "pa_report" set default '-'::yes_no_enum;

alter table "public"."case" alter column "pa_report" set not null;


