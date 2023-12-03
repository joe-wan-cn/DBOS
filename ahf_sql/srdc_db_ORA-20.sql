Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_ORA-20.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_ORA-20.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_ORA-20.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_ORA-20.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - gather info for ORA-20 issues
Rem    bburton     09/22/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_db_ORA-20.sql
REM collect Database Characterset details for troubleshooting National characterset related issues.
define SRDCNAME='DB_ORA-20'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name : ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine : ' , host_name from v$instance
union all
select 'Version : ',version from v$instance
union all
select 'DBName : ',name from v$database
union all
select 'Instance : ',instance_name from v$instance
/
set echo on
--********************PROCESSES parameter setting********************
show parameter processes
--********************Session details********************
select p.username "OS USERNAME",p.terminal,p.program,s.username" DBUSERNAME", s.command,s.status,s.server,s.process,s.machine,s.port,s.terminal,s.program,s.sid,s.serial#,p.spid FROM v$session s,v$process p WHERE p.addr=s.paddr order by p.background desc
/
--********************Resource Limit********************
select * from v$resource_limit where RESOURCE_NAME='processes'
/
--********************Sessions from Oraagent********************
select process,osuser, count(process) from v$session where program like '%oraagent%' group by process,osuser
/
--********************Count of user sessions********************
select count(*) from v$session
/
select count(*) from v$process
/
--********************Historical data********************
select * from DBA_HIST_RESOURCE_LIMIT where RESOURCE_NAME='processes' order by snap_id
/
select SNAP_ID,BEGIN_INTERVAL_TIME,END_INTERVAL_TIME from DBA_HIST_SNAPSHOT where BEGIN_INTERVAL_TIME>sysdate-2
/

spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
@?/rdbms/admin/sqlsessend.sql
 
