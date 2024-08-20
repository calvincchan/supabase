# Installation: supabase cli

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew install gcc
brew install supabase/tap/supabase
```

# Common Actions

### Fetch latest code from upstream and merge to local main branch

`./scripts/upstream.sh`

### Create migration script:

`./scripts/dump.sh`

`./scripts/diff.sh <script_name>`

### Apply migration scripts:

`./scripts/up.sh`

### If the database is already patched but you want to update the migration timestamp:

1. Mark as applied
   `./scripts/repair.sh <script_timestamp> applied`

2. Mark is reverted
   `./scripts/repair.sh <script_timestamp> reverted`

### Clear the database

`rm -rf volumes/db/data`

# Manual actions

### 20240201204039_lris_init

1. Enable realtime to the following tables in `public`: `case`, `progress_note`, `reminder`, `session`, `target`.
2. Enable RLS to all tables.

### 20240201214818_audit_log

1. Enable RLS to `Audit.record_version`.

### 20240201221159_sso

1. Enable RLS to `pending_member` table.
2. Run the HTTP requests in sso.http to add Id Providers.

### 20240201223425_progress_note_attachment

1. Enable realtime to the table `progress_note_attachment`.
2. Add bucket `progress_note_attachment_bucket`.
3. Add policy "All access to authenticated users", allow INSERT-UPDATE-DELETE-SELECT, target role "Authenticated".
4. Add the snippet below to the `server` block of file `/etc/nginx/sites-enabled/lst`:

```
   # STORAGE
  location ~ ^/storage/v1/(.*)$ {
      proxy_set_header Host $host;
      proxy_pass http://kong;
      proxy_redirect off;
  }
```

### 20240201224445_case_custom_columns

Nothing to do.

### 20240314060710_safeguarding_note.sql

1. Enable realtime to table `safeguarding_note`.

### 20240315191018_role_custom_claim

1. add these to .env to enable custom access token hook
GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_ENABLED=true
GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_URI="pg-functions://postgres/public/custom_access_token_hook"

2. double check role_permission table is populated

### 20240529195456_ban_unban_team_member

1. Enable realtime to table `team_member`.

### 20240815142831_rollover_job

1. Enable realtime to table `rollover_job`.

### 20240820012658_legacy_progress_logging

1. create a dir "./upload" in the root of the project
