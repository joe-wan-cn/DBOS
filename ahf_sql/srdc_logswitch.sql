Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_logswitch.sql /main/1 2021/07/26 08:55:41 bvongray Exp $
Rem
Rem srdc_logswitch.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_logswitch.sql - script to collect checkpoint and Log Switch related diagnostic data
Rem
Rem    DESCRIPTION
Rem     cript to collect checkpoint and Log Switch related diagnostic data
Rem
Rem    NOTES
Rem      * This script collects the data related to the Log Switch issues
Rem                including the configuration, parameters , statistics etc
Rem                and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_logswitch.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_logswitch.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/22/21 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_LOGSWITCH'
set long 2000000000
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
set echo off
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '      ||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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

set echo off
prompt
prompt ============================================================================================
prompt                     ++ Checkpoint and log file switch configurations ++
prompt ============================================================================================
prompt
set echo on

select l.thread#, l.group#, l.bytes/1024/1024 as size_MB, l.status, lf.member 
from v$log l,v$logfile lf
where l.group# = lf.group#
order by l.thread#, l.group#;

set echo off
prompt **** v$logfile ****
set echo on

select * from v$logfile order by 1;

set echo off
prompt **** v$log ****
set echo on

select * from v$log order by 1,2;

set echo off
prompt **** v$database ****
set echo on

select * from v$database;

set echo off
prompt **** archive log list ****
set echo on

archive log list

set echo off
prompt **** log related parameters ****
set echo on
select name,value from v$parameter where name in (
    'log_checkpoint_interval',
    'log_checkpoint_timeout',
    'log_checkpoints_to_alert',
    'fast_start_mttr_target',
    'commit_logging'
    ) order by 1;

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
