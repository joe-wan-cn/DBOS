Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_text_index_stats.sql /main/1 2021/10/12 12:46:51 bvongray Exp $
Rem
Rem srdc_text_index_stats.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_text_index_stats.sql - Collect Oracle Text Index Fragmentation Statistics information
Rem
Rem    DESCRIPTION
Rem      Collect Oracle Text Index Fragmentation Statistics information
Rem
Rem    NOTES
Rem      .
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/24/21 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql

define SRDCNAME='Text_Index_Stats_Information'
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
REM
REM   In versions < 10.2 please use the sample from Note:189819.1
REM   due to Bug 2564546 and store it in a file called:
REM   SRDC_TEXT_INDEX_STATS_INFORMATION_<INSTANCE_NAME>_<SYSDATE>.txt
REM
set HEADING OFF MARKUP html preformat on
SET LINESIZE 200;
SET SERVEROUTPUT ON FORMAT WRAP;
SET LONG 2000000000
SET LONGCHUNKSIZE 10000
SET PAGESIZE 10000
SET TRIMOUT ON TRIMSPOOL ON

VAR stats CLOB;

DEFINE OWN = &1
DEFINE IND = &2


DECLARE
x CLOB := null;
BEGIN
ctx_output.start_log('&&SRDCNAME.log');
ctx_report.index_stats('&&OWN..&&IND',x);
ctx_output.end_log;
:stats := x;
dbms_lob.freetemporary(x);
END;
/

SET LONG 2000000000
SET LONGCHUNKSIZE 10000
SET HEAD OFF
SET PAGESIZE 10000

SELECT :stats FROM dual;

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
 
