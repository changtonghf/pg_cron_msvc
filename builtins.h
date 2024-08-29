
#ifndef PG_CRON_BUILTINS
#define PG_CRON_BUILTINS

#ifndef PGDLLEXPORT
#ifdef _MSC_VER
#define PGDLLEXPORT	__declspec(dllexport)

#undef PG_MODULE_MAGIC
#define PG_MODULE_MAGIC \
extern PGDLLEXPORT const Pg_magic_struct *PG_MAGIC_FUNCTION_NAME(void); \
const Pg_magic_struct * \
PG_MAGIC_FUNCTION_NAME(void) \
{ \
	static const Pg_magic_struct Pg_magic_data = PG_MODULE_MAGIC_DATA; \
	return &Pg_magic_data; \
} \
extern int no_such_variable

#undef PG_FUNCTION_INFO_V1
#define PG_FUNCTION_INFO_V1(funcname) \
extern PGDLLEXPORT const Pg_finfo_record * CppConcat(pg_finfo_,funcname)(void); \
const Pg_finfo_record * \
CppConcat(pg_finfo_,funcname) (void) \
{ \
	static const Pg_finfo_record my_finfo = { 1 }; \
	return &my_finfo; \
} \
extern int no_such_variable

#else
#define PGDLLEXPORT	PGDLLIMPORT
#endif
#endif

extern PGDLLEXPORT void _PG_init(void);
extern PGDLLEXPORT void PgCronLauncherMain(Datum arg);
extern PGDLLEXPORT void CronBackgroundWorker(Datum arg);
extern PGDLLEXPORT Datum cron_schedule(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum cron_schedule_named(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum cron_unschedule(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum cron_unschedule_named(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum cron_job_cache_invalidate(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum cron_alter_job(PG_FUNCTION_ARGS);

#endif
