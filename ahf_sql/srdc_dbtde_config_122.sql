Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_dbtde_config_122.sql /main/1 2018/08/15 16:55:52 bburton Exp $
Rem
Rem srdc_dbtde_config_122.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_dbtde_config_122.sql 
Rem
Rem    DESCRIPTION
Rem      None
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_dbtde_config_122.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    07/03/18 - Called by DBTDE SRDC collection
Rem    xiaodowu    07/03/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
EM srdc_dbtde_config_122.sql 
REM Connect as SYSDBA 
define SRDCNAME='DBTDE_CONFIG_122'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off verify off TRIMSPOOL on
set lines 132 pages 10000
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on 
REM
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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

SET MARKUP HTML ON PREFORMAT ON

prompt +-----------------------------------------------------------+
prompt    Encrypted datafiles(Only in 12.2)
prompt +-----------------------------------------------------------+

set line 1000
col name format a75
col TABLESPACE_NAME format a10
col encrypted format a10
select tablespace_name,name,encrypted from v$datafile_header;

set HEADING on MARKUP html preformat off

spool off

@?/rdbms/admin/sqlsessend.sql
 
