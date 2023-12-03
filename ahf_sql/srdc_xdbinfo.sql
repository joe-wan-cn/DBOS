Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_xdbinfo.sql /main/2 2021/03/24 11:11:30 bvongray Exp $
Rem
Rem srdc_xdbinfo.sql
Rem
Rem Copyright (c) 2017, 2021, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_xdbinfo.sql - Oracle XML Database Check
Rem
Rem    DESCRIPTION
Rem      Checks the Oracle XML Database (XDB) health of a DB
Rem    NOTES
Rem     .
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_xdbinfo.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    03/19/21 - script updates
Rem    bburton     07/11/17 - SQL to gather xdb information from a database.
Rem    bburton     07/11/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='XDB_INFO'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
       to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name: ' || '&&SRDCNAME'  as "SRDC COLLECTION HEADER"  from dual
union all
select 'Time: ' || to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine: ' || host_name from v$instance
union all
select 'Version: '|| version from v$instance
union all
select 'DBName: '||name from v$database
union all
select 'Instance: '||instance_name from v$instance
/
set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/

define LOWTHRESHOLD=10
define MIDTHRESHOLD=62
define VERBOSE=TRUE

set veri off;
set feedback off;
REM === -- end of standard header -- ===
set markup html preformat on
set lines 150 trimspool on pages 50000 long 100000 tab off

PROMPT *************************************************************************
PROMPT Instance and platform information
PROMPT *************************************************************************
COLUMN Platform FORMAT a30 HEADING 'PLATFORM'
SELECT instance_name, version FROM v$instance;
SELECT NLS_UPPER(platform_name) "Platform" FROM v$database;
SELECT substrb(parameter,1,24)parameter,
       substrb(value,1,12)value
FROM nls_database_parameters
WHERE parameter LIKE '%SET' ORDER BY 1;
SELECT substrb(Comp_ID,1,10)Comp_ID,
	 substrb(Status,1,8)Status,
	 substrb(Version,1,12)Version,
	 substrb(Comp_Name,1,35)Comp_Name
FROM DBA_Registry
ORDER by 1,2;

PROMPT *************************************************************************
PROMPT Invalid objects under SYS and XDB, and related rows from dba_errors
PROMPT *************************************************************************
COLUMN owner       FORMAT a10 HEADING 'OWNER'
COLUMN object_name FORMAT a30 HEADING 'OBJECT NAME'
COLUMN object_type FORMAT a15 HEADING 'OBJECT_TYPE'
SELECT owner, object_name, object_type, status
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID'
  AND owner IN ('SYS', 'XDB')
ORDER BY OWNER, OBJECT_NAME, OBJECT_TYPE;
COLUMN name        FORMAT a30 HEADING 'NAME'
COLUMN position    FORMAT a10 HEADING 'ERR LOC'
COLUMN text        FORMAT a150 HEADING 'COMPILATION ERROR'
SELECT e.owner, e.name, TO_CHAR(e.line) || '/' || TO_CHAR(e.position) "POSITION", e.text
FROM dba_errors e
where owner in ('SYS', 'XDB')
ORDER BY e.owner, e.name, e.sequence;

PROMPT *************************************************************************
PROMPT Privileges granted to PUBLIC and XDB
PROMPT *************************************************************************
select substrb(owner,1,10)owner,
       substrb(table_name,1,20)table_name,
       substrb(grantee,1,12)grantee,
       substrb(privilege,1,10)privilege
from dba_tab_privs
where table_name in ('UTL_FILE','DBMS_LOB','UTL_HTTP','DBMS_JOB','DBMS_SQL','DBMS_RAW','DBMS_RANDOM','UTL_SMTP','DUAL','ALL_USERS')
and grantee in ('PUBLIC', 'XDB')
order by 1,2,3;

