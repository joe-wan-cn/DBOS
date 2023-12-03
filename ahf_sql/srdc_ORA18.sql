Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_ORA18.sql /main/1 2019/08/20 06:38:51 xiaodowu Exp $
Rem
Rem srdc_ORA18.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_ORA18.sql
Rem
Rem    DESCRIPTION
Rem      Called by ORA-18 SRDC collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_ORA18.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    08/14/19 - Called by ORA-18 SRDC collection
Rem    xiaodowu    08/14/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
Rem srdc_ORA18.sql
Rem
Rem Copyright (c) 2006, 2019, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_ORA18.sql - script to collect  diagnostic details required for  
Rem                       troubleshooting ORA-18 and other SESSIONS related issues.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to single instance 
Rem		   shutdown , for both multitenant and non-multitenant architecture.
Rem		 * The checks here might not be enough for troubleshooting issues . 
Rem		   on RAC or Dataguard. Check the respective SRDC document for 
Rem		   the complete set of data.
Rem		 * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    slabraha   04/23/19  - updated the script
Rem    slabraha   04/17/19  - created the script
Rem
Rem
Rem
Rem
Rem   
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_ORA18'
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
set echo on
set serveroutput on
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
select * from v$instance
/
select * from v$database
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Resource Limit and License++
prompt ============================================================================================
prompt
set echo on
select * from v$resource_limit
/
select * from v$license
/
select sessions_max,sessions_warning,sessions_current,sessions_highwater  from v$license
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ SESSIONS Usage ++
prompt ============================================================================================
prompt
set echo on

--********************All initialized sessions********************
select count(*) from x$ksuse where bitand(ksspaflg,1) !=0
/
--********************Count of user sessions********************
select count(*) from v$session
/
select username,count(*) from v$session group by username
/
select server, count(*) from v$session group by server
/
select service_name,count(*) from v$session group by service_name
/
SELECT SYSDATE,SID,SERIAL#,USERNAME,PROGRAM,MODULE,LOGON_TIME,STATUS FROM V$SESSION
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Sessions , processed and profile setting ++
prompt ============================================================================================
prompt
set echo on
select name,value,ismodified from sys.v$parameter where name in ('sessions','processes')
/
select highwater from DBA_HIGH_WATER_MARK_STATISTICS where name = 'SESSIONS'
/
show parameter sessions
show parameter processes
SELECT * FROM DBA_PROFILES
/
select p.CON_ID , p.name , s.NAME, s.VALUE$ from v$pdbs p ,  pdb_spfile$ s where s.name='sessions' and s.PDB_UID=p.DBID
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Historical details ++
prompt ============================================================================================
prompt
set echo on

select max(AVERAGE),max(MAXVAL), METRIC_UNIT from dba_hist_sysmetric_summary where  METRIC_ID =2143 group by METRIC_UNIT
/
select 'Highest_Concurrent_sessions_period' "CHECK_NAME" ,INSTANCE_NUMBER, BEGIN_TIME, END_TIME, METRIC_NAME, AVERAGE, MAXVAL, METRIC_UNIT from dba_hist_sysmetric_summary where  METRIC_ID =2143 and rownum <10 order by maxval desc
/
select 'Session_details_for_24Hrs' "CHECK_NAME" ,INSTANCE_NUMBER, BEGIN_TIME, END_TIME, METRIC_NAME, AVERAGE, MAXVAL, METRIC_UNIT from dba_hist_sysmetric_summary where  METRIC_ID in (select METRIC_ID from v$sysmetric_history where lower(METRIC_NAME) like '%session count%') and BEGIN_TIME > sysdate -1
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Database Registry ++
prompt ============================================================================================
prompt
set echo on
select * from dba_registry
/
SELECT action_time, action, namespace, version, id, comments FROM dba_registry_history ORDER by action_time desc
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
 
