Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_privs_roles.sql /main/1 2022/03/11 10:05:49 smuthuku Exp $
Rem
REM srdc_get_privs_roles.sql
Rem
Rem Copyright (c) 2019, 2022, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_get_privs_roles.sql
Rem
Rem    DESCRIPTION
Rem      Called by SRDC collection privsroles
Rem
Rem    NOTES
Rem      None 
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    02/07/28- Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='get_privs_roles'
define USERNAME='&1'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off verify off TRIMSPOOL on
set lines 132 pages 10000
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on
REM
spool &&SRDCSPOOLNAME..htm
set heading off
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


column role_name format a25
column priv format a60
set heading off

prompt
prompt
prompt +-----------------------------------------------------------+
prompt    List of System and object privileges granted to the user
prompt +-----------------------------------------------------------+

select '(object priv) '||privilege||' on '||owner||'.'||table_name||decode(grantable,'YES',' WITH GRANT OPTION','') priv , 'Granted directly ' role_name from dba_tab_privs where grantee in (upper('&&USERNAME'))
union all
select '(object priv) '||privilege||' on '||owner||'.'||table_name||decode(grantable,'YES',' WITH GRANT OPTION','') priv , grantee role_name from dba_tab_privs where grantee in (select granted_role from dba_role_privs start with grantee=
upper('&&USERNAME') connect by prior granted_role=grantee)
union all
select '(system priv) '||privilege priv , 'Granted directly' role_name from dba_sys_privs where grantee in (upper('&&USERNAME'))
union all
select '(system priv) '||privilege priv , grantee role_name from dba_sys_privs where grantee in (select granted_role from dba_role_privs start with grantee=upper('&&USERNAME') connect by prior granted_role=grantee)
union all
select '(role without privs)' priv, granted_role from (select granted_role from dba_role_privs start with grantee=upper('&&USERNAME') connect by prior granted_role=grantee) where granted_role not in (select grantee from dba_tab_privs 
union all select grantee from dba_sys_privs)
/


column PASSWORD_REQUIRED format a20
column AUTHENTICATION_TYPE format a25

prompt
prompt
prompt +-----------------------------------------------------------+
prompt     List of roles in the database
prompt +-----------------------------------------------------------+

set heading on
select * from dba_roles;
set HEADING on MARKUP html preformat off

spool off
@?/rdbms/admin/sqlsessend.sql

