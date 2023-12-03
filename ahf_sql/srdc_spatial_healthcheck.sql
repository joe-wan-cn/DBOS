Rem
Rem
Rem srdc_spatial_healthcheck.sql
Rem
Rem Copyright (c) 2012, 2023, Oracle and/or its affiliates.
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_spatial_healthcheck.sql - Oracle Locator / Oracle Spatial Health check
Rem
Rem    DESCRIPTION
Rem      Checks Oracle Locator / Oracle Spatial health of a DB
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_spatial_healthcheck.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    08/08/23 - ER 35688125 
Rem    smuthuku    03/08/23 - ER 35145694
Rem    sumendoz    01/23/23 - Added MDSYS user check, MDSYS objects check
Rem    bvongray    09/24/21 - ER 33285667
Rem    sumendoz    05/07/21 - Added multitenant info
Rem    sumendoz    03/03/21 - Added Index Type
Rem    sumendoz    12/07/20 - Added display of SVA setting,removed count_spatial_data
Rem    sumendoz    03/01/19 - Modified for SRDC standardization
Rem    xiaodowu    11/13/18 - Called by dbspatialinstall SRDC collection
Rem    xiaodowu    11/13/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_SPATIAL_HEALTHCHECK'
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
set HEADING on MARKUP html ON preformat off
SET LINESIZE 120;
SET SERVEROUTPUT ON FORMAT WRAP;
DECLARE
 db_name    VARCHAR2(30);
 db_version VARCHAR2(30);
 db_type     VARCHAR2(30);
 con_type    VARCHAR2(3);
 con_name    VARCHAR2(20);
 u_type     VARCHAR2(25);
 v_sva      VARCHAR2(5);
 v_count    NUMBER := 0;
 v_sdouser  NUMBER := 0;
 v_metadata mdsys.sdo_geom_metadata_table%ROWTYPE;
 v_statement   VARCHAR2 (250);

 no_spatial EXCEPTION;
 not_exist EXCEPTION;
 PRAGMA EXCEPTION_INIT(not_exist, -942);

 CURSOR c_feat IS SELECT comp_name,status,version
   FROM dba_registry ORDER BY comp_id;
 CURSOR c_inval IS SELECT * FROM dba_objects
   WHERE status !='VALID' AND OWNER = 'MDSYS' ORDER BY object_type, object_name;
 CURSOR c_other IS SELECT * FROM dba_objects a
   WHERE a.object_name || a.object_type IN
       (SELECT b.object_name || b.object_type FROM dba_objects b WHERE b.owner = 'MDSYS')
     AND a.owner NOT IN ('PUBLIC', 'MDSYS')
     AND a.object_type != 'JAVA RESOURCE'
   ORDER BY a.owner, a.object_name, a.object_type;
 CURSOR c_spatial_indexes IS
    SELECT i.owner,i.index_name,i.table_owner,i.table_name,c.column_name,
     i.status,i.ityp_name,i.domidx_status,i.domidx_opstatus
   FROM dba_indexes i, dba_ind_columns c
   WHERE i.ityp_name in ('SPATIAL_INDEX','SPATIAL_INDEX_V2') AND i.owner = c.index_owner
    AND i.index_name = c.index_name ORDER BY 1,2;
 CURSOR c_spatial_columns IS SELECT owner,table_name,column_name
  FROM dba_tab_columns
  WHERE data_type = 'SDO_GEOMETRY' AND owner != 'MDSYS' ORDER BY 1,2,3;
 CURSOR c_dba_errors IS SELECT owner, name, type, line, position, text
  FROM dba_errors
  WHERE owner = 'MDSYS'
  ORDER BY owner, name, sequence;

 PROCEDURE display_banner
 IS
 BEGIN
   DBMS_OUTPUT.PUT_LINE( '*************************************************************************');
 END display_banner;

 PROCEDURE show_geom_metadata(the_schema VARCHAR2,the_table VARCHAR2,
                               the_column VARCHAR2,tab_owner VARCHAR2)
 IS
  TYPE my_cursor_type IS REF CURSOR;
  my_cursor  my_cursor_type;
  my_cursor2 my_cursor_type;
  dimname VARCHAR2(64);
  lb number;
  ub number;
  tolerance number;
 BEGIN
  OPEN my_cursor FOR 'SELECT * FROM mdsys.sdo_geom_metadata_table WHERE sdo_owner='''||the_schema||''' AND sdo_table_name='''||the_table||''' AND sdo_column_name='''|| the_column || '''';
  FETCH my_cursor INTO v_metadata;
  IF my_cursor%NOTFOUND THEN
     DBMS_OUTPUT.PUT_LINE('...... This index does not have a VALID row in MDSYS.SDO_GEOM_METADATA_TABLE.');
     RAISE NO_DATA_FOUND;
  END IF;
  DBMS_OUTPUT.PUT ('.... Table = ' || tab_owner || '.' || v_metadata.sdo_table_name);
  DBMS_OUTPUT.PUT (', Column = ' || v_metadata.sdo_column_name);
  DBMS_OUTPUT.PUT_LINE(', SRID = ' || v_metadata.sdo_srid);
  DBMS_OUTPUT.PUT_LINE('.... DimInfo: ');
  OPEN my_cursor2 FOR
  'SELECT d.sdo_dimname,d.sdo_lb,d.sdo_ub,d.sdo_tolerance
   FROM mdsys.sdo_geom_metadata_table a, table(a.sdo_diminfo) d
   WHERE a.sdo_owner = ''' || v_metadata.sdo_owner ||
     ''' AND a.sdo_table_name = ''' || v_metadata.sdo_table_name ||
     ''' AND a.sdo_column_name = ''' || v_metadata.sdo_column_name || '''';
  LOOP
   FETCH my_cursor2 INTO dimname,lb,ub,tolerance;
   EXIT WHEN my_cursor2%NOTFOUND;
   DBMS_OUTPUT.PUT('...... Dim Name = ' || dimname);
   DBMS_OUTPUT.PUT(', Lower Bound = ' || lb);
   DBMS_OUTPUT.PUT(', Upper Bound = ' || ub);
   DBMS_OUTPUT.PUT_LINE(', Tolerance = ' || tolerance);
  END LOOP;
  CLOSE my_cursor2;
  CLOSE my_cursor;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN CLOSE my_cursor;
    WHEN OTHERS THEN RETURN;
  END show_geom_metadata;

BEGIN
 DBMS_OUTPUT.ENABLE(NULL);
 SELECT name INTO db_name FROM v$database;
 SELECT version INTO db_version FROM v$instance;
 IF TO_NUMBER((substr(db_version,1,2))) >= 19 THEN
   v_statement := 'SELECT version_full FROM v$instance';
   EXECUTE IMMEDIATE (v_statement) INTO db_version;
 END IF;

 DBMS_OUTPUT.PUT_LINE( 'Oracle Locator/Spatial Health Check Tool              ' || TO_CHAR(SYSDATE, 'MM-DD-YYYY HH24:MI:SS'));
 display_banner;
 DBMS_OUTPUT.PUT_LINE('Database:');
 display_banner;
 DBMS_OUTPUT.PUT_LINE ('--> name:                    ' || db_name );
 DBMS_OUTPUT.PUT_LINE ('--> version:                 ' || db_version );
  $IF DBMS_DB_VERSION.VER_LE_11_2 $THEN
    NULL;
 $ELSE
   SELECT DECODE(CDB, 'YES', 'Multitenant', 'Regular NON-multitenant') INTO db_type FROM v$database;
   SELECT decode(sys_context('USERENV','CON_ID'),1,'CDB','PDB'),
           sys_context('USERENV','CON_NAME')
   INTO con_type, con_name
   FROM DUAL;
   DBMS_OUTPUT.PUT_LINE ('--> database type:           ' || db_type);
   IF db_type = 'Multitenant' THEN
     DBMS_OUTPUT.PUT_LINE ('--> cdb or pdb:              ' || con_type);
     DBMS_OUTPUT.PUT_LINE ('--> container name:          ' || con_name);
   END IF;
 $END
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Database Components:');
 display_banner;
 FOR v_feat IN c_feat
 LOOP
   DBMS_OUTPUT.PUT_LINE( '--> ' || rpad(v_feat.comp_name, 35) || ' ' || rpad(v_feat.version, 10) || '   ' || rpad(v_feat.status, 10));
 END LOOP;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 IF dbms_registry.is_in_registry('SDO') = TRUE THEN
   DBMS_OUTPUT.PUT_LINE ('Oracle Spatial Status, MDSYS check and SVA Parameter:');
   display_banner;
   DBMS_OUTPUT.PUT_LINE('Oracle Spatial status is '|| dbms_registry.status('SDO'));
    IF to_number(substr(dbms_registry.version('SDO'),1,2)) >= 12 THEN
      SELECT DECODE(oracle_maintained, 'Y', 'Oracle_Maintained', 'NOT Oracle_Maintained!') 
        INTO u_type FROM dba_users WHERE username = 'MDSYS';
      DBMS_OUTPUT.PUT_LINE ('MDSYS is '|| u_type);
      select value into v_sva from v$parameter where upper(name) = 'SPATIAL_VECTOR_ACCELERATION';
      DBMS_OUTPUT.PUT_LINE ('SPATIAL_VECTOR_ACCELERATION is '|| v_sva);
    END IF;
 ELSIF dbms_registry.is_in_registry('ORDIM') = TRUE THEN
    SELECT 1 INTO v_count FROM dba_users WHERE username = 'MDSYS';
   IF v_count = 1 THEN
     DBMS_OUTPUT.PUT_LINE ('Oracle Locator is installed as part of');
     display_banner;
     DBMS_OUTPUT.PUT_LINE(dbms_registry.comp_name('ORDIM')||' status is '||
        dbms_registry.status('ORDIM')||' and is at version '||
        dbms_registry.version('ORDIM'));
   END IF;
 ELSE
   RAISE no_spatial;
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Invalid Objects in MDSYS Schema:');
 display_banner;
 FOR v_inval IN c_inval
 LOOP
   DBMS_OUTPUT.PUT_LINE( '.. MDSYS.' || rpad(v_inval.object_name,30) ||
     ' -  ' || v_inval.object_type );
   v_count := c_inval%rowcount;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no Invalid objects in the MDSYS schema');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Compilation errors of invalid MDSYS-owned objects:');
 display_banner;
 v_count := 0;
 FOR v_dba_errors IN c_dba_errors LOOP
   EXIT WHEN (c_dba_errors%NOTFOUND);
   DBMS_OUTPUT.PUT_LINE( '.. ' || v_dba_errors.type || ' ' ||
   v_dba_errors.owner || '.' || v_dba_errors.name );
   DBMS_OUTPUT.PUT_LINE( '.... at Line/Col: ' || TO_CHAR(v_dba_errors.line) || '/' ||
   TO_CHAR(v_dba_errors.position) );
   DBMS_OUTPUT.PUT_LINE('.... ' || v_dba_errors.text);
   v_count := c_dba_errors%ROWCOUNT;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no errors from MDSYS-owned objects');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Possible SDO Objects found in schemas other than MDSYS:');
 display_banner;
 FOR v_other IN c_other
 LOOP
   DBMS_OUTPUT.PUT_LINE( '.. ' || v_other.owner || '.' ||
    v_other.object_name || ' -  ' || v_other.object_type || ' -  ' || v_other.status );
   v_count := c_other%rowcount;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('No SDO Object found in schemas other than MDSYS');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Tables with Spatial Columns:');
 display_banner;
 v_count := 0;
 FOR v_spatial_columns IN c_spatial_columns LOOP
 DBMS_OUTPUT.PUT_LINE('.. ' || v_spatial_columns.owner || '.'
   || v_spatial_columns.table_name
   || ' has spatial column '
   || v_spatial_columns.column_name);
 v_count := c_spatial_columns%rowcount;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no Spatial columns');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Spatial Indexes:');
 display_banner;
 v_count := 0;
 FOR v_spatial_indexes IN c_spatial_indexes LOOP
 DBMS_OUTPUT.PUT('.. ' || v_spatial_indexes.owner ||
   '.' || v_spatial_indexes.index_name || ' is ');
 IF (v_spatial_indexes.status != 'VALID' OR
     v_spatial_indexes.domidx_status != 'VALID' OR
     v_spatial_indexes.domidx_opstatus != 'VALID') THEN
   DBMS_OUTPUT.PUT_LINE('INVALID');
   DBMS_OUTPUT.PUT_LINE('.... Index Type = '||v_spatial_indexes.ityp_name);
   DBMS_OUTPUT.PUT_LINE('.... INDEX STATUS => '||v_spatial_indexes.status);
   DBMS_OUTPUT.PUT_LINE('.... DOMAIN INDEX STATUS => '||v_spatial_indexes.domidx_status);
   DBMS_OUTPUT.PUT_LINE('.... DOMAIN INDEX OPERATION STATUS => '||v_spatial_indexes.domidx_opstatus);
 ELSE
   DBMS_OUTPUT.PUT_LINE('VALID');
   DBMS_OUTPUT.PUT_LINE('.... Index Type = '||v_spatial_indexes.ityp_name);
 END IF;
 -- get MDSYS.SDO_GEOM_METADATA_TABLE per index
 show_geom_metadata(v_spatial_indexes.owner,v_spatial_indexes.table_name,
    v_spatial_indexes.column_name,v_spatial_indexes.table_owner);
 DBMS_OUTPUT.PUT_LINE ('.');
 v_count := c_spatial_indexes%rowcount;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no Spatial indexes');
   DBMS_OUTPUT.PUT_LINE ('.');
 END IF;

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Testing Spatial Index Creation:');
 display_banner;
 -- Create tfaora_sdo_hc user
 SELECT COUNT (1) INTO v_sdouser FROM dba_users
  WHERE username = 'TFAORA_SDO_HC';
 IF v_sdouser < 1 THEN
  DBMS_OUTPUT.PUT_LINE ('..Creating user TFAORA_SDO_HC');
  v_statement := 'GRANT connect,resource TO tfaora_sdo_hc IDENTIFIED BY tfaora_sdo_hc';
  EXECUTE IMMEDIATE (v_statement);
  DBMS_OUTPUT.PUT_LINE ('....User TFAORA_SDO_HC created successfully');
 ELSE
  DBMS_OUTPUT.PUT_LINE ('..Using existing TFAORA_SDO_HC user');
  BEGIN
   EXECUTE IMMEDIATE ('DROP TABLE tfaora_sdo_hc.tfaora_sdo_hc_tab PURGE');
   EXECUTE IMMEDIATE ('DROP TABLE tfaora_sdo_hc.tfaora_sdo_hc_tabg PURGE');
  EXCEPTION
   WHEN not_exist THEN NULL;
  END;
  MDSYS.SDO_META.DELETE_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TAB','GEOM');
  MDSYS.SDO_META.DELETE_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TABG','GEOM');
 END IF;
 EXECUTE IMMEDIATE ('GRANT create sequence to tfaora_sdo_hc');
 EXECUTE IMMEDIATE ('GRANT create table to tfaora_sdo_hc');
 EXECUTE IMMEDIATE ('GRANT unlimited tablespace to tfaora_sdo_hc');
 -- Create Non-Geodetic index
 DBMS_OUTPUT.PUT_LINE ('..Testing creation of Non-Geodetic index');
 v_statement :=
   'CREATE TABLE tfaora_sdo_hc.tfaora_sdo_hc_tab (id NUMBER, geom MDSYS.SDO_GEOMETRY)';
 DBMS_OUTPUT.PUT_LINE('....Creating table TFAORA_SDO_HC_TAB');
 EXECUTE IMMEDIATE(v_statement);
 DBMS_OUTPUT.PUT_LINE('....Inserting test data');
 v_statement :=
      'INSERT INTO tfaora_sdo_hc.tfaora_sdo_hc_tab VALUES (1,'
   || 'MDSYS.SDO_GEOMETRY(2003,NULL,NULL,'
   || 'MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),'
   || 'MDSYS.SDO_ORDINATE_ARRAY(1,1,5,7)))';
 EXECUTE IMMEDIATE(v_statement);
 MDSYS.SDO_META.INSERT_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TAB','GEOM',SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',0,20,0.005),SDO_DIM_ELEMENT('Y',0,20,0.005)),NULL);
 v_statement :=
      'CREATE INDEX tfaora_sdo_hc.tfaora_sdo_hc_idx '
   || 'ON tfaora_sdo_hc.tfaora_sdo_hc_tab(geom) INDEXTYPE IS MDSYS.SPATIAL_INDEX';
 DBMS_OUTPUT.PUT_LINE('....Creating non-geodetic index SP_HC_IDX');
 EXECUTE IMMEDIATE(v_statement);
 DBMS_OUTPUT.PUT_LINE ('....Non-geodetic index SP_HC_IDX created successfully');
 -- Create Geodetic index
 DBMS_OUTPUT.PUT_LINE ('..Testing creation of Geodetic index');
 v_statement :=
  'CREATE TABLE tfaora_sdo_hc.tfaora_sdo_hc_tabg(id NUMBER, geom MDSYS.SDO_GEOMETRY)';
 DBMS_OUTPUT.PUT_LINE('....Creating table TFAORA_SDO_HC_TABG');
 EXECUTE IMMEDIATE(v_statement);
 v_statement :=
      'INSERT INTO tfaora_sdo_hc.tfaora_sdo_hc_tabg VALUES (1,'
   || 'MDSYS.SDO_GEOMETRY(2003,8307,NULL,'
   || 'MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),'
   || 'MDSYS.SDO_ORDINATE_ARRAY(-90,45,-75,60)))';
 DBMS_OUTPUT.PUT_LINE('....Inserting test data');
 EXECUTE IMMEDIATE(v_statement);
 MDSYS.SDO_META.INSERT_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TABG','GEOM',SDO_DIM_ARRAY(SDO_DIM_ELEMENT('Longitude', -180, 180, 10),SDO_DIM_ELEMENT('Latitude', -90, 90, 10)),8307);
 v_statement :=
      'CREATE INDEX tfaora_sdo_hc.tfaora_sdo_hc_geod_idx '
   || 'ON tfaora_sdo_hc.tfaora_sdo_hc_tabg(geom) INDEXTYPE IS MDSYS.SPATIAL_INDEX';
 DBMS_OUTPUT.PUT_LINE('....Creating geodetic index SP_HC_GEOD_IDX');
 EXECUTE IMMEDIATE(v_statement);
 DBMS_OUTPUT.PUT_LINE ('....Geodetic index SP_HC_GEOD_IDX created successfully');
 DBMS_OUTPUT.PUT_LINE ('  ');
 IF v_sdouser < 1 THEN
  DBMS_OUTPUT.PUT_LINE ('..Dropping user TFAORA_SDO_HC');
  EXECUTE IMMEDIATE ('DROP USER tfaora_sdo_hc CASCADE');
  DBMS_OUTPUT.PUT_LINE ('....User TFAORA_SDO_HC dropped successfully');
 ELSE
  DBMS_OUTPUT.PUT_LINE ('..Dropping TFAORA_SDO_HC objects created by health check');
  EXECUTE IMMEDIATE ('DROP TABLE tfaora_sdo_hc.tfaora_sdo_hc_tab PURGE');
  EXECUTE IMMEDIATE ('DROP TABLE tfaora_sdo_hc.tfaora_sdo_hc_tabg PURGE');
  MDSYS.SDO_META.DELETE_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TAB','GEOM');
  MDSYS.SDO_META.DELETE_ALL_SDO_GEOM_METADATA('TFAORA_SDO_HC','TFAORA_SDO_HC_TABG','GEOM');
  DBMS_OUTPUT.PUT_LINE ('....Spatial health check objects dropped successfully');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('  ');
 DBMS_OUTPUT.PUT_LINE ('Spatial Index Creation Test complete');
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;

 EXCEPTION
  WHEN no_spatial THEN
   DBMS_OUTPUT.PUT_LINE ('!! Neither Oracle Spatial nor Oracle Locator is installed !!');
   display_banner;
  WHEN OTHERS THEN
   DBMS_OUTPUT.PUT('....');
   DBMS_OUTPUT.PUT_LINE (SQLERRM);
   display_banner;

END;
/
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
