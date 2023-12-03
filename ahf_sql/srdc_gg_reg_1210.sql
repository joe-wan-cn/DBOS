Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_gg_reg_1210.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_gg_reg_1210.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_gg_reg_1210.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_gg_reg_1210.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/18/18 - For SRDC dbggclassicmode collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
EM srdc_gg_reg_1210.sql
REM
REM Collect db information for troubleshooting register problems on 12.1.0.
REM
REM :  Usage : sqlplus / as sysdba @srdc_gg_reg_1210.sql
define SRDCNAME='gg_reg_1210'

SET MARKUP HTML ON PREFORMAT ON
set pagesize 50
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off

alter session set nls_date_format='YYYY-MM-DD HH24MiSS';

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;

spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||
          to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine: '||host_name from v$instance
union all
select '| Platform: '||platform_name from v$database
union all
select '| Version: '||version from v$instance
union all
select '| DBName: '||name from v$database
union all
select '| Instance: '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set HEADING on MARKUP html preformat off 
set feedback on
REM === -- end of standard header -- ===

prompt
prompt ============================================================================================
prompt ++ REGISTERED EXTRACTS ++
prompt ============================================================================================
prompt

set lines 180
col extract_name format a12 heading 'Extract|Name'
col capture_name format a20 heading 'Capture|Name'
col capture_type format a10 heading 'Capture|Type'
col status Heading 'Status'
col capture_user format a12 Heading 'Capture|User'

select client_name extract_name, capture_name, capture_type,
   capture_user, version, logminer_id, status
from cdb_capture c;

prompt
prompt ============================================================================================
prompt ++ LOGMINER SESSIONS ++
prompt ============================================================================================
prompt

col session_name Heading 'Capture|Name'
col session_id Heading 'Session|ID'
col session_state Heading 'Session|State'

select session_id, session_name, session_state
      FROM gv$logmnr_session order by session_name; 

prompt
prompt ============================================================================================
prompt ++ GOLDENGATE PRIVILEGES ++
prompt ============================================================================================
prompt 

select * from dba_goldengate_privileges;

spool off
set markup html off spool off
set feedback on
set term on
set echo on

@?/rdbms/admin/sqlsessend.sql
 
