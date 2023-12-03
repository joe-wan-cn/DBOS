Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_gg_database.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_gg_database.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_gg_database.sql 
Rem
Rem    DESCRIPTION
Rem      collect generic database informations for goldengate.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_gg_database.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/29/18 - Called by srdc_dbggintegratedmode.xml
Rem    xiaodowu    03/29/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_gg_database.sql
REM collect generic database informations for goldengate
set echo off
set feedback off

define SRDCNAME='gg_database'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on entmap off spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;


spool &&SRDCSPOOLNAME..htm

set markup html off
prompt <b><font face="Arial" size="4" >Database information:</font></b>
set markup html on

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

alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
col next_change# for 9999999999999999999999999999
col first_change# for 9999999999999999999999999999

set markup html off
prompt <b><font face="Arial" size="4" >DB Instance information:</font></b>
set markup html on

select INST_ID, INSTANCE_NAME, HOST_NAME, THREAD# from gv$instance;

REM Main menu:

prompt <a href="#Parameters">Database Parameters</a>
prompt <a href="#NLSParameters">Database NLS parameters</a>
prompt <a href="#Components">Installed database components</a>
prompt <a href="#Loggroups">Database Log groups</a>
prompt <a href="#Supplog">Database level logging information</a>
prompt <a href="#Registeredlogs">Registered archived log files (1000 newest)</a><br>

set markup html off
prompt <a name="Parameters"><font face="Arial" size="4" >Database parameters (where value is not null) :</font></a>
set markup html on

select inst_id, name, value from gv$parameter where value is not null order by 2,1 ;


set markup html off
prompt <a name="NLSParameters"><font face="Arial" size="4" >Database NLS parameters:</font></a>
set markup html on

select * from nls_database_parameters;

set markup html off
prompt <a name="Components"><font face="Arial" size="4" >Installed database components:</font></a>
set markup html on

select comp_id, comp_name,version,status,modified,schema from DBA_REGISTRY;

set markup html off
prompt <a name="Loggroups"><font face="Arial" size="4" >Database Log groups:</font></a>
set markup html on

select * from gv$log;

set markup html off
prompt <a name="Supplog"><font face="Arial" size="4" >Database level logging information</font></a>
set markup html on

select SUPPLEMENTAL_LOG_DATA_MIN, SUPPLEMENTAL_LOG_DATA_PK, SUPPLEMENTAL_LOG_DATA_UI, FORCE_LOGGING from v$database;


set markup html off
prompt <a name="Registeredlogs"><font face="Arial" size="4" >Registered archived log files (1000 newest) :</font></a>
set markup html on
set pages 1002

select * from ( select inst_id, thread#, sequence#, FIRST_TIME, NEXT_TIME, name from gv$archived_log order by first_time desc) where rownum < 1000;



set echo off
set sqlprompt "SQL> " term on
set verify on
spool off
set markup html off spool off
set echo on

@?/rdbms/admin/sqlsessend.sql
