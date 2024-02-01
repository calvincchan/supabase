source .env
DB_URL=postgresql://postgres:$POSTGRES_PASSWORD@127.0.0.1:$POSTGRES_PORT/$POSTGRES_DB

supabase migration repair $1 --db-url "$DB_URL" --status $2
