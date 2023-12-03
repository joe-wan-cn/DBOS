Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_audit_details.sql /main/1 2021/12/07 18:37:23 smuthuku Exp $
Rem
Rem srdc_get_audit_details.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      srdc_get_audit_details.sql
Rem
Rem    DESCRIPTION
Rem      Query unified audit information
Rem
Rem    NOTES
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_audit_details.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    11/29/21 - Initial Creaion - Bug 33603481
Rem

 
@@?/rdbms/admin/sqlsessstart.sql
spool get_audit_details.log

set timing on
set echo on
set serveroutput on
set pagesize 10000
set linesize 4000

-- First get the current DB version details
select banner from v$version;

-- Get deployment type
col DATABASE_ROLE for a25
select SYS_CONTEXT('USERENV', 'DATABASE_ROLE') as DATABASE_ROLE from SYS.DUAL;

col CLOUD_SERVICE for a25
select SYS_CONTEXT('USERENV','CLOUD_SERVICE') as CLOUD_SERVICE from SYS.DUAL;

col name format a9
col database_role format
col db_unique_name format a30
col open_mode format a20
col database_role format a16
select dbid, name, created, open_mode, DATABASE_ROLE, DB_UNIQUE_NAME from v$database;

col instance_name format a16
col host_name format a30
col dbversion format a17
col version_full format a17
col instance_role format a18
select instance_number, instance_name, host_name, version as dbversion, con_id, version_full, instance_role from v$instance;

col name format a30
col open_mode format a10
select con_id, dbid, con_uid, guid, name, open_mode, AUDIT_FILES_SIZE, MAX_AUDIT_SIZE from v$pdbs;

-- PDB incarnation information if any
COL PDB_NAME FORMAT A60
COL CLONED_FROM_PDB_NAME FORMAT A60
col DB_NAME FORMAT A60
COL DB_UNIQUE_NAME FORMAT A60

SELECT PDB_NAME, PDB_ID, PDB_DBID, PDB_GUID, DB_VERSION, CLONED_FROM_PDB_NAME, CLONED_FROM_PDB_GUID, DB_NAME, DB_UNIQUE_NAME, DB_DBID FROM DBA_PDB_HISTORY;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Traditional Audit Settings
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Audit Parameter settings
show parameter audit

-- Get Audit Trail Configuration parameters
col PARAMETER_NAME format a25
col PARAMETER_VALUE format a25
col AUDIT_TRAIL format a20 truncate
select PARAMETER_NAME, PARAMETER_VALUE, AUDIT_TRAIL
from DBA_AUDIT_MGMT_CONFIG_PARAMS
order by PARAMETER_NAME, AUDIT_TRAIL;

-- To get the list of Statement Audit Options

col user_name format a25
col proxy_name format a25
col audit_option format a35
col success format a10
col failure format a10
select user_name,proxy_name,audit_option,success,failure
from DBA_STMT_AUDIT_OPTS order by user_name,audit_option;

-- To get the list of Privilege Audit Options
col privilege format a35
select user_name,proxy_name,privilege,success,failure
from DBA_PRIV_AUDIT_OPTS order by user_name,privilege;

-- To get the list of Object Audit Options
col OWNER format a10
col OBJECT_NAME format a30
col OBJECT_TYPE format a10
col ALT format a5
col AUD format a5
col COM format a5
col DEL format a5
col GRA format a5
col IND format a5
col INS format a5
col LOC format a5
col REN format a5
col SEL format a5
col UPD format a5
col EXE format a5
col CRE format a5
col REA format a5
col WRI format a5
col FBK format a5
select owner,object_name,object_type,alt,aud,com,del,gra,ind,ins,loc,ren,sel,upd,exe,cre,rea,wri,fbk
from DBA_OBJ_AUDIT_OPTS order by owner,object_type,object_name;

