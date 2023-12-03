Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_perf_explain.sql /main/1 2021/10/12 12:46:51 bvongray Exp $
Rem
Rem srdc_spatial_perf_explain.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_spatial_perf_explain.sql - Spatial Version Check
Rem
Rem    DESCRIPTION
Rem      Collects the execution plan of a Spatial query
Rem
Rem    NOTES
Rem      .
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_perf_explain.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/24/21 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='SPATIAL_PERF_EXPLAIN'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
       to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name: ' || '&&SRDCNAME'  as "SRDC COLLECTION HEADER"  from dual
union all
select 'Time: ' || to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine: ' || host_name from v$instance
union all
select 'Version: '|| version from v$instance
union all
select 'DBName: '||name from v$database
union all
select 'Instance: '||instance_name from v$instance
/
set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/

define LOWTHRESHOLD=10
define MIDTHRESHOLD=62
define VERBOSE=TRUE

set veri off;
set feedback off;
REM === -- end of standard header -- ===
set echo off feedback on termout off pages 999 lines 132 long 300000000


/* If you get error when running the script:

SP2-0618: Cannot find the Session Identifier.  Check PLUSTRACE role is enabled
SP2-0611: Error enabling STATISTICS report

then enable the following lines and rerun the script

connect / as sysdba
@?/sqlplus/admin/plustrce.sql
grant plustrace to &&OBJ_OWNER;
*/

set echo on
show user
set echo off
set autotrace traceonly explain
set linesize 132

REM -- ---------------------------------
REM -- ADD the problem query here:
REM -- ---------------------------------
REM -- a sample could be like the following:
REM -- SELECT * FROM DUAL;

set timing on echo on

@&&1

set echo off
Rem===========================================================================================================================================
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem===========================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
 
