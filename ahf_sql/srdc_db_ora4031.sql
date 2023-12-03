Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_ora4031.sql /main/3 2022/08/23 00:50:00 manuegar Exp $
Rem
Rem srdc_db_ora4031.sql
Rem
Rem Copyright (c) 2017, 2022, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_ora4031.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_ora4031.sql
Rem    SQL_SHIPPED_FILE: tfa_home/resources/sql/srdc_db_ora4031.sql
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    SQL_CALLING_FILE:
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    manuegar    08/19/22 - Enh 34335827 - SRDC: UPDATE SCRIPT FOR ORA4031
Rem                           COLLECTION.
Rem    bburton     02/25/20 - Add granule information - ER 30908449
Rem    bburton     04/07/17 - Script to collect info for ORA4031 data.
Rem    bburton     04/07/17 - Created
Rem
REM srdc_db_ora4031.sql - Collect information for ORA-4031 analysis 
@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_ORA4031'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
       to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on
REM
spool &SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||
       to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine:         '||host_name from v$instance
union all
select '| Version:         '||version from v$instance
union all
select '| DBName:          '||name from v$database
union all
select '| Instance:        '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/

set HEADING on MARKUP html preformat off
REM === -- end of standard header -- ===
REM
SET PAGESIZE 9999
SET LINESIZE 256
SET TRIMOUT ON
SET TRIMSPOOL ON
COL 'Total Shared Pool Usage' FORMAT 99999999999999999999999
COL 'Total Large Pool Usage' FORMAT 99999999999999999999999
COL 'Total UGA' FORMAT 99999999999999999999999
COL 'Total Pool Usage' FORMAT 99999999999999999999999
COL bytes FORMAT 999999999999999
COL current_size FORMAT 999999999999999
COL name FORMAT A40
COL 'HEAP NAME' FORMAT A40
COL value FORMAT A20
ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';

SET MARKUP HTML ON PREFORMAT ON

/* Database identification */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Database identification:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT name, platform_id, database_role FROM v$database;
SELECT * FROM v$version WHERE banner LIKE 'Oracle Database%';

/* Current instance parameter values */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Current instance parameter values:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SELECT '*****************************SHARED POOL**************************************' FROM dual;
SET HEADING ON
SELECT n.ksppinm name, v.KSPPSTVL value
FROM x$ksppi n, x$ksppsv v
WHERE n.indx = v.indx
AND (n.ksppinm LIKE '%shared_pool%' OR n.ksppinm like '_4031%'
OR n.ksppinm IN 
('_kghdsidx_count','_ksmg_granule_size','_memory_imm_mode_without_autosga','_memory_broker_stat_interval','cursor_sharing','event'))
ORDER BY 1;

SET HEADING OFF
SELECT '*****************************LARGE POOL**************************************' FROM dual;
SET HEADING ON
SELECT n.ksppinm name, v.KSPPSTVL value
FROM x$ksppi n, x$ksppsv v
WHERE n.indx = v.indx and (n.ksppinm like '%large_pool%' or n.ksppinm like 'parallel%' or n.ksppinm = '_kghdsidx_count')
ORDER BY 1;

SET HEADING OFF
SELECT '*****************************JAVA/STREAMS POOL**************************************' FROM dual;
SET HEADING ON
SELECT n.ksppinm name, v.KSPPSTVL value
FROM x$ksppi n, x$ksppsv v
WHERE n.indx = v.indx AND (n.ksppinm like '%_pool%'  OR n.ksppinm like 'java%' OR n.ksppinm IN ('_kghdsidx_count','_ksmg_granule_size','aq_tm_processes'))
ORDER BY 1;

SET HEADING OFF
SELECT '*****************************GRANULE DISTRIBUTION**************************************' FROM dual;
SET HEADING ON
SELECT DSIDX_KSMNWEX "DSIDX", CURDUR_KSMNWEX "DURATION",count(*) "GRANULES",substr('sga heap(' || DSIDX_KSMNWEX || ',' || (CURDUR_KSMNWEX - 1) || ')',1,20) "HEAP NAME"
FROM X$KSMSP_NWEX
group by DSIDX_KSMNWEX, CURDUR_KSMNWEX
order by DSIDX_KSMNWEX, CURDUR_KSMNWEX;

