
Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_dbtde.sql /main/2 2021/07/20 06:32:07 bvongray Exp $
Rem
Rem srdc_dbtde.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_dbtde.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/srdc_dbtde.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/12/21 - ER 33001587
Rem    bvongray    05/28/21 - Created
Rem
connect / as sysdba
@@?/rdbms/admin/sqlsessstart.sql
set sqlprompt " "
set sqlnumber off
set pagesize 1000
set markup html on 
set heading on echo off feedback off verify off underline on timing off
prompt

prompt *** WRL_PARAMETER from v$encryption_wallet - wallet details ***
prompt *** This is for 11g and below DB ***
prompt *** As v$encrytion_wallet is not available in 11g and below DB, use orapki to display wallet content ***
prompt 
column wrl_parameter_11g noprint new_value tdewrl
select wrl_parameter wrl_parameter_11g from v$encryption_wallet where upper(wrl_type)='FILE' and wrl_parameter is not null and exists(select version from v$instance where version like '10%' or version like '11%');
prompt <table>
prompt <tr>
prompt <th>
prompt WRL_WALLET_LS
prompt </th>
prompt <th>
prompt WRL_WALLET_ORAPKI
prompt </th>
prompt </tr>
prompt <tr>
prompt <td><pre>
prompt WALLET_WRL = &tdewrl
host "dir &tdewrl*wallet*"
prompt
prompt </pre></td>
prompt <td><pre>
host "echo null | orapki wallet display -wallet &tdewrl"
prompt
prompt </pre></td>
prompt </tr>
prompt </table>
prompt ==================================================
prompt


prompt *** Database Version, Status, and Role ***
select VERSION, (SELECT DB_UNIQUE_NAME FROM v$database) "DB_Name",INSTANCE_NAME, DATABASE_STATUS, INSTANCE_ROLE, HOST_NAME, STATUS,(SELECT OPEN_MODE FROM v$database) "Open_Mode" from v$instance;
prompt ==================================================
prompt

prompt *** Status of the wallet - v$encryption_wallet ***
prompt select wrl_type, wrl_parameter, status from v$encryption_wallet
select wrl_type, wrl_parameter, status from v$encryption_wallet;
prompt ===================================================
prompt

prompt *** Status of the wallet in grid environment - gv$encryption_wallet ***
prompt select inst_id, wrl_type, wrl_parameter, status from gv$encryption_wallet order by inst_id
select inst_id, wrl_type, wrl_parameter, status from gv$encryption_wallet order by inst_id;
prompt ===================================================
prompt

prompt *** mkeyid used to encrypt the columns ***
prompt select obj#, owner#, mkeyid from enc$
select obj#, owner#, mkeyid from enc$;
prompt ===================================================
prompt

prompt *** mkeyid associated with the tablespaces ***
prompt select ts#, name as ts_name, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select t.name, t.ts#, RAWTOHEX(x.mkid) mkeyid from v$tablespace t, x$kcbtek x where t.ts#=x.ts#)
select ts#, name as ts_name, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select t.name, t.ts#, RAWTOHEX(x.mkid) mkeyid from v$tablespace t, x$kcbtek x where t.ts#=x.ts#);
prompt ===================================================
prompt

prompt *** mkeyid in the control file ***
prompt select inst_id, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select inst_id, RAWTOHEX(mkid) mkeyid from x$kcbdbk)
select inst_id, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select inst_id, RAWTOHEX(mkid) mkeyid from x$kcbdbk);
prompt ===================================================
prompt

prompt *** To check if TDE was ever configured in this Database ***
prompt *** returns 6 for pre-generated ID, returns 14 for TDE MKEYID ***
prompt select flags from x$kcbdbk
select flags from x$kcbdbk;
prompt ===================================================
prompt

prompt *** To check the algorithm of encryption key mkeyid ***
prompt select masterkeyid, encryptionalg from v$database_key_info
select masterkeyid, encryptionalg from v$database_key_info;
prompt ===================================================
prompt

prompt *** To check mkeyid of tablespaces for DB in mount status ***
prompt select t.name, x.mkid from v$tablespace t, x$kcbtek x where t.ts#=x.ts#
select t.name, x.mkid from v$tablespace t, x$kcbtek x where t.ts#=x.ts#;
prompt ===================================================
prompt

