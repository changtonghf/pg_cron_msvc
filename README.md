# pg_cron_msvc
based on [citusdata/pg_cron](https://github.com/citusdata/pg_cron) and compiled in Windows MSVC
## Installing pg_cron
copy pg_cron.dll from Debug directory to postgresql lib directory

copy pg_cron.control and pg_cron--1.6.sql postgresql share\extension directory

edit postgresql.conf add below contents
```
log_min_messages = info
log_min_error_statement = info
max_worker_processes = 32
shared_preload_libraries = 'pg_cron'
cron.database_name = 'postgres'
cron.use_background_workers = on
cron.host = ''
```
After restarting PostgreSQL, you can create the pg_cron functions and metadata tables using **create extension pg_cron**
