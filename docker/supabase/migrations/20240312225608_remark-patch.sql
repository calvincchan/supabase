alter table "public"."remark" alter column "content" drop not null;

create policy "Enable read access for all users"
on "public"."remark"
as permissive
for select
to authenticated
using (true);



