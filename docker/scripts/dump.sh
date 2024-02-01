source .env
DB_URL=postgresql://postgres:$POSTGRES_PASSWORD@127.0.0.1:$POSTGRES_PORT/$POSTGRES_DB

supabase db dump --schema $POSTGRES_DUMP_SCHEMAS --db-url "$DB_URL" --role-only > ./supabase/dumps/roles.sql
supabase db dump --schema $POSTGRES_DUMP_SCHEMAS --db-url "$DB_URL" > ./supabase/dumps/schema.sql
# supabase db dump --schema $POSTGRES_DUMP_SCHEMAS --db-url "$DB_URL" --data-only > ./supabase/dumps/data.sql
