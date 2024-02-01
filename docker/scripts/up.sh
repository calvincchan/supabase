source .env
DB_URL=postgresql://postgres:$POSTGRES_PASSWORD@127.0.0.1:$POSTGRES_PORT/$POSTGRES_DB

supabase migration up --db-url "$DB_URL"