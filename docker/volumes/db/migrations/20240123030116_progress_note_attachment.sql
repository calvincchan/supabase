-- migrate:up

CREATE TABLE "public"."progress_note_attachment" (
    "id" uuid NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "case_id" int8 NOT NULL,
    "note_id" int8 NOT NULL,
    "name" text NOT NULL,
    "size" int8 NOT NULL,
    "type" text NOT NULL,
    CONSTRAINT "progress_note_attachment_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "public"."case"("id") ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT "progress_note_attachment_note_id_fkey" FOREIGN KEY ("note_id") REFERENCES "public"."progress_note"("id") ON DELETE CASCADE ON UPDATE RESTRICT,
    PRIMARY KEY ("id")
);

CREATE POLICY "Enable all operations for authenticated users" ON public.progress_note_attachment TO authenticated USING (true) WITH CHECK (true);

-- migrate:down

DROP TABLE public.progress_note_attachment;