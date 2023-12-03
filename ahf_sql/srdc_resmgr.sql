Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_resmgr.sql /main/1 2021/06/01 13:25:12 bvongray Exp $
Rem
Rem srdc_resmgr.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_resmgr.sql - script to collect Oracle Resource Manager related diagnostic data 
Rem
Rem    NOTES
Rem      * This script collects the data related to the Resource Manager setting and resource utilization in the database
Rem		   and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_resmgr.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem    slabraha   26/01/2021 - created script
Rem
Rem
Rem
@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_RESMGR'
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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
REM === -- end of standard header -- ===
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Database Details ++
prompt ============================================================================================
prompt
set echo on
select * from gv$version
/
select 'Instance_status' "CHECK_NAME",sysdate, instance_name,startup_time,instance_role from gv$instance
/
SELECT 'Database_status' "CHECK_NAME",name,platform_id,open_mode from v$database
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Parameter Setting ++
prompt ============================================================================================
prompt
set echo on
SELECT name, value FROM v$parameter WHERE upper(name) in ('COMPATIBLE','STATISTICS_LEVEL','TIMED_STATISTICS','RESOURCE_MANAGER_PLAN','CPU_COUNT','DB_PERFORMANCE_PROFILE')
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Resource Manager Configuration ++
prompt ============================================================================================
prompt
set echo on
SELECT * FROM DBA_RSRC_MANAGER_SYSTEM_PRIVS
/
SELECT * FROM DBA_RSRC_CONSUMER_GROUP_PRIVS
/
SELECT * FROM DBA_RSRC_CONSUMER_GROUPS
/
SELECT * FROM DBA_RSRC_PLANS
/
SELECT * FROM DBA_RSRC_PLAN_DIRECTIVES order by plan
/
SELECT * FROM V$RSRC_CONSUMER_GROUP
/
SELECT * FROM V$RSRC_CONSUMER_GROUP_CPU_MTH
/
SELECT * FROM V$RSRC_PLAN
/
SELECT * FROM V$RSRC_PLAN_CPU_MTH
/
SELECT * FROM DBA_RSRC_MAPPING_PRIORITY
/
SELECT * FROM DBA_RSRC_GROUP_MAPPINGS
/
SELECT * FROM V$RSRC_CONS_GROUP_HISTORY
/
SELECT * FROM V$RSRC_PLAN_HISTORY
/
SELECT * FROM V$RSRC_SESSION_INFO
/
SELECT * FROM V$RSRCMGRMETRIC order by BEGIN_TIME,END_TIME,CONSUMER_GROUP_ID
/
SELECT * FROM V$RSRCMGRMETRIC_HISTORY order by BEGIN_TIME,END_TIME,CONSUMER_GROUP_ID
/
select * from DBA_RSRC_CATEGORIES
/
select * from DBA_RSRC_IO_CALIBRATE
/
select * from V$RSRC_PDB order by pdb_name
/
select * from V$RSRC_PDB_HISTORY order by pdb_name,sequence#
/
select * from V$RSRCPDBMETRIC order by SEQUENCE#
/
select * from V$RSRCPDBMETRIC_HISTORY order by SEQUENCE#
/

set echo off
prompt
prompt ============================================================================================
prompt                         ++ Resource Manager CPU Usage and related checks ++
prompt ============================================================================================
prompt
set echo on

---********************** Diag Info for "resmgr:cpu quantum" from BUG:26095326 *******************
set serveroutput on
declare

 version                 varchar2(512) := 'bug-26095326_diag.sql version 01';
 starting_time           date;
 ending_time             date;
 tmp_time                date;
 message                 varchar2(512);
 os_cpu_count            simple_integer := 0;
 min_cpu_wt_time         simple_integer := 0;
 sample_interval         interval day (3) to second;
 interval_seconds        simple_integer := 0;
 consecutive_intervals   simple_integer := 0;
 over_throttle_samples   simple_integer := 0;

