Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_acl_config.sql /main/1 2019/05/02 06:15:43 xiaodowu Exp $
Rem
Rem srdc_acl_config.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_acl_config.sql
Rem
Rem    DESCRIPTION
Rem      Called by dbacl SRDC collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_acl_config.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    04/19/19 - Called by dbacl SRDC collection
Rem    xiaodowu    04/19/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_acl_config.sql 
REM Connect as SYSDBA and when prompted enter the ACL Name and User.
define SRDCNAME='acl_config'
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
prompt    List of ACLs
prompt +-----------------------------------------------------------+
column host format a20
column LOWER_PORT format a5
column UPPER_PORT format a5
column acl format a50
set linesize 10000
select host,ACL from dba_network_acls; 

prompt +-----------------------------------------------------------+
prompt    ACL privileges granted to the users
prompt +-----------------------------------------------------------+

column principal format a15
column privilege format a10
column is_grant format a10
select acl, principal, privilege, is_grant from dba_network_acl_privileges; 

prompt +-----------------------------------------------------------+
prompt    List of ACEs - 12c Database ONLY
prompt +-----------------------------------------------------------+
column host format a15
column principal format a20
column privilege format a10
column grant_type format a10
select host,principal,privilege,grant_type from dba_host_aces;

prompt +-----------------------------------------------------------+
prompt    ACEs to access wallets - 12c Database ONLY
prompt +-----------------------------------------------------------+

column principal format a10
column privilege format a25
column wallet_path format a30
select principal,privilege,wallet_path,grant_type from dba_wallet_aces;

set HEADING on MARKUP html preformat off

spool off

@?/rdbms/admin/sqlsessend.sql
