Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_external_tables.sql /main/1 2021/07/26 08:55:41 bvongray Exp $
Rem
Rem srdc_db_external_tables.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_db_external_tables.sql - srdc_db_external_tables.sql
Rem
Rem    DESCRIPTION
Rem      To collect details of external tables in the database
Rem
Rem    NOTES
Rem      To collect details of external tables in the database 
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_external_tables.sql
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

define SRDCNAME='DB_EXTERNAL_TABLES'
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
prompt ***********************Run Time**********************
set echo on

select sysdate from dual;

set echo off
prompt ********************** Details of the External Tables **********************
set echo on

SELECT * FROM dba_external_tables;

set echo off
prompt ********************** Directories used by the External tables **********************
set echo on

select * from DBA_EXTERNAL_LOCATIONS where directory_name in (select default_directory_name from dba_external_tables);

select * from dba_tab_privs where table_name in (select default_directory_name from dba_external_tables);

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
exit

 