prompt *** To check mkeyid of control file for DB in mount status ***
prompt select mkid from x$kcbdbk
select mkid from x$kcbdbk;
prompt ===================================================
prompt

Prompt ****************************** Below details are for 12c and above Databases ******************************
prompt ***********************************************************************************************************
prompt


prompt *** PDB details in multitenant DB ***
prompt *** Ignore error in 11g and below DB ***
prompt select CON_ID, DBID, CON_UID, GUID, NAME, OPEN_MODE, RESTRICTED from v$pdbs
select CON_ID, DBID, CON_UID, GUID, NAME, OPEN_MODE, RESTRICTED from v$pdbs;
prompt ==================================================
prompt

prompt *** Status of the wallet in multitenant - v$encryption_wallet ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id, wrl_type, wrl_parameter, status, wallet_type, wallet_order from v$encryption_wallet order by con_id, wrl_type
select con_id, wrl_type, wrl_parameter, status, wallet_type, wallet_order from v$encryption_wallet order by con_id, wrl_type;
prompt ===================================================
prompt

prompt *** Status of the wallet in grid environment in multitenant - gv$encryption_wallet ***
prompt *** Ignore error in 11g and below DB ***
prompt select inst_id, con_id, wrl_type, wrl_parameter, status, wallet_type, wallet_order from gv$encryption_wallet order by con_id, inst_id, wrl_type
select inst_id, con_id, wrl_type, wrl_parameter, status, wallet_type, wallet_order from gv$encryption_wallet order by con_id, inst_id, wrl_type;
prompt ===================================================
prompt

prompt *** mkeyid associated with the tablespaces in multitenant ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id , ts#, name as ts_name,utl_raw.cast_to_varchar2 ( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode (substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select x.con_id, t.ts# , t.name, RAWTOHEX(x.mkid) mkeyid from v$tablespace t, x$kcbtek x where t.ts#=x.ts# and x.con_id=t.con_id) order by con_id, ts#
select con_id , ts#, name as ts_name,utl_raw.cast_to_varchar2 ( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode (substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select x.con_id, t.ts# , t.name, RAWTOHEX(x.mkid) mkeyid from v$tablespace t, x$kcbtek x where t.ts#=x.ts# and x.con_id=t.con_id) order by con_id, ts#;
prompt ===================================================
prompt

prompt *** Output from encryption_keys view in multitenant - v$encryption_keys ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id, key_id, keystore_type, creator_pdbid, creator_pdbname, creator_dbname, activating_pdbid, activating_pdbname, activating_dbname, creation_time, activation_time from v$encryption_keys order by con_id
select con_id, key_id, keystore_type, creator_pdbid, creator_pdbname, creator_dbname, activating_pdbid, activating_pdbname, activating_dbname, creation_time, activation_time from v$encryption_keys order by con_id;
prompt ===================================================
prompt

prompt *** mkeyid in the control file in multitenant ***
prompt *** Ignore error in 11g and below DB ***
prompt select inst_id, con_id, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select con_id, inst_id, RAWTOHEX(mkid) mkeyid from x$kcbdbk) order by con_id
select inst_id, con_id, utl_raw.cast_to_varchar2( utl_encode.base64_encode('01'||substr(mkeyid,1,4))) || utl_raw.cast_to_varchar2( utl_encode.base64_encode(substr(mkeyid,5,length(mkeyid)))) masterkeyid_base64, mkeyid FROM (select con_id, inst_id, RAWTOHEX(mkid) mkeyid from x$kcbdbk) order by con_id;
prompt ===================================================
prompt

prompt *** Encrypted datafiles ***
prompt *** Ignore error in 12.1 and below DB ***
prompt select con_id, ts#, tablespace_name,name,encrypted from v$datafile_header order by con_id
select con_id, ts#, tablespace_name,name,encrypted from v$datafile_header order by con_id;
prompt ===================================================
prompt

