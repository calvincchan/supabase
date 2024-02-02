create table "public"."progress_note_attachment" (
    "id" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "case_id" bigint not null,
    "note_id" bigint not null,
    "name" text not null,
    "size" bigint not null,
    "type" text not null
);


alter table "public"."progress_note_attachment" enable row level security;

CREATE UNIQUE INDEX progress_note_attachment_pkey ON public.progress_note_attachment USING btree (id);

alter table "public"."progress_note_attachment" add constraint "progress_note_attachment_pkey" PRIMARY KEY using index "progress_note_attachment_pkey";

alter table "public"."progress_note_attachment" add constraint "progress_note_attachment_case_id_fkey" FOREIGN KEY (case_id) REFERENCES "case"(id) ON UPDATE RESTRICT ON DELETE CASCADE not valid;

alter table "public"."progress_note_attachment" validate constraint "progress_note_attachment_case_id_fkey";

alter table "public"."progress_note_attachment" add constraint "progress_note_attachment_note_id_fkey" FOREIGN KEY (note_id) REFERENCES progress_note(id) ON UPDATE RESTRICT ON DELETE CASCADE not valid;

alter table "public"."progress_note_attachment" validate constraint "progress_note_attachment_note_id_fkey";

grant delete on table "public"."progress_note_attachment" to "anon";

grant insert on table "public"."progress_note_attachment" to "anon";

grant references on table "public"."progress_note_attachment" to "anon";

grant select on table "public"."progress_note_attachment" to "anon";

grant trigger on table "public"."progress_note_attachment" to "anon";

grant truncate on table "public"."progress_note_attachment" to "anon";

grant update on table "public"."progress_note_attachment" to "anon";

grant delete on table "public"."progress_note_attachment" to "authenticated";

grant insert on table "public"."progress_note_attachment" to "authenticated";

grant references on table "public"."progress_note_attachment" to "authenticated";

grant select on table "public"."progress_note_attachment" to "authenticated";

grant trigger on table "public"."progress_note_attachment" to "authenticated";

grant truncate on table "public"."progress_note_attachment" to "authenticated";

grant update on table "public"."progress_note_attachment" to "authenticated";

grant delete on table "public"."progress_note_attachment" to "service_role";

grant insert on table "public"."progress_note_attachment" to "service_role";

grant references on table "public"."progress_note_attachment" to "service_role";

grant select on table "public"."progress_note_attachment" to "service_role";

grant trigger on table "public"."progress_note_attachment" to "service_role";

grant truncate on table "public"."progress_note_attachment" to "service_role";

grant update on table "public"."progress_note_attachment" to "service_role";

create policy "Enable all operations for authenticated users"
on "public"."progress_note_attachment"
as permissive
for all
to authenticated
using (true)
with check (true);