/* Current memory settings */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Current memory settings:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT component, current_size FROM v$sga_dynamic_components;

/* Memory resizing operations */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Memory resizing operations:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT start_time, end_time, component, oper_type, oper_mode, initial_size, target_size, final_size, status
FROM v$sga_resize_ops
ORDER BY 1, 2;

/* Historical memory resizing operations */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Historical memory resizing operations:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT start_time, end_time, component, oper_type, oper_mode, initial_size, target_size, final_size, status
FROM dba_hist_memory_resize_ops
ORDER BY 1, 2;

/* Shared pool 4031 information */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Shared pool 4031 information:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT request_failures, last_failure_size FROM v$shared_pool_reserved;

/* Shared pool reserved 4031 information */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Shared pool reserved 4031 information:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT requests, request_misses, free_space, avg_free_size, free_count, max_free_size FROM v$shared_pool_reserved;

/* Shared pool memory allocations by size */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Shared pool memory allocations by size:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT name, bytes FROM v$sgastat WHERE pool = 'shared pool' AND (bytes > 999999 OR name = 'free memory') ORDER BY bytes DESC;

/* Total shared pool usage */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Total shared pool usage:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT SUM(bytes) "Total Shared Pool Usage" FROM v$sgastat WHERE pool = 'shared pool' AND name != 'free memory';

/* Cursor sharability problems */
/* This version is for >= 10g; for <= 9i substitute ss.kglhdpar for ss.address!!!! */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Cursor sharability problems (this version is for >= 10g; for <= 9i substitute ss.kglhdpar for ss.address!!!!):' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT sa.sql_text,sa.version_count,ss.*
FROM v$sqlarea sa,v$sql_shared_cursor ss
WHERE sa.address=ss.address AND sa.version_count > 50
ORDER BY sa.version_count;

/* Java and Streams pool memory allocations by size */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Java and Streams pool memory allocations by size:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT pool, name, bytes FROM v$sgastat WHERE (pool = 'java pool' OR pool = 'streams pool') AND (bytes > 999999 OR name = 'free memory') ORDER BY bytes DESC;

/* Total pool usage */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Total pool usage:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT pool, SUM(bytes) "Total Pool Usage" FROM v$sgastat WHERE (pool = 'java pool' OR pool = 'streams pool') AND name != 'free memory' GROUP BY pool;

/* Large Pool memory usage */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Large Pool memory usage:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT SUM(bytes) "Total Large Pool Usage" FROM v$sgastat WHERE pool = 'large pool' AND name != 'free memory';
SELECT name, bytes FROM v$sgastat WHERE pool = 'large pool' ORDER BY bytes DESC;

/* Total UGA from session statistics */
SET HEADING OFF
SELECT '**************************************************************************************************************' FROM dual
UNION ALL
SELECT 'Total UGA from session statistics:' FROM dual
UNION ALL
SELECT '**************************************************************************************************************' FROM dual;
SET HEADING ON
SELECT SUM(value) "Total UGA" FROM v$sesstat s, v$statname n WHERE n.statistic# = s.statistic# AND name = 'session uga memory';

SET HEADING OFF MARKUP HTML OFF

SET SERVEROUTPUT ON FORMAT WRAP