prompt *** To check if TDE was ever configured in this Database ***
prompt *** returns 0 for pre-generated ID, returns 1 for TDE MKEYID ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id, mklocact from x$kcbtek where TS# in (select ts# from v$tablespace where name = 'SYSTEM') order by con_id
select con_id, mklocact from x$kcbtek where TS# in (select ts# from v$tablespace where name = 'SYSTEM') order by con_id; 
prompt ===================================================
prompt

prompt *** To check mkeyid of tablespaces for DB in mount status in multitenant ***
prompt *** Ignore error in 11g and below DB ***
prompt select t.con_id, t.name, x.mkid from v$tablespace t, x$kcbtek x where t.ts#=x.ts# and t.con_id = x.con_id order by t.con_id
select t.con_id, t.name, x.mkid from v$tablespace t, x$kcbtek x where t.ts#=x.ts# and t.con_id = x.con_id order by t.con_id;
prompt ===================================================
prompt

prompt *** To check mkeyid of control file for DB in mount status in multitenant ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id, inst_id, mkid from x$kcbdbk order by con_id
select con_id, inst_id, mkid from x$kcbdbk order by con_id;
prompt ===================================================
prompt

prompt *** To check the PDB Plugin violations with status='PENDING' ***
prompt *** Ignore error in 11g and below DB ***
prompt select con_id, name, type, error_number, cause, line, message, action from pdb_plug_in_violations where status='PENDING' order by con_id
select con_id, name, type, error_number, cause, line, message, action from pdb_plug_in_violations where status='PENDING' order by con_id;
prompt ===================================================
prompt

Prompt ****************************** Below details are for 18c and above Databases ******************************
prompt ***********************************************************************************************************
prompt

prompt *** To check if its Unified or isolated wallet mode - keystore_mode ***
prompt *** CDB root (CON_ID=1) will always be in NONE mode, PDBs will be in either UNITED or ISOLATED ***
prompt *** Ignore error in 12c and below DB ***
prompt select con_id, keystore_mode, wrl_type, wrl_parameter, status, wallet_type, wallet_order from v$encryption_wallet order by con_id, wrl_type
select con_id, keystore_mode, wrl_type, wrl_parameter, status, wallet_type, wallet_order from v$encryption_wallet order by con_id, wrl_type; 
prompt ===================================================
prompt

prompt *** To check the algorithm of encryption key mkeyid and ***
prompt ***   masterkey_activated=YES confirms mkeyid is set ***
prompt *** Ignore error in 12c and below DB ***
prompt select con_id, masterkeyid, encryptionalg, masterkey_activated from v$database_key_info order by con_id
select con_id, masterkeyid, encryptionalg, masterkey_activated from v$database_key_info order by con_id;
prompt ===================================================
prompt

prompt *** DB Parameter List *** 
prompt *** From 18c and above DB, check parameters wallet_root, tde_configuration ***
prompt *** From 21c and above DB, check parameters wallet_root, tde_configuration, heartbeat_batch_size, tde_key_cache ***
prompt *** Ignore error in 12c and below DB ***
prompt select  con_id, name, value from v$parameter where lower(name) in ('wallet_root','tde_configuration','heartbeat_batch_size', 'tde_key_cache') order by con_id
select  con_id, name, value from v$parameter where lower(name) in ('wallet_root','tde_configuration','heartbeat_batch_size', 'tde_key_cache') order by con_id; 
prompt ===================================================
prompt

column pdbname noprint new_value pdbname
select name pdbname from v$containers where con_id = &1;

prompt *** Ignore error in 11g and below DB and in non-multitenant DB ***
alter session set container = &pdbname ;

prompt *** Isolated TDE wallet content for the PDB ***
prompt *** Output from encryption_keys view in PDB - v$encryption_keys from PDB ***
prompt alter session set container = &pdbname
prompt select con_id, key_id, keystore_type, creator_pdbid, creator_pdbname, creator_dbname, activating_pdbid, activating_pdbname, activating_dbname, creation_time, activation_time from v$encryption_keys order by con_id
select con_id, key_id, keystore_type, creator_pdbid, creator_pdbname, creator_dbname, activating_pdbid, activating_pdbname, activating_dbname, creation_time, activation_time from v$encryption_keys order by con_id;
prompt ===================================================
prompt
@?/rdbms/admin/sqlsessend.sql
exit