-- To get the Details of FGA policies
col OBJECT_SCHEMA format a25
col OBJECT_NAME format a20
col POLICY_OWNER format a10
col POLICY_NAME format a10
col POLICY_TEXT format a30
col POLICY_COLUMN format a10
col PF_SCHEMA format a10
col PF_PACKAGE format a10
col PF_FUNCTION format a10
col ENABLED format a10
col SEL format a3
col INS format a3
col UPD format a3
col DEL format a3
col AUDIT_TRAIL format a12
col POLICY_COLUMN_OPTIONS format a12
select OBJECT_SCHEMA, OBJECT_NAME, POLICY_OWNER, POLICY_NAME, POLICY_TEXT, POLICY_COLUMN, PF_SCHEMA, PF_PACKAGE,
PF_FUNCTION, ENABLED, SEL, INS, UPD, DEL, AUDIT_TRAIL, POLICY_COLUMN_OPTIONS
from DBA_AUDIT_POLICIES order by policy_name;

col OBJECT_SCHEMA format a30
col OBJECT_NAME format a30
col POLICY_NAME format a30
col POLICY_COLUMN format a30
select OBJECT_SCHEMA, OBJECT_NAME, POLICY_NAME, POLICY_COLUMN
from DBA_AUDIT_POLICY_COLUMNS
order by OBJECT_SCHEMA, OBJECT_NAME, POLICY_NAME, POLICY_COLUMN;

-- Statistics of Traditional Audit Records
select count(*) from DBA_AUDIT_TRAIL;

-- get MIN and MAX times on Traditional Audit Trail
col mintime format a38
col maxtime format a38
select min(EXTENDED_TIMESTAMP) mintime, max(EXTENDED_TIMESTAMP) maxtime from DBA_AUDIT_TRAIL;

col USERNAME format a25
col ACTION_NAME format a30
select USERNAME, ACTION_NAME, count(*) Counts from DBA_AUDIT_TRAIL
group by USERNAME, ACTION_NAME order by Counts desc, username;

-- Statistics of XML audit trail (XML AT)
select count(*) from v$xml_audit_trail;

-- know the types of audit records in XML AT
select audit_type, count(*) Counts from v$xml_audit_trail group by audit_type order by Counts desc;

-- user-action statistics from XML AT
col DB_USER format a25
select db_user,action,count(*) Counts from v$xml_audit_trail
group by db_user, action order by Counts desc, db_user;

-- get the distinct FGA policy details from XML AT
col policy_name format a30
select policy_name, count(*) Counts from v$xml_audit_trail
group by policy_name order by Counts desc, policy_name;

-- get MIN and MAX times on XML Audit Trail
col mintime format a38
col maxtime format a38
select min(EXTENDED_TIMESTAMP) mintime, max(EXTENDED_TIMESTAMP) maxtime from V$XML_AUDIT_TRAIL;

-- Statistics of FGA audit records
select count(*) from DBA_FGA_AUDIT_TRAIL;

-- get MIN and MAX times on FGA Audit Trail
select min(EXTENDED_TIMESTAMP) mintime, max(EXTENDED_TIMESTAMP) maxtime from DBA_FGA_AUDIT_TRAIL;

-- Types of FGA audit records
col DB_USER format a20
col OBJECT_SCHEMA format a20
col OBJECT_NAME format a20
col STATEMENT_TYPE format a10
select DB_USER, OBJECT_SCHEMA, OBJECT_NAME, STATEMENT_TYPE, count(*) from DBA_FGA_AUDIT_TRAIL
group by DB_USER, OBJECT_SCHEMA, OBJECT_NAME, STATEMENT_TYPE
order by DB_USER, OBJECT_SCHEMA, OBJECT_NAME, STATEMENT_TYPE;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Unified Audit Settings (Should be run on 12.1 and above)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

set echo on
set serveroutput on
set pagesize 10000
set linesize 4000

-- Check if Pure Unified Auditing is Turned ON
col parameter format a20
col value format a10
select parameter,value from v$option where parameter='Unified Auditing';