PROMPT *************************************************************************
PROMPT Information on ANONYMOUS user
PROMPT *************************************************************************
col account_status format a18
col user_id format 999999
col username format a10
col ptime heading 'PASSWORD CHANGE TIME'
col lock_date heading 'ACCOUNT LOCK DATE'
select username, d.user_id, d.created, u.ptime, d.lock_date, d.expiry_date, d.account_status
from dba_users d, user$ u
where d.user_id = u.user#
  and d.username = 'ANONYMOUS';

PROMPT *************************************************************************
PROMPT List of XMLType tables and tables with XMLType columns
PROMPT *************************************************************************
set lines 200
col owner format a20
col table_name format a28
col XMLSCHEMA format a75
select OWNER,TABLE_NAME, STORAGE_TYPE, XMLSCHEMA
from dba_xml_tables
order by 1,2;
col column_name format a28
select OWNER, TABLE_NAME, COLUMN_NAME, STORAGE_TYPE, XMLSCHEMA
from dba_xml_tab_cols
order by 1,2,3;

PROMPT *************************************************************************
PROMPT List of User-defined XMLIndexes
PROMPT *************************************************************************
col parameters format a50 wrap heading 'ParameterS'
select index_owner, index_name, parameters, table_owner, table_name, type, index_type from dba_xml_indexes;

PROMPT *************************************************************************
PROMPT Relevant Database parameters
PROMPT *************************************************************************
set lines 200
Col "Parameter" for a60
col "Session Value"  for a30
col "Instance Value"  for a30
show parameter compatible
show parameter dispatcher
show parameter SHARED_SERVERS
show parameter local_listener
show parameter services

PROMPT *************************************************************************
PROMPT Configured ports
PROMPT *************************************************************************
COLUMN http_port FORMAT 99999 HEADING 'HTTP Port'
COLUMN ftp_port  FORMAT 99999 HEADING 'FTP Port'
select dbms_xdb.gethttpport http_port,
       dbms_xdb.getftpport ftp_port
  from dual;
COLUMN "Protocol" FORMAT a15 HEADING 'Protocol'
COLUMN "https_port" FORMAT a10 HEADING 'HTTPS Port'
select extractValue(value(x),'/httpconfig/http2-protocol', 'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"') "Protocol"
,      extractValue(value(x),'/httpconfig/http2-port', 'xmlns="http://xmlns.oracle.com/xdb/xdbconfig.xsd"') "https_port"
from   table(xmlsequence(extract(xdburitype('/xdbconfig.xml').getXML(),'/xdbconfig/sysconfig/protocolconfig/httpconfig'))) x
/

PROMPT *************************************************************************
PROMPT XDB Repository Information
PROMPT *************************************************************************
PROMPT -- Registered schemas:
col schema_url format a60
select owner, schema_url, local
from dba_xml_schemas
order by 1,2;

PROMPT -- Number of resources per user:
col user format a12
select distinct (a.username) "USER", count (r.xmldata) "TOTAL Resources"
from dba_users a, xdb.xdb$resource r
where sys_op_rawtonum (extractvalue (value(r),'/Resource/OwnerID/text()')) = a.USER_ID
group by a.username;

PROMPT -- Can the Resource_View be queried?'
COLUMN any_path FORMAT a15 HEADING 'ANY_PATH'
set lines 260
select any_path from resource_view where equals_path(RES, '/xdbconfig.xml')=1;

PROMPT -- Display the xdbconfig.xml
select XDBUriType('/xdbconfig.xml').getXML() from dual;

PROMPT *************************************************************************
PROMPT Registry information
PROMPT *************************************************************************
col comments format a38
col version format a10
col namespace format a10
col action_time format a30
col action format a15
col bundle_series format a15
select * from sys.registry$history order by 1 desc;

SET SERVEROUTPUT OFF
Rem===========================================================================================================================================
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
PROMPT
Rem===========================================================================================================================================
set verify on echo on
@?/rdbms/admin/sqlsessend.sql
exit
