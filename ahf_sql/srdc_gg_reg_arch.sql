Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_gg_reg_arch.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_gg_reg_arch.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_gg_reg_arch.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_gg_reg_arch.sql
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
EM srdc_gg_reg_arch.sql
REM
REM Collect db information for registered archived logs
REM
REM :  Usage : sqlplus / as sysdba @srdc_gg_reg_arch.sql
define SRDCNAME='gg_reg_arch'

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
prompt ++ REGISTERED ARCHIVED LOG ++
prompt ============================================================================================
prompt

set lines 180
set numwidth 18

select consumer_name, source_database, purgeable, first_scn, next_scn, thread#, sequence#, name
from dba_registered_archived_log 
order by consumer_name, first_scn;

spool off
set markup html off spool off
set feedback on
set term on
set echo on

@?/rdbms/admin/sqlsessend.sql
 
