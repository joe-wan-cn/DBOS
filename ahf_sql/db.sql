Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/db.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem db.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      db.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/db.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/28/18 - Called by srdc_ora1031.xml
Rem    xiaodowu    03/28/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
connect / as sysdba
set sqlprompt " "
set sqlnumber off
set heading on echo off feedback off verify off underline on timing off
prompt *** Host Name ***
select host_name "Hostname"  from v$instance;
prompt ==================================================
prompt
prompt *** Database Version, Status, and Role ***
select VERSION, DATABASE_STATUS, INSTANCE_ROLE from v$instance;
prompt ==================================================
prompt
prompt *** ORACLE_HOME (from database) *** 
set serveroutput on
declare
    oh varchar2(200);
begin
    dbms_system.get_env('ORACLE_HOME',oh);
    dbms_output.put_line(chr(13)||oh);
end;
/
prompt ==================================================
prompt

-- list users granted sysdba, sysoper (, sysasm)
prompt *** REMOTE_LOGIN_PASSWORDFILE Parameter *** 
show parameter remote_login_passwordfile
prompt ===================================================
prompt
prompt *** LOCAL_LISTENER and REMOTE_LISTENER Parameters ***
show parameter _listener
prompt ===================================================
prompt
prompt *** List of Users from gv\$pwfile_users ***
select * from GV$PWFILE_USERS order by inst_id;
prompt ==================================================
prompt
prompt *** Value of _asmsid Hidden Parameter ***
col parameter for a10
col value for a10 
select x.ksppinm parameter, y.ksppstvl value
        from   x$ksppi  x , x$ksppcv y
        where  x.indx = y.indx
        and    x.ksppinm = '_asmsid' 
       order  by x.ksppinm;
prompt ==================================================
prompt
@?/rdbms/admin/sqlsessend.sql
 