begin

 -- Determine starting and ending times for the overthrottling checks
 --
 select sysdate + to_number(-1) / (24) into starting_time from dual;  -- one hour ago
 select sysdate into ending_time from dual;                           -- now

 -- Determine the minimum CPU wait time required for an overthrottling sample
 --
 select value into os_cpu_count from v$osstat where stat_name = 'NUM_CPUS';
 min_cpu_wt_time := os_cpu_count * 60000 / 10;

 message := CHR(10) ||
            version || CHR(10) || CHR(10) ||
            'start time: ' || to_char(starting_time, 'YYYY-MM-DD HH24:MI') || ' (1 hour ago)' || CHR(10) ||
            'end time:   ' || to_char(ending_time, 'YYYY-MM-DD HH24:MI') || ' (now)';
 DBMS_OUTPUT.put_line(message);

 declare

   -- This cursor gets all samples to be checked.
   --
   CURSOR all_stats_cur IS
     with      rm_stats as
               (select    to_char(end_time, 'YYYY-MM-DD HH24:MI') "TIME_OF_SAMPLE",
                          avg(num_cpus) "NUM_CPUS",
                          sum(cpu_consumed_time) "CPU_CONSUMED_TIME",
                          sum(cpu_wait_time) "CPU_WAIT_TIME",
                          sum(avg_cpu_utilization) "AVG_CPU_UTIL",
                          sum(AVG_RUNNING_SESSIONS) "RM_AVG_RNG",
                          sum(AVG_WAITING_SESSIONS) "RM_AVG_WTG"
                from      v$rsrcmgrmetric_history
                where     end_time >= starting_time and end_time <= ending_time
                          and plan_name is not null
                group by  to_char(end_time, 'YYYY-MM-DD HH24:MI')
                order by  to_char(end_time, 'YYYY-MM-DD HH24:MI')),

               sys_stats as
               (select    to_char(end_time, 'YYYY-MM-DD HH24:MI') "TIME_OF_SAMPLE",
                          value "OS_CPU_UTIL"
                from      v$sysmetric_history
                where     metric_name = 'Host CPU Utilization (%)'
                          and INTSIZE_CSEC > 2000
                order by  end_time),

               os_stats as
               (select    value "OS_CPUS"
                from      v$osstat
                where     stat_name = 'NUM_CPUS')

     select    rm.time_of_sample, rm.num_cpus,
               rm.cpu_wait_time, rm.cpu_consumed_time, rm.avg_cpu_util,
               rm.rm_avg_rng, rm.rm_avg_wtg,
               os.os_cpus, sys.os_cpu_util
     from      rm_stats rm, sys_stats sys, os_stats os
     where     rm.time_of_sample = sys.time_of_sample
     order by  time_of_sample;

   -- This cursor gets the over-throttling samples to be considered.
   --
   CURSOR over_throttle_cur IS
     with      rm_stats as
               (select    to_char(end_time, 'YYYY-MM-DD HH24:MI') "TIME_OF_SAMPLE",
                          avg(num_cpus) "NUM_CPUS",
                          sum(cpu_consumed_time) "CPU_CONSUMED_TIME",
                          sum(cpu_wait_time) "CPU_WAIT_TIME",
                          sum(avg_cpu_utilization) "AVG_CPU_UTIL",
                          sum(AVG_RUNNING_SESSIONS) "RM_AVG_RNG",
                          sum(AVG_WAITING_SESSIONS) "RM_AVG_WTG"
                from      v$rsrcmgrmetric_history
                where     end_time >= starting_time and end_time <= ending_time
                          and plan_name is not null
                group by  to_char(end_time, 'YYYY-MM-DD HH24:MI')
                order by  to_char(end_time, 'YYYY-MM-DD HH24:MI')),

               sys_stats as
               (select    to_char(end_time, 'YYYY-MM-DD HH24:MI') "TIME_OF_SAMPLE",
                          value "OS_CPU_UTIL"
                from      v$sysmetric_history
                where     metric_name = 'Host CPU Utilization (%)'
                          and INTSIZE_CSEC > 2000
                order by  end_time),

               os_stats as
               (select    value "OS_CPUS"
                from      v$osstat
                where     stat_name = 'NUM_CPUS')

     select    rm.time_of_sample, rm.num_cpus,
               rm.cpu_wait_time, rm.cpu_consumed_time, rm.avg_cpu_util,
               rm.rm_avg_rng, rm.rm_avg_wtg,
               os.os_cpus, sys.os_cpu_util
     from      rm_stats rm, sys_stats sys, os_stats os
     where     rm.time_of_sample = sys.time_of_sample
               /* the over-throttling checks go here... */
               and (rm.rm_avg_rng < 0.90 * rm.num_cpus)
               and (rm.cpu_wait_time > min_cpu_wt_time)
     order by  time_of_sample;

 begin

   -- Display all samples
   --
   message := CHR(10) || 'ALL SAMPLES:';
   DBMS_OUTPUT.put_line(message);
   message := CHR(10) || 'TIME_OF_SAMPLE   RM_CPUS RM_AVG_RNG RM_AVG_WTG OS_CPUS OS_CPU_UTIL';
   DBMS_OUTPUT.put_line(message);
   message :=            '---------------- ------- ---------- ---------- ------- -----------';
   DBMS_OUTPUT.put_line(message);

   for all_stats_rec in all_stats_cur
   loop
 
     message := all_stats_rec.time_of_sample
                || ' ' || to_char(all_stats_rec.num_cpus, '999999')
                || ' ' || to_char(all_stats_rec.rm_avg_rng, '999999.99')
                || ' ' || to_char(all_stats_rec.rm_avg_wtg, '999999.99')
                || ' ' || to_char(all_stats_rec.os_cpus, '999999')
                || ' ' || to_char(all_stats_rec.os_cpu_util, '9999999.99')
     ;
     DBMS_OUTPUT.put_line(message);
 
   end loop;

   -- Display the overthrottling samples.
   --
   message := CHR(10) || 'OVERTHROTTLE SAMPLES:';
   DBMS_OUTPUT.put_line(message);
   message := CHR(10) || 'TIME_OF_SAMPLE   RM_CPUS RM_AVG_RNG RM_AVG_WTG OS_CPUS OS_CPU_UTIL';
   DBMS_OUTPUT.put_line(message);
   message :=            '---------------- ------- ---------- ---------- ------- -----------';
   DBMS_OUTPUT.put_line(message);

   tmp_time := to_date('2000-01-01 00:00', 'YYYY-MM-DD HH24:MI');
   consecutive_intervals := 0;

   for over_throttle_rec in over_throttle_cur
   loop
 
     if (consecutive_intervals = 0)
     then
       tmp_time := to_date(over_throttle_rec.time_of_sample, 'YYYY-MM-DD HH24:MI');
     end if;

     sample_interval := (to_date(over_throttle_rec.time_of_sample, 'YYYY-MM-DD HH24:MI') - tmp_time) day to second;

     interval_seconds := extract( second from sample_interval )
       + extract( minute from sample_interval ) * 60
       + extract( hour from sample_interval ) * 60 * 60
       + extract( day from sample_interval ) * 60 * 60 * 24;

     if (interval_seconds < 70)
     then
       consecutive_intervals := consecutive_intervals + 1;
     else
       consecutive_intervals := 0;
     end if;

     -- only show over-throttling samples where 2 or more consecutive samples occurred
     --
     if (consecutive_intervals >= 2)
     then
       message := over_throttle_rec.time_of_sample
                  || ' ' || to_char(over_throttle_rec.num_cpus, '999999')
                  || ' ' || to_char(over_throttle_rec.rm_avg_rng, '999999.99')
                  || ' ' || to_char(over_throttle_rec.rm_avg_wtg, '999999.99')
                  || ' ' || to_char(over_throttle_rec.os_cpus, '999999')
                  || ' ' || to_char(over_throttle_rec.os_cpu_util, '9999999.99')
                  ;
       DBMS_OUTPUT.put_line(message);
       over_throttle_samples := over_throttle_samples + 1;
     end if;
 
     tmp_time := to_date(over_throttle_rec.time_of_sample, 'YYYY-MM-DD HH24:MI');

   end loop;

   message := CHR(10) || 'Number of over-throttling samples found: ' || over_throttle_samples;
   DBMS_OUTPUT.put_line(message);

 end;
 
