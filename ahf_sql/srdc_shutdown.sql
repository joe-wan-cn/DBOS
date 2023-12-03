Rem srdc_shutdown.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_shutdown.sql - script to collect  diagnostic details required for troubleshooting 
Rem                         database startup related issues.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to single instance 
Rem		   shutdown , for both multitenant and non-multitenant architecture.
Rem		 * The checks here might not be enough for troubleshooting issues on RAC or dataguard. 
REM			Check the respective SRDC document for the complete set of data.
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
Rem       02/19/19  - created the script
Rem
Rem
Rem
Rem
Rem   
@@?/rdbms/admin/sqlsessstart.sql
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_SHUTDOWN'
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
prompt                         ++ Transaction recovery related checks ++
prompt ============================================================================================
prompt
set echo on
show parameter fast_start_parallel_rollback
/

--*******************Dead Transactions*******************

select * from x$ktuxe where ktuxecfl = 'DEAD'
/
--*******************Long running Transactions*******************
select count(*) from v$session_longops where time_remaining>0
/
select sum(used_ublk) from v$transaction
/
--********************Ongoing Jobs********************
select owner, job_name, session_id, slave_os_process_id, running_instance from dba_scheduler_running_jobs
/
--********************Recovery********************
select * from gv$fast_start_transactions
/
select * from gv$fast_start_servers
/
Select usn, state, undoblockstotal "Total", undoblocksdone "Done", undoblockstotal-undoblocksdone "ToDo", decode(cputime,0,'unknown',sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400))
"Estimated time to complete" from v$fast_start_transactions
/

set echo off
prompt
prompt ============================================================================================
prompt                         ++ PDB related checks - 12c specific ++
prompt ============================================================================================
prompt
set echo on

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
select * from PDB_PLUG_IN_VIOLATIONS
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