DECLARE
    TYPE ptype IS RECORD(nam VARCHAR2(512), val VARCHAR2(512));
    TYPE paramstype IS TABLE OF ptype;
    commonparams       paramstype;
    banner             VARCHAR2(80);
    db_name            VARCHAR2(9);
    cpus               NUMBER;
    cpusers            NUMBER;
    def_servers_max    NUMBER;
    def_servers_target NUMBER;
    granule_size       NUMBER;
    large_pool         NUMBER;
    large_pool_abs     NUMBER;
    large_pool_asmm    NUMBER;
    large_pool_smax    NUMBER;
    large_pool_smin    NUMBER;
    large_pool_strgt   NUMBER;
    lp_servers         NUMBER;
    mem_tgt            NUMBER;
    min_msg_pool       NUMBER;
    msg_size           NUMBER;
    parbuf_hwm         NUMBER;
    parbuf_hwm_mem     NUMBER;
    parsvr_hwm         NUMBER;
    pga_agg            NUMBER;
    ptpcpu             NUMBER;
    servers_max        NUMBER;
    servers_min        NUMBER;
    servers_target     NUMBER;
    sga_tgt            NUMBER;
    subpools           NUMBER;
    use_lp             VARCHAR2(5);
    mfactor            NUMBER;
    nam                VARCHAR2(512);
    val                VARCHAR2(512);
    vsnmajor           NUMBER;
    vsnminor           NUMBER;
    params_sql         VARCHAR2(32767);

    FUNCTION getnumber(str IN VARCHAR2, cnt IN NUMBER) RETURN NUMBER
    IS
        dp NUMBER;
        s VARCHAR2(512);
    BEGIN
       s := str;
        FOR i IN 1..cnt-1
        LOOP
            s := SUBSTR(s, INSTR(s, '.', 1, 1)+1);
        END LOOP;
       RETURN SUBSTR(s, 1, INSTR(s, '.', 1, 1)-1);
    END;
   FUNCTION find_param_value(nam IN VARCHAR2) RETURN VARCHAR2
   IS
   BEGIN
      FOR i IN 1..commonparams.COUNT() LOOP
          IF commonparams(i).nam = nam
          THEN
              RETURN commonparams(i).val;
          END IF;
      END LOOP;
       RETURN '';
   END;
   FUNCTION find_param_value_num(nam IN VARCHAR2) RETURN NUMBER
   IS
   BEGIN
      FOR i IN 1..commonparams.COUNT() LOOP
          IF commonparams(i).nam = nam
          THEN
              RETURN TO_NUMBER(commonparams(i).val);
          END IF;
      END LOOP;
       RETURN 0;
   END;
   FUNCTION execcur(stmt IN VARCHAR2) RETURN VARCHAR2
   IS
        TYPE curtype IS REF CURSOR;
        stmtcur curtype;
   BEGIN
       OPEN stmtcur FOR stmt;
       FETCH stmtcur INTO val;
       CLOSE stmtcur;
       RETURN val;
   END;
