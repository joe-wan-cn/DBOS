Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_validate_geom.sql /main/2 2021/10/12 12:46:51 bvongray Exp $
Rem
Rem srdc_spatial_validate_geom.sql
Rem
Rem Copyright (c) 2018, 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_spatial_validate_geom.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      Called by SRDC collection for dbspatialexportimport
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_validate_geom.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/24/21 - ER 33285667
Rem    xiaodowu    10/19/18 - Called by SRDC collection for
Rem                           dbspatialexportimport
Rem    xiaodowu    10/19/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_spatial_validate_geom.sql - Validation of Spatial geometries
define SRDCNAME='Spatial_Geometry_Validation'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
        to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on
REM
spool &&SRDCSPOOLNAME..HTM
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
select '| Table Owner:     '||'&1' from v$instance
union all
select '| Table:           '||'&2' from v$instance
union all
select '| Column:          '||'&3' from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set HEADING on MARKUP html preformat off
REM === -- end of standard header -- ===
REM


DEFINE OWN = &1
DEFINE TAB = &2
DEFINE COL = &3

SET SERVEROUTPUT ON

DECLARE
 CURSOR c IS  
   SELECT  c.rowid ,
           sdo_geom.validate_geometry_with_context(&&3,m.diminfo) Valid
   FROM    &&1..&&2 c, all_sdo_geom_metadata m
   WHERE   m.owner       = UPPER('&&1') 
   AND     m.table_name  = UPPER('&&2') 
   AND     m.column_name = UPPER('&&3'); 
BEGIN
DBMS_OUTPUT.ENABLE(1000000);
DBMS_OUTPUT.PUT_LINE ('Validating geometries in    Table: ' || UPPER('&&1') || '.' || UPPER('&&2') || '     Column: ' || UPPER('&&3'));
DBMS_OUTPUT.PUT_LINE ('.');
DBMS_OUTPUT.PUT_LINE ('Rows with Invalid Geometry: ');
FOR c_cur IN c
LOOP
 IF c_cur.valid IS NOT NULL AND c_cur.valid <> 'TRUE' THEN 
   DBMS_OUTPUT.PUT_LINE('Rowid: '||to_char(c_cur.rowid)||' Error :'||c_cur.valid);
 END IF;
END LOOP;
DBMS_OUTPUT.PUT_LINE('Note: If no rows are displayed the geometries are all valid');
END;
/    
Rem===========================================================================================================================================
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem===========================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
 
