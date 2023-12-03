Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_text_index_errors.sql /main/1 2021/10/12 12:46:51 bvongray Exp $
Rem
Rem srdc_text_index_errors.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_text_index_errors.sql - Collect Oracle Text Index Errors
Rem
Rem    DESCRIPTION
Rem      Collect Oracle Text Index Errors
Rem
Rem    NOTES
Rem      .
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/24/21 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

define SRDCNAME='Text_Index_Errors'
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
SET SERVEROUTPUT ON FORMAT WRAP;

DEFINE OWN = &1
DEFINE IND = &2

select  count(*) as "Indexing Error Count"
from    ctxsys.ctx_index_errors
where   upper(err_index_owner) = upper('&&OWN')
and     upper(err_index_name) = upper('&&IND');

select  ERR_INDEX_OWNER   as "INDEX OWNER",
        ERR_INDEX_NAME   as "INDEX NAME",
        TO_CHAR(ERR_TIMESTAMP,'DD-MON-YYYY HH24:MI:SS') as "ERROR TIMESTAMP",
        ERR_TEXTKEY as "ROWID" ,
        ERR_TEXT as "ERROR TEXT"
from    ctxsys.ctx_index_errors
where   upper(err_index_owner) = upper('&&OWN')
and     upper(err_index_name) = upper('&&IND')
order by err_timestamp desc ;

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
EXIT;
 