-- To get the details of existing Unified audit policies (Including Out of the box audit policies)
col POLICY_NAME format a20
col AUDIT_CONDITION format a40
col CONDITION_EVAL_OPT format a10
col AUDIT_OPTION format a20
col AUDIT_OPTION_TYPE format a10
col OBJECT_SCHEMA format a25
col OBJECT_NAME format a30
col OBJECT_TYPE format a10
col COMMON format a5
select POLICY_NAME,AUDIT_CONDITION,CONDITION_EVAL_OPT,AUDIT_OPTION,OBJECT_SCHEMA,OBJECT_NAME,OBJECT_TYPE,COMMON
from AUDIT_UNIFIED_POLICIES order by policy_name;

-- To get the details of existing common Unified audit policies
col POLICY_NAME format a20
col AUDIT_CONDITION format a40
col CONDITION_EVAL_OPT format a10
col AUDIT_OPTION format a20
col AUDIT_OPTION_TYPE format a10
col OBJECT_SCHEMA format a25
col OBJECT_NAME format a30
col OBJECT_TYPE format a10
col COMMON format a5
select POLICY_NAME,AUDIT_CONDITION,CONDITION_EVAL_OPT,AUDIT_OPTION,OBJECT_SCHEMA,OBJECT_NAME,OBJECT_TYPE,COMMON
from AUDIT_UNIFIED_POLICIES where COMMON = 'YES' order by policy_name;

-- To get the details of all enabled unified audit policies (can be run on 12.1.0.1 and 12.1.0.2)
col USER_NAME format a25
col ENABLED_OPT format a10
col SUCCESS format a10
col FAILURE format a10
select USER_NAME,POLICY_NAME, ENABLED_OPT,SUCCESS,FAILURE
from AUDIT_UNIFIED_ENABLED_POLICIES order by USER_NAME,POLICY_NAME;

-- To get the details of all enabled unified audit policies (should be run on 12.2.0.1 and above)
col ENTITY_NAME format a25
col ENABLED_OPTION format a15
col ENTITY_TYPE format a10
select ENTITY_NAME,POLICY_NAME,ENTITY_TYPE,ENABLED_OPTION,SUCCESS,FAILURE
from AUDIT_UNIFIED_ENABLED_POLICIES order by ENTITY_NAME,POLICY_NAME;

-- Application contexts configured for auditing (can be run on 12.1 and above)
col NAMESPACE format a20
col ATTRIBUTE format a20
select namespace,attribute,user_name from AUDIT_UNIFIED_CONTEXTS order by namespace;

-- Statistics of UNIFIED audit records
select count(*) from UNIFIED_AUDIT_TRAIL;

-- get MIN and MAX times on Unified Audit Trail
select min(EVENT_TIMESTAMP) mintime, max(EVENT_TIMESTAMP) maxtime from UNIFIED_AUDIT_TRAIL;

-- get the total number of records in OS spillover audit files (true iff DB is freshly created >=12.2)
select count(*) from gv$unified_audit_trail;

col min_time format a35
col max_time format a35
-- min and max timestamp value for records in OS files (true iff DB is freshly created >=12.2)
select min(event_timestamp) as min_time, max(event_timestamp) as max_time from gv$unified_audit_trail;

-- get the total number of records in db unified audit table
select count(*) from audsys.aud$unified;

-- get the audit table partition interval and tablespae per partition
col partition_name format a30
col tablespace_name format a30
col high_value format a35
select partition_name, tablespace_name, high_value from dba_tab_partitions where table_owner='AUDSYS' and table_name='AUD$UNIFIED' order by partition_name;

-- Number of unified audit records per partition of table
declare
sql_stmt varchar2(1024);
row_count number;
cursor get_tab is
select partition_name
from dba_tab_partitions
where table_owner=upper('AUDSYS') and table_name='AUD$UNIFIED' order by partition_name;
begin
dbms_output.put_line(chr(10));
dbms_output.put_line(chr(10));
dbms_output.put_line(rpad('Partition Name',50)
||' '||TO_CHAR(row_count)||' Rows');

dbms_output.put_line(rpad('................',50) || rpad('.........',10));

for get_tab_rec in get_tab loop
BEGIN
sql_stmt := 'select count(*) from AUDSYS.AUD$UNIFIED' ||' partition ( '||get_tab_rec.partition_name||' )';

