Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_ora-30036.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_undo_ora-30036.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_undo_ora-30036.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_ora-30036.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - collect Undo parameters and segment details for
Rem                           troubleshooting ORA-30036 issues
Rem    bburton     09/22/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_db_undo_ora-30036.sql
REM collect Undo parameters and segment details for troubleshooting ORA-30036 issues.
define SRDCNAME='DB_Undo_ORA-30036'
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

--***********************Undo Parameters**********************

SELECT a.ksppinm "Parameter",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value"
FROM sys.x$ksppi a, sys.x$ksppcv b, sys.x$ksppsv c
WHERE a.indx = b.indx
AND a.indx = c.indx
AND a.ksppinm in ( '_undo_autotune' , '_smu_debug_mode' ,
'_highthreshold_undoretention' ,
'undo_tablespace' , 'undo_retention' , 'undo_management' )
order by 2
/
--**********************Tuned Undo Retention**********************
SELECT MAX(TUNED_UNDORETENTION), MAX(MAXQUERYLEN),SUM(NOSPACEERRCNT),SUM(EXPSTEALCNT) FROM V$UNDOSTAT;

--**********************Status of the undo blocks**********************

select tablespace_name, 
round(sum(case when status = 'UNEXPIRED' then bytes else 0 end) / 1048675,2) unexp_MB ,
round(sum(case when status = 'EXPIRED' then bytes else 0 end) / 1048576,2) exp_MB ,
round(sum(case when status = 'ACTIVE' then bytes else 0 end) / 1048576,2) act_MB 
from dba_undo_extents group by tablespace_name
/
select count(*) from dba_rollback_segs where status='OFFLINE'
/
--**********************Free space available within the Undo tablespace**********************

SELECT SUM(BYTES) FROM DBA_FREE_SPACE WHERE TABLESPACE_NAME in (select value from v$parameter where name= 'undo_tablespace')
/
SELECT file_name,autoextensible,bytes/ 1048576 FROM dba_data_files WHERE tablespace_name in (select value from v$parameter where name= 'undo_tablespace' )
/
--**********************FBDA related information**********************

SELECT a.ksppinm "Parameter",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value"
FROM sys.x$ksppi a, sys.x$ksppcv b, sys.x$ksppsv c
WHERE a.indx = b.indx
AND a.indx = c.indx
AND a.ksppinm LIKE '%flashback_archiver%' 
/
set echo off 
set sqlprompt "SQL> " term on 
set verify on 
spool off
set markup html off spool off 
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set echo on
@?/rdbms/admin/sqlsessend.sql
