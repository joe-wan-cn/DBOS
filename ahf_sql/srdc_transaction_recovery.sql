Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_transaction_recovery.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_transaction_recovery.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_transaction_recovery.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_transaction_recovery.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    10/13/17 - Adding exit at the end of the script
Rem    recornej    10/06/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

REM srdc_transaction_recovery.sql
REM collect information about undo and dead transactions
define SRDCNAME='Transaction_recovery'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine ' , host_name from v$instance
union all
select 'Version ',version from v$instance
union all
select 'DBName ',name from v$database
union all
select 'Instance ',instance_name from v$instance
/
set echo on
--***********************Information about transactions **********************
alter session set nls_date_format='dd-mon-yyyy hh24:mi:ss'
/
select sysdate from dual
/
show parameter fast_start_parallel_rollback
/
select ktuxeusn USN, ktuxeslt Slot, ktuxesqn Seq, ktuxesta State,ktuxesiz Undo from x$ktuxe where ktuxesta <> 'INACTIVE' and ktuxecfl like '%DEAD%' order by ktuxesiz asc
/
Select usn, state, undoblockstotal "Total", undoblocksdone "Done", undoblockstotal-undoblocksdone "ToDo", decode(cputime,0,'unknown',sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400))
"Estimated time to complete" from v$fast_start_transactions
/
select * from v$fast_start_servers
/
select ktuxeusn, to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Time", ktuxesiz, ktuxesta from x$ktuxe where ktuxecfl = 'DEAD'
/
set echo off 
set sqlprompt "SQL> " term on 
set verify on 
spool off
set markup html off spool off 
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set echo on
exit

@?/rdbms/admin/sqlsessend.sql
 
