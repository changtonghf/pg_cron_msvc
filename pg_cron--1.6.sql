DO $$
BEGIN
   IF pg_catalog.current_database() OPERATOR(pg_catalog.<>) pg_catalog.current_setting('cron.database_name') AND pg_catalog.current_database() OPERATOR(pg_catalog.<>) 'contrib_regression' THEN
      RAISE EXCEPTION 'can only create extension in database %', pg_catalog.current_setting('cron.database_name')
      USING DETAIL = 'Jobs must be scheduled from the database configured in 'OPERATOR(pg_catalog.||) 'cron.database_name, since the pg_cron background worker 'OPERATOR(pg_catalog.||) 'reads job descriptions from this database.',
            HINT = pg_catalog.format('Add cron.database_name = ''%s'' in postgresql.conf 'OPERATOR(pg_catalog.||) 'to use the current database.', pg_catalog.current_database());
   END IF;
END;
$$;

CREATE SCHEMA cron;
CREATE SEQUENCE cron.jobid_seq;

CREATE TABLE cron.job (
    jobid       bigint  primary key default pg_catalog.nextval('cron.jobid_seq'),
    schedule    text    not null,
    command     text    not null,
    nodename    text    not null default 'localhost',
    nodeport    int     not null default pg_catalog.inet_server_port(),
    database    text    not null default pg_catalog.current_database(),
    username    text    not null default current_user
);
GRANT SELECT ON cron.job TO public;
ALTER TABLE cron.job ENABLE ROW LEVEL SECURITY;
CREATE POLICY cron_job_policy ON cron.job USING (username OPERATOR(pg_catalog.=) current_user);

CREATE FUNCTION cron.schedule(schedule text, command text) RETURNS bigint LANGUAGE C STRICT AS 'MODULE_PATHNAME', $$cron_schedule$$;
COMMENT ON FUNCTION cron.schedule(text,text) IS 'schedule a pg_cron job';

CREATE FUNCTION cron.unschedule(job_id bigint) RETURNS bool LANGUAGE C STRICT AS 'MODULE_PATHNAME', $$cron_unschedule$$;
COMMENT ON FUNCTION cron.unschedule(bigint) IS 'unschedule a pg_cron job';

CREATE FUNCTION cron.job_cache_invalidate() RETURNS trigger LANGUAGE C AS 'MODULE_PATHNAME', $$cron_job_cache_invalidate$$;
COMMENT ON FUNCTION cron.job_cache_invalidate() IS 'invalidate job cache';

CREATE TRIGGER cron_job_cache_invalidate AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE ON cron.job FOR STATEMENT EXECUTE PROCEDURE cron.job_cache_invalidate();

ALTER TABLE cron.job ADD COLUMN active boolean not null default 'true';

SELECT pg_catalog.pg_extension_config_dump('cron.job', '');
SELECT pg_catalog.pg_extension_config_dump('cron.jobid_seq', '');

CREATE SEQUENCE cron.runid_seq;
CREATE TABLE cron.job_run_details (
    jobid           bigint,
    runid           bigint primary key default pg_catalog.nextval('cron.runid_seq'),
    job_pid         integer,
    database        text,
    username        text,
    command         text,
    status          text,
    return_message  text,
    start_time      timestamptz,
    end_time        timestamptz
);

GRANT SELECT ON cron.job_run_details TO public;
GRANT DELETE ON cron.job_run_details TO public;
ALTER TABLE cron.job_run_details ENABLE ROW LEVEL SECURITY;
CREATE POLICY cron_job_run_details_policy ON cron.job_run_details USING (username OPERATOR(pg_catalog.=) current_user);

SELECT pg_catalog.pg_extension_config_dump('cron.job_run_details', '');
SELECT pg_catalog.pg_extension_config_dump('cron.runid_seq', '');

ALTER TABLE cron.job ADD COLUMN jobname name;

CREATE UNIQUE INDEX jobname_username_idx ON cron.job (jobname, username);
ALTER TABLE cron.job ADD CONSTRAINT jobname_username_uniq UNIQUE USING INDEX jobname_username_idx;

CREATE FUNCTION cron.schedule(job_name name, schedule text, command text) RETURNS bigint LANGUAGE C STRICT AS 'MODULE_PATHNAME', $$cron_schedule_named$$;
COMMENT ON FUNCTION cron.schedule(name,text,text) IS 'schedule a pg_cron job';

CREATE FUNCTION cron.unschedule(job_name name) RETURNS bool LANGUAGE C STRICT AS 'MODULE_PATHNAME', $$cron_unschedule_named$$;
COMMENT ON FUNCTION cron.unschedule(name) IS 'unschedule a pg_cron job';

DROP FUNCTION cron.schedule(name,text,text);
CREATE FUNCTION cron.schedule(job_name text, schedule text, command text) RETURNS bigint LANGUAGE C AS 'MODULE_PATHNAME', $$cron_schedule_named$$;
COMMENT ON FUNCTION cron.schedule(text,text,text) IS 'schedule a pg_cron job';

CREATE FUNCTION cron.alter_job(job_id bigint, schedule text default null, command text default null, database text default null, username text default null, active boolean default null)
RETURNS void LANGUAGE C AS 'MODULE_PATHNAME', $$cron_alter_job$$;

COMMENT ON FUNCTION cron.alter_job(bigint,text,text,text,text,boolean) IS 'Alter the job identified by job_id. Any option left as NULL will not be modified.';

REVOKE ALL ON FUNCTION cron.alter_job(bigint,text,text,text,text,boolean) FROM public;

CREATE FUNCTION cron.schedule_in_database(job_name text, schedule text, command text, database text, username text default null, active boolean default 'true')
RETURNS bigint LANGUAGE C AS 'MODULE_PATHNAME', $$cron_schedule_named$$;

COMMENT ON FUNCTION cron.schedule_in_database(text,text,text,text,text,boolean) IS 'schedule a pg_cron job';

REVOKE ALL ON FUNCTION cron.schedule_in_database(text,text,text,text,text,boolean) FROM public;

GRANT SELECT ON SEQUENCE cron.jobid_seq TO public;
GRANT SELECT ON SEQUENCE cron.runid_seq TO public;

ALTER TABLE cron.job ALTER COLUMN jobname TYPE text;

DROP FUNCTION cron.unschedule(name);
CREATE FUNCTION cron.unschedule(job_name text) RETURNS bool LANGUAGE C STRICT AS 'MODULE_PATHNAME', $$cron_unschedule_named$$;
COMMENT ON FUNCTION cron.unschedule(text) IS 'unschedule a pg_cron job';
