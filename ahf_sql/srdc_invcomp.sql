Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_invcomp.sql /main/3 2021/03/03 20:02:13 bburton Exp $
Rem
Rem srdc_invcomp.sql
Rem
Rem Copyright (c) 2018, 2021, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_invcomp.sql
Rem
Rem    DESCRIPTION
Rem      Called by ORA4063 SRDC collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_invcomp.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/27/19 - Script modified
Rem    xiaodowu    11/05/18 - Called by ORA4063 SRDC collection
Rem    xiaodowu    11/05/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
Rem srdc_invcomp.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_invcomp.sql - script to collect diagnostic details related to invalid data dictionary objects and components
Rem
Rem    NOTES
Rem      * This script collects the data related to the invalid data dictionary
Rem		   and registry components. This collects the details regarding the overall invalid 
Rem		   objects in the databse and the editions. 
Rem		 * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    slabraha   11/18/19 - added PDB specific checks in the script
Rem    slabraha   12/14/18 - updated the header
Rem    slabraha   11/01/18 - updated the script
Rem    slabraha   09/15/18 - updated the script
Rem    slabraha   03/05/18 - created the script
Rem
Rem
Rem
Rem
define SRDCNAME='DB_INVALID_DICT'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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
set echo on
set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
SELECT 'SRDC_INVALID_DICT' "CHECK_NAME",sysdate from dual
/
SELECT 'Instance_status' "CHECK_NAME",logins,status from v$instance
/
SELECT 'Database_status' "CHECK_NAME",open_mode, to_char(created,'YYYY-MM-DD HH24:MI:SS') creation_date from v$database
/
SELECT 'Registry_Status' "CHECK_NAME",comp_id,comp_name,version,status from dba_registry
/
select * from dba_registry
/
select  'Registry_History' "CHECK_NAME",TO_CHAR(action_time, 'DD-MON-YYYY HH24:MI:SS') AS action_time,action,namespace,version,id,comments from DBA_REGISTRY_HISTORY ORDER by action_time
/
SELECT 'Invalid_dictObjects' "CHECK_NAME",object_name,object_type,owner from dba_objects where status!='VALID' and owner in ('SYS','SYSTEM')
/
SELECT 'Invalid_Objcount' "CHECK_NAME",owner,count(*) from dba_objects where status!='VALID' group by owner
/
select 'UTL_obj_schema' "CHECK_NAME",owner,object_name,object_type,status from dba_objects where owner!='SYS' and object_name like 'UTL_RECOMP%'
/
select 'Duplicate_dictObjects' "CHECK_NAME",object_name, object_type from dba_objects where object_name||object_type in 
(select object_name||object_type from dba_objects where owner = 'SYS') and owner = 'SYSTEM'
/
select 'Reserved_names_as_ObjName' "CHECK_NAME",object_name,object_type,owner from dba_objects where object_name in ('SYS','SYSTEM')
/
select 'Timestamp_Mismatch' "CHECK_NAME",do.obj# d_obj,do.name d_name, do.type# d_type,
po.obj# p_obj,po.name p_name,
to_char(p_timestamp,'DD-MON-YYYY HH24:MI:SS') "P_Timestamp",
to_char(po.stime ,'DD-MON-YYYY HH24:MI:SS') "STIME",
decode(sign(po.stime-p_timestamp),0,'SAME','*DIFFER*') X
from sys.obj$ do, sys.dependency$ d, sys.obj$ po
where P_OBJ#=po.obj#(+)
and D_OBJ#=do.obj#
and do.status=1 /*dependent is valid*/
and po.status=1 /*parent is valid*/
and po.stime!=p_timestamp /*parent timestamp not match*/
order by 2,1
/
select 'Default_Edition' "CHECK_NAME",property_value from database_properties where property_name='DEFAULT_EDITION'
/
select * from dba_editions order by edition_name
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ PDB related checks - 12c specific ++
prompt ============================================================================================
prompt
set echo on
SHOW con_name
/
select NAME,CDB from v$database
/
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS
/
select * from v$pdbs
/
select * from pdb_spfile$
/
SELECT PDB, NETWORK_NAME, CON_ID FROM CDB_SERVICES   WHERE PDB IS NOT NULL AND CON_ID > 2 ORDER BY PDB
/
SELECT DB_NAME, CON_ID, PDB_NAME, OPERATION, OP_TIMESTAMP, CLONED_FROM_PDB_NAME  FROM CDB_PDB_HISTORY  WHERE CON_ID > 2  ORDER BY CON_ID
/
select cause, type, message from PDB_PLUG_IN_VIOLATIONS where status='PENDING' 
/
select * from PDB_PLUG_IN_VIOLATIONS
/
SELECT 'Invalid_dictObjects12c' "CHECK_NAME",object_name,object_type,owner,oracle_maintained from dba_objects where status!='VALID' and owner in ('SYS','SYSTEM')
/
SELECT 'Invalid_Objcount12c' "CHECK_NAME",owner,oracle_maintained,count(*) from dba_objects where status!='VALID' group by owner,oracle_maintained
/
SELECT 'sqlpatch_history' "CHECK_NAME",TO_CHAR(action_time, 'DD-MON-YYYY HH24:MI:SS') AS action_time,action,status,description,version,patch_id,bundle_series FROM   sys.dba_registry_sqlpatch ORDER by action_time
/
SELECT * FROM   sys.dba_registry_sqlpatch ORDER by action_time
/
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
