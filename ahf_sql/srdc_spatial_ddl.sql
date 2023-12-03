Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_ddl.sql /main/1 2018/11/05 06:04:08 xiaodowu Exp $
Rem
Rem srdc_spatial_ddl.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_spatial_ddl.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem       Called by SRDC collection for dbspatialexportimport
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_ddl.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    10/19/18 - Called by SRDC collection for
Rem                           dbspatialexportimport
Rem    xiaodowu    10/19/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_spatial_ddl.sql - collect Oracle Spatial DDL information
define SRDCNAME='Spatial_DDL_Information'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||'&&1'||'_'||'&&2'||'_'||
        to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on
REM
spool &&SRDCSPOOLNAME..txt
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||
        to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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
set HEADING on MARKUP html preformat off
REM === -- end of standard header -- ===
set HEADING oN MARKUP html OFF preformat off
SET LONG 10000000 LINESIZE 1000 PAGESIZE 0
col DDL format a1000
DEFINE OBJ_NAME = &2
DEFINE OBJ_OWNER = &1

exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', true);

select DBMS_METADATA.GET_DDL('TABLE', '&&obj_name','&&obj_owner') DDL from dual;

SELECT DBMS_METADATA.GET_DEPENDENT_DDL('INDEX','&&obj_name','&&obj_owner') as obj_ddl FROM dual;

PROMPT "OUTPUT FROM ALL_SDO_GEOM_METADATA"
PROMPT "================================="

SELECT 'Owner:   '||OWNER||'              
Table:   '||TABLE_NAME||'              
Column:  '||COLUMN_NAME||'              
Diminfo: ',DIMINFO,
'Srid:    '||to_char(SRID)
FROM   ALL_SDO_GEOM_METADATA
WHERE  OWNER = '&&obj_owner'
AND    TABLE_NAME  = '&&obj_name';
spool off
@?/rdbms/admin/sqlsessend.sql
 
