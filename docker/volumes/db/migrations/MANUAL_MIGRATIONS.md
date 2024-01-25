There are some operations that requires manual clicking in the studio interface. Please make sure to complete these tasks before deployment.


## 2024-01-18 Public Tables
1. Enable realtime to the following tables in `public`: `case`, `progress_note`, `reminder`, `session`, `target`.
2. Enable RLS to all tables.

## 2024-01-18 Audit tables
1. Enable RLS to `Audit.record_version`.


## 2024-01-19 SSO Pending Member

1. Enable RLS to `pending_member` table.

## 2024-01-25 Progress Note Attachments

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