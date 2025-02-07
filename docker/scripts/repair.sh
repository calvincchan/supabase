source .env
DB_URL=postgresql://postgres:$POSTGRES_PASSWORD@127.0.0.1:$POSTGRES_PORT/$POSTGRES_DB

supabase migration repair --db-url "$DB_URL" --status $1 $2 $3