end;
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ PDB related checks - 12c specific ++
prompt ============================================================================================
prompt
set echo on
SHOW con_name
/
select NAME,CDB from v$database
/
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS
/
select * from v$pdbs
/
select * from pdb_spfile$
/
SELECT PDB, NETWORK_NAME, CON_ID FROM CDB_SERVICES   WHERE PDB IS NOT NULL AND CON_ID > 2 ORDER BY PDB
/
SELECT DB_NAME, CON_ID, PDB_NAME, OPERATION, OP_TIMESTAMP, CLONED_FROM_PDB_NAME  FROM CDB_PDB_HISTORY  WHERE CON_ID > 2  ORDER BY CON_ID
/
select cause, type, message from PDB_PLUG_IN_VIOLATIONS where status='PENDING' 
/
SELECT PLAN, STATUS, COMMENTS FROM DBA_CDB_RSRC_PLANS ORDER BY PLAN
/
SELECT PLAN,PLUGGABLE_DATABASE,SHARES,UTILIZATION_LIMIT,PARALLEL_SERVER_LIMIT
  FROM DBA_CDB_RSRC_PLAN_DIRECTIVES
  ORDER BY PLAN
/
set echo off
prompt
prompt ============================================================================================
prompt            +++++++++++++++++++++End of SRDC Data Collection+++++++++++++ 
prompt ============================================================================================
prompt
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT======================================================================================================================================
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem======================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
exit;