BEGIN
    /* Get db ID */
    SELECT DISTINCT name INTO db_name FROM v$database;
    SELECT DISTINCT banner INTO banner FROM v$version WHERE banner LIKE 'Oracle Database%';
    vsnmajor := getnumber(SUBSTR(banner, INSTR(banner, 'Release') + 8), 1);
    vsnminor := getnumber(SUBSTR(banner, INSTR(banner, 'Release') + 8), 2);

    params_sql := 'SELECT n.ksppinm name, v.ksppstvl value ' ||
        'FROM x$ksppi n, x$ksppsv v ' ||
        'WHERE n.indx = v.indx ' ||
        'AND n.ksppinm IN (''_PX_use_large_pool'', ''_kghdsidx_count'', ''_ksmg_granule_size'', ''_parallel_min_message_pool'', ' ||
            '''cpu_count'',''large_pool_size'', ''parallel_execution_message_size'', ''parallel_max_servers'', ' ||
            '''parallel_min_servers'', ''parallel_threads_per_cpu'', ''pga_aggregate_target'', ''sga_target'', ' ||
            '''memory_target'', ''parallel_servers_target'') ORDER BY 1';
    EXECUTE IMMEDIATE params_sql BULK COLLECT INTO commonparams;
    use_lp := find_param_value('_PX_use_large_pool');
    subpools := find_param_value_num('_kghdsidx_count');
    granule_size := find_param_value_num('_ksmg_granule_size');
    min_msg_pool := find_param_value_num('_parallel_min_message_pool');
    cpus := find_param_value_num('cpu_count');
    large_pool := find_param_value_num('large_pool_size');
    mem_tgt := find_param_value_num('memory_target');
    msg_size := find_param_value_num('parallel_execution_message_size');
    servers_max := find_param_value_num('parallel_max_servers');
    servers_min := find_param_value_num('parallel_min_servers');
    servers_target := find_param_value_num('parallel_servers_target');
    ptpcpu := find_param_value_num('parallel_threads_per_cpu');

    IF (vsnmajor <= 10)
    THEN
        pga_agg := find_param_value('pga_aggregate_target');
        sga_tgt := find_param_value('sga_target');
        large_pool_asmm := execcur('select current_size from v$sga_dynamic_components where component = ''large pool''');
    ELSE
        pga_agg := execcur('SELECT current_size FROM v$sga_dynamic_components WHERE component = ''PGA Target''');
        sga_tgt := execcur('SELECT current_size FROM v$sga_dynamic_components WHERE component = ''SGA Target''');
        large_pool_asmm := execcur('SELECT current_size FROM v$sga_dynamic_components WHERE component = ''large pool''');
    END IF;
    parsvr_hwm := execcur('SELECT value FROM v$pq_sysstat WHERE statistic LIKE ''Servers Highwater%''');
    parbuf_hwm := execcur('SELECT value FROM v$px_process_sysstat WHERE statistic LIKE ''Buffers HWM%''');

    DBMS_OUTPUT.PUT_LINE('<pre>');

    /* Perform calculations and display results */
    DBMS_OUTPUT.PUT_LINE(vsnmajor || 'R' || vsnminor || ': CALCULATIONS for the LARGE_POOL_SIZE with parallel processing.');
    DBMS_OUTPUT.PUT_LINE('Version 2.0, 2014.');
    DBMS_OUTPUT.PUT_LINE('Database Identification:');
    DBMS_OUTPUT.PUT_LINE('The database name is ' || db_name || '.');
    DBMS_OUTPUT.PUT_LINE('Version: ' || banner);
    DBMS_OUTPUT.PUT_LINE('LARGE_POOL_SIZE:');
    large_pool := large_pool/1024/1024;
    DBMS_OUTPUT.PUT_LINE('The initial setting is ' || large_pool || 'Mb.');
    IF large_pool = 0
    THEN
        DBMS_OUTPUT.PUT('If set, the ');
    ELSE
        DBMS_OUTPUT.PUT('The ');
    END IF;
    large_pool_abs := (granule_size * subpools)/1024/1024;
    dbms_output.put_line('absolute minimum is ' || large_pool_abs || 'Mb (a lower non-0 value is over-ridden).');
    large_pool_asmm := large_pool_asmm/1024/1024;
    IF sga_tgt > 0
    THEN
        DBMS_OUTPUT.PUT_LINE('The current dynamic size is ' || large_pool_asmm || 'Mb.');
    END IF;
    /* Parallel processing */
    DBMS_OUTPUT.PUT_LINE('Parallel Processing:');
    IF servers_min > 0
    THEN
        large_pool_smin := (granule_size * (servers_min + 2))/1024/1024; /* From unpublished Bug 13096841 */
        DBMS_OUTPUT.PUT_LINE('For parallel_min_servers=' || servers_min || ', the minimum Large Pool is ' ||
            large_pool_smin || 'Mb.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The parallel_min_servers setting is 0.');
    END IF;
    IF vsnmajor >= 11
    THEN
        /* Calculate Concurrent Parallel Users */
        cpusers := 1;
        IF pga_agg > 0
        THEN
            cpusers := 2;
            IF sga_tgt > 0
            THEN
                cpusers := 4;
            END IF;
        END IF;
        IF mem_tgt > 0
        THEN
           cpusers := 4;
        END IF;
        IF (vsnmajor > 11 OR vsnminor >= 2)
        THEN
            IF servers_target > 0
            THEN
                large_pool_strgt := (granule_size * servers_target)/1024/1024/2; /* assume 2 servers use 1 granule */
                DBMS_OUTPUT.PUT_LINE('For parallel_servers_target=' || servers_target || ', the Large Pool may grow to ' ||
                    large_pool_strgt || 'Mb.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('The parallel_servers_target setting is 0');
            END IF;
        END IF;
    END IF;
    /* Calculate the default for parallel_max_servers */
    IF (vsnmajor <= 10)
    THEN
        /* 10.2 Data Warehousing formula: (CPU_COUNT x PARALLEL_THREADS_PER_CPU x (2 if PGA_AGGREGATE_TARGET > 0; otherwise 1) x 5) */
        IF pga_agg > 0
        THEN
            mfactor := 10;
        ELSE
            mfactor := 5;
        END IF;
        def_servers_max := cpus * ptpcpu * mfactor;
    ELSE
        /* 11.2 PARALLEL_THREADS_PER_CPU x CPU_COUNT x concurrent_parallel_users x 5 */
        def_servers_max := ptpcpu * cpus * cpusers * 5;
    END IF;
    /* Calculate Large Pool usage (theoretical) */
    IF servers_max > 0
    THEN
        lp_servers := servers_max;
    ELSE
        lp_servers := def_servers_max;
    END IF;
    large_pool_smax := (granule_size * lp_servers)/1024/1024/2; /* assume 2 servers use 1 granule */
    IF servers_max > 0
    THEN
        DBMS_OUTPUT.PUT('For parallel_max_servers=' || servers_max );
    ELSE
        DBMS_OUTPUT.PUT_LINE('No Parallelism because parallel_max_servers=0.');
        IF (vsnmajor <= 10)
        THEN
            DBMS_OUTPUT.PUT('If enabled');
        ELSE
            DBMS_OUTPUT.PUT('If enabled with the parallel_max_servers DEFAULT');
        END IF;
    END IF;
    DBMS_OUTPUT.PUT_LINE(', the Large Pool may grow to ' || large_pool_smax || 'Mb.');
    IF (vsnmajor > 11 OR (vsnmajor = 11 AND vsnminor >= 2))
    THEN
        /* Calculate the default for parallel_servers_target */
        /* 11.2 PARALLEL_THREADS_PER_CPU * CPU_COUNT * concurrent_parallel_users * 2 */
        def_servers_target := ptpcpu * cpus * cpusers * 2;
        DBMS_OUTPUT.PUT_LINE('The DEFAULT for parallel_servers_target is ' || def_servers_target || ' (over-rides 0 setting).');
    END IF;
    DBMS_OUTPUT.PUT_LINE('The DEFAULT for parallel_max_servers is ' || def_servers_max || '.');
    /* Additional PX information */
    DBMS_OUTPUT.PUT_LINE('Additional:');
    DBMS_OUTPUT.PUT('The Parallel Servers High Water Mark is ');
    IF parsvr_hwm > 0
    THEN
        DBMS_OUTPUT.PUT_LINE(parsvr_hwm || '.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('currently 0 (yet to be set).');
    END IF;
    DBMS_OUTPUT.PUT('This instance will put the "PX msg pool" allocation in the ');
    IF sga_tgt = 0 AND use_lp != 'TRUE'
    THEN
        DBMS_OUTPUT.PUT_LINE('Shared Pool.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Large Pool.');
    END IF;
    DBMS_OUTPUT.PUT('The initial size of the "PX msg pool" allocation ');
    IF min_msg_pool > 0
    THEN
        DBMS_OUTPUT.PUT_LINE('is ' || min_msg_pool || ' bytes.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('has been manually set to 0.');
    END IF;
    DBMS_OUTPUT.PUT('The Parallel Buffers High Water Mark is ');
    IF parbuf_hwm > 0
    THEN
        DBMS_OUTPUT.PUT_LINE(parbuf_hwm || ' buffers,');
        parbuf_hwm_mem := parbuf_hwm * msg_size;
        DBMS_OUTPUT.PUT_LINE('that required ' || parbuf_hwm_mem || ' bytes of memory.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('currently 0.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('</pre>');
END;
/
SPOOL OFF
@@?/rdbms/admin/sqlsessend.sql
EXIT
