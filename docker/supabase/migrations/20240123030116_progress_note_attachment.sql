CREATE TABLE
  "public"."progress_note_attachment" (
    "id" UUID NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "case_id" BIGINT NOT NULL,
    "note_id" BIGINT NOT NULL,
    "name" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "type" TEXT NOT NULL
  );

ALTER TABLE "public"."progress_note_attachment" ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX progress_note_attachment_pkey ON public.progress_note_attachment USING btree (id);

ALTER TABLE "public"."progress_note_attachment"
ADD CONSTRAINT "progress_note_attachment_pkey" PRIMARY KEY USING INDEX "progress_note_attachment_pkey";

ALTER TABLE "public"."progress_note_attachment"
ADD CONSTRAINT "progress_note_attachment_case_id_fkey" FOREIGN KEY (case_id) REFERENCES "case" (id) ON UPDATE RESTRICT ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."progress_note_attachment" VALIDATE CONSTRAINT "progress_note_attachment_case_id_fkey";

ALTER TABLE "public"."progress_note_attachment"
ADD CONSTRAINT "progress_note_attachment_note_id_fkey" FOREIGN KEY (note_id) REFERENCES progress_note (id) ON UPDATE RESTRICT ON DELETE CASCADE NOT VALID;

ALTER TABLE "public"."progress_note_attachment" VALIDATE CONSTRAINT "progress_note_attachment_note_id_fkey";

GRANT DELETE ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT INSERT ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT REFERENCES ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT
SELECT
  ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT TRIGGER ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT
TRUNCATE ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT
UPDATE ON TABLE "public"."progress_note_attachment" TO "anon";

GRANT DELETE ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT INSERT ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT
SELECT
  ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT
TRUNCATE ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT
UPDATE ON TABLE "public"."progress_note_attachment" TO "authenticated";

GRANT DELETE ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT INSERT ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT REFERENCES ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT
SELECT
  ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT TRIGGER ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT
TRUNCATE ON TABLE "public"."progress_note_attachment" TO "service_role";

GRANT
UPDATE ON TABLE "public"."progress_note_attachment" TO "service_role";

CREATE POLICY "Enable all operations for authenticated users" ON "public"."progress_note_attachment" AS permissive FOR ALL TO authenticated USING (TRUE)
WITH
  CHECK (TRUE);