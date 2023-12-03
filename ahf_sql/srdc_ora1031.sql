Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_ora1031.sql /main/1 2021/07/20 06:32:07 bvongray Exp $
Rem
Rem srdc_ora1031.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_ora1031.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_ora1031.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/12/21 - Created
Rem

connect / as sysdba
@@?/rdbms/admin/sqlsessstart.sql
set sqlprompt " "
set sqlnumber off
set pagesize 1000
set markup html on 
set heading on echo off feedback off verify off underline on timing off
prompt
prompt *** Host Database Instance Details ***
select VERSION, (SELECT DB_UNIQUE_NAME FROM v$database) "DB_Name",INSTANCE_NAME, DATABASE_STATUS, INSTANCE_ROLE, HOST_NAME, STATUS,(SELECT OPEN_MODE FROM v$database) "Open_Mode" from v$instance;
prompt ==================================================
prompt
-- list users granted sysdba, sysoper (, sysasm)
-- check LOCAL_LISTENER and REMOTE_LISTENER Parameters
-- check remote_login_passwordfile
-- check sec_case_sensitive_logon
-- Doc ID 2150270.1 check _notify_crs parameter 
prompt *** List of DB Parameter *** 
show parameters 
prompt ==================================================
prompt
prompt *** Value of _asmsid Hidden Parameter ***
select x.ksppinm parameter, y.ksppstvl value
        from   x$ksppi  x , x$ksppcv y
        where  x.indx = y.indx
        and    x.ksppinm = '_asmsid' 
       order  by x.ksppinm;
prompt ==================================================
prompt

prompt *** List of Users from gv$pwfile_users ***
select INST_ID, USERNAME, SYSDBA, SYSOPER, SYSASM from GV$PWFILE_USERS order by inst_id;
prompt ===================================================
prompt

prompt *** List of DB users and their password version, account_status ***
prompt *** For 11g DB non-CDB ***
select a.username username, a.account_status, a.password_versions, a.authentication_type, to_char(a.lock_date,'DD-MON-YYYY HH24:MI:SS') lock_date, to_char(a.expiry_date,'DD-MON-YYYY HH24:MI:SS') expiry_date, a.profile profile, to_char(b.ptime,'DD-MON-YYYY HH24:MI:SS') ptime
from dba_users a , sys.user$ b
where a.user_id = b.user#
and a.username = UPPER('%FAILING_USER')
order by a.username;
prompt ==================================================
prompt

prompt *** Ignore below error in 11g DB ***
select a.username username, a.account_status, a.password_versions, a.authentication_type, to_char(a.lock_date,'DD-MON-YYYY HH24:MI:SS') lock_date, to_char(a.expiry_date,'DD-MON-YYYY HH24:MI:SS') expiry_date, a.profile profile, to_char(b.ptime,'DD-MON-YYYY HH24:MI:SS') ptime, a.common common, a.con_id con_id
from cdb_users a  , sys.user$ b
where a.user_id = b.user#
and a.username = UPPER('%FAILING_USER')
order by a.username;

prompt ==================================================
prompt

-- Collect details for DG standby DB (read-only mode) user login issue - ORA-28000
-- In multitenant DB, if V$RO_USER_ACCOUNT view is queried from the root in a multitenent container database (CDB), then only common users and the SYS user are returned.
-- If this view is queried from a pluggable database (PDB), only rows that pertain to the current PDB are returned.
-- PASSW_LOCKED - Indicates whether the account is locked (1) or not (0) 
-- PASSW_LOCK_UNLIM - Indicates whether the account is locked for an unlimited time (1) or not (0) 
prompt *** List of DB users (of read-only DB) in locked status ***
prompt *** For 11g DB ***
 select du.username username, rua.userid, rua.PASSW_LOCKED, rua.PASSW_LOCK_UNLIM, to_char(rua.PASSW_LOCK_TIME,'DD-MON-YYYY HH24:MI:SS') locked_date
 from GV$RO_USER_ACCOUNT rua, dba_users du 
 where rua.userid=du.user_id 
   and (rua.PASSW_LOCKED = 1 OR rua.PASSW_LOCK_UNLIM = 1)
   and du.username = upper('%FAILING_USER')
 order by du.username;
prompt ==================================================
prompt
-- Adding these 12c specific queries ( which will fail when executed in 11g because of additional columns of 12c DB missing) at the end of the script to get it parsed correctly
prompt *** Ignore below error in OS passwordfile of 11g DB and below ***
select inst_id, con_id, common, USERNAME, SYSDBA, SYSOPER, SYSASM, SYSBACKUP, SYSDG, SYSKM, ACCOUNT_STATUS, PASSWORD_PROFILE, LAST_LOGIN, LOCK_DATE, EXPIRY_DATE, EXTERNAL_NAME, AUTHENTICATION_TYPE from GV$PWFILE_USERS order by inst_id;
prompt ==================================================
prompt
prompt *** Ignore error in 11g readonly DB ***
 select rua.con_id, du.username username, rua.userid, rua.PASSW_LOCKED, rua.PASSW_LOCK_UNLIM, to_char(rua.PASSW_LOCK_TIME,'DD-MON-YYYY HH24:MI:SS') locked_date
 from GV$RO_USER_ACCOUNT rua, cdb_users du 
 where rua.userid=du.user_id 
   and (rua.PASSW_LOCKED = 1 OR rua.PASSW_LOCK_UNLIM = 1)
   and du.username = upper('%FAILING_USER')
 order by rua.con_id, du.username;
prompt ==================================================
prompt
prompt *** ORACLE_HOME (from database) ***
set serveroutput on
declare
    oh varchar2(200);
begin
    dbms_system.get_env('ORACLE_HOME',oh);
    dbms_output.put_line(oh);
end;
/
prompt ==================================================
prompt
@?/rdbms/admin/sqlsessend.sql
exit
 