EXECUTE IMMEDIATE sql_stmt INTO row_count;
dbms_output.put_line(rpad(get_tab_rec.partition_name,50)
||' '||TO_CHAR(row_count));
exception when others then
dbms_output.put_line
('Error counting partition rows for table AUDSYS.AUD$UNIFIED');
END;
end loop;
end;
/

-- Types of audit records
col AUDIT_TYPE format a20
select audit_type, count(*) Counts from UNIFIED_AUDIT_TRAIL
group by audit_type order by Counts desc, audit_type;

-- Get the different actions and their count
col ACTION_NAME format a25
select action_name, count(*) from unified_audit_trail group by action_name;

-- Get distinct DBID records
select DBID, count(*) from unified_audit_trail group by DBID;

-- Get the different system privilege used
col SYSTEM_PRIVILEGE_USED format a25
select system_privilege_used, count(*) from unified_audit_trail group by system_privilege_used;

-- Get what all unified policies was used to generate the records
set linesize 150;
col policies format a125
select NVL(unified_audit_policies, 'null') policies, count(*) from unified_audit_trail group by unified_audit_policies order by 1;

-- Get the count of mandatory records that was audited
select count(*) from unified_audit_trail where unified_audit_policies is NULL and (((action_name in ('CREATE AUDIT POLICY', 'ALTER AUDIT POLICY', 'DROP AUDIT POLICY', 'AUDIT', 'NOAUDIT')) or (action_name = 'EXECUTE' and object_name in ('DBMS_FGA', 'DBMS_AUDIT_MGMT'))));

-- get the client id
col client_identifier format a35
select action_name , client_identifier, count(*) from unified_audit_trail group by action_name,client_identifier;

-- get details on what are the distinct actions (and how many of them) executed by individual users
col dbusername format a35
select action_name , dbusername , count(*) total from unified_audit_trail group by action_name, dbusername order by dbusername, total desc;

-- get details on what are the distinct actions (and how many of them) executed by individual users and what policy led to generation of those records
col dbusername format a35
col UNIFIED_AUDIT_POLICIES format a50
select action_name , dbusername , UNIFIED_AUDIT_POLICIES, count(*) total from unified_audit_trail group by action_name, dbusername, UNIFIED_AUDIT_POLICIES order by dbusername, total desc;

-- AUDIT TRAIL MANAGEMENT Cleanup INFORMATION

-- List of Last Archive Timestamps
col AUDIT_TRAIL format a20
col RAC_INSTANCE alias RID format 99 truncated
col LAST_ARCHIVE_TS format a20
col DATABASE_ID alias DBID format 999999999999 truncated
col CONTAINER_GUID format a15 truncated
select AUDIT_TRAIL, RAC_INSTANCE as RID, LAST_ARCHIVE_TS, DATABASE_ID as DBID, CONTAINER_GUID
from DBA_AUDIT_MGMT_LAST_ARCH_TS
ORDER BY AUDIT_TRAIL, RID;

-- List of Cleanup Jobs
col JOB_NAME format a20 truncate
col JOB_STATUS format a6 truncate
col AUDIT_TRAIL format a20 truncate
col JOB_FREQUENCY format a40
col USE_LAST_ARCHIVE_TIMESTAMP format a2 truncate
col JOB_CONTAINER format a5 truncate
select AUDIT_TRAIL, JOB_NAME, JOB_STATUS, JOB_FREQUENCY, USE_LAST_ARCHIVE_TIMESTAMP, JOB_CONTAINER
from DBA_AUDIT_MGMT_CLEANUP_JOBS
ORDER BY Audit_Trail;

-- List of Cleanup Events completed
col AUDIT_TRAIL format a20 truncate
col RAC_INSTANCE alias RID format 99 truncate
col CLEANUP_TIME format a20
col DELETE_COUNT format 999999999
col WAS_FORCED format a1 truncate
select AUDIT_TRAIL, RAC_INSTANCE, CLEANUP_TIME, DELETE_COUNT, WAS_FORCED
from DBA_AUDIT_MGMT_CLEAN_EVENTS
ORDER BY AUDIT_TRAIL, CLEANUP_TIME;

spool off
@?/rdbms/admin/sqlsessend.sql
