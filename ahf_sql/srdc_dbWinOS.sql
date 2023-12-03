Rem srdc_dbWinOS.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_dbWinOS.sql - script to collect  diagnostic details required for troubleshooting 
Rem                       database issues on Windows platform.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to single instance 
Rem		   issues, for both multitenant and non-multitenant architecture.
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
Rem       03/105/19  - created the script
Rem
Rem
Rem
Rem
Rem   
@@?/rdbms/admin/sqlsessstart.sql
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_WinOS'
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
--12c Specific
select * from v$pdbs
/
show parameter USE_INDIRECT_DATA_BUFFERS
show parameter DB_BLOCK_BUFFERS
show parameter cache
SELECT a.ksppinm "Parameter",b.ksppstvl "Session Value",c.ksppstvl "Instance Value" FROM sys.x$ksppi a, sys.x$ksppcv b, sys.x$ksppsv c WHERE a.indx = b.indx AND a.indx = c.indx AND a.ksppinm LIKE '%kill_java%'
/

set echo off
prompt
prompt ============================================================================================
prompt                         ++ Processes ++
prompt ============================================================================================
prompt
set echo on

select count (*) from v$process
/
select status,count(*) from v$session group by status
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ PGA Usage ++
prompt ============================================================================================
prompt
set echo on

select sum(bytes)/1024/1024 mb from
  (select bytes from v$sgastat
  union
  select value bytes from v$sesstat s, v$statname n where n.STATISTIC# = s.STATISTIC# and n.name = 'session pga memory' )
/
select sum(pga_used_mem)/(1024*1024),sum(pga_alloc_mem)/(1024*1024) from v$process
/
select max(pga_used_mem) from v$process
/
select username,serial#,sid from v$session where paddr=(select addr from v$process where pga_used_mem=(select max(pga_used_mem) from v$process))
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
