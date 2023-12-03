Rem
Rem
Rem srdc_Text_Health_Check.sql
Rem
Rem Copyright (c) 2012, 2023, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_text_healthcheck.sql - Oracle Text Health Check
Rem
Rem    DESCRIPTION
Rem      Called by dbtextupgrade SRDC collection
Rem      Checks Oracle Text health of a DB
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_text_healthcheck.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA      
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    08/08/23 - ER 35688125
Rem    smuthuku    03/08/23 - ER 35145694
Rem    sumendoz    05/07/21 - Added db characteset and multitenant info
Rem    sumendoz    03/03/21 - Added display of COMPATIBLE and Text Events
Rem    sumendoz    03/04/19 - Modified for SRDC standardization
Rem    xiaodowu    11/13/18 - Called by dbtextupgrade SRDC collection
Rem    xiaodowu    11/13/18 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='Text_Health_Check'
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
SET LINESIZE 90;
SET SERVEROUTPUT ON FORMAT WRAP;
DECLARE
 db_name     VARCHAR2(30);
 db_version VARCHAR2(30);
 db_compat   VARCHAR2(10);
 db_charset  VARCHAR2(15);
 db_type     VARCHAR2(30);
 con_type    VARCHAR2(3);
 con_name    VARCHAR2(20); 
 v_count     NUMBER := 0;
 v_ctxuser   NUMBER := 0;
 v_stmt VARCHAR2 (250);
 l_level NUMBER;

 not_exist EXCEPTION;
 PRAGMA EXCEPTION_INIT(not_exist, -942);

 CURSOR c_feat IS SELECT comp_name,status,version
   FROM dba_registry ORDER BY comp_id;
 CURSOR c_par IS SELECT * FROM ctxsys.ctx_parameters
   WHERE par_name LIKE '%_INDEX_MEMORY' 
      OR par_name LIKE '%_OPTIMIZE' 
   ORDER BY par_name;
 CURSOR c_inval IS SELECT * FROM dba_objects
   WHERE status !='VALID' AND OWNER = 'CTXSYS' ORDER BY object_type, object_name;
 CURSOR c_other_objects IS SELECT owner, object_name, object_type, status FROM dba_objects
   WHERE owner = 'SYS'
     AND (object_name like 'CTX_%' or object_name like 'DRI%')
   ORDER BY 2,3;
 CURSOR c_count_obj IS SELECT object_type, count(*) count FROM dba_objects
   WHERE owner='CTXSYS' GROUP BY object_type ORDER BY 1;
 CURSOR c_text_indexes IS
   SELECT c.*, i.status,i.domidx_status,i.domidx_opstatus
   FROM ctxsys.ctx_indexes c, dba_indexes i
   WHERE c.idx_owner = i.owner
     AND c.idx_name = i.index_name
   ORDER BY 2,3;
 CURSOR c_dba_errors IS SELECT owner, name, type, line, position, text
  FROM dba_errors
  WHERE owner = 'CTXSYS'
      OR (owner = 'SYS' AND (name like 'CTX_%' or name like 'DRI%'))
  ORDER BY owner, name, sequence;
 CURSOR c_errors IS SELECT * FROM ctxsys.ctx_index_errors
   ORDER BY err_timestamp DESC, err_index_owner, err_index_name;

 PROCEDURE display_banner
 IS
 BEGIN
   DBMS_OUTPUT.PUT_LINE( '**********************************************************************');
 END display_banner;

BEGIN
 DBMS_OUTPUT.ENABLE(900000);
 SELECT name INTO db_name FROM v$database;
 SELECT version INTO db_version FROM v$instance;
 IF TO_NUMBER((substr(db_version,1,2))) >= 19 THEN
   v_stmt := 'SELECT version_full FROM v$instance';
   EXECUTE IMMEDIATE (v_stmt) INTO db_version;
 END IF; 
 SELECT value INTO db_compat FROM v$parameter WHERE upper(name) = 'COMPATIBLE';
 SELECT value INTO db_charset FROM nls_database_parameters WHERE parameter='NLS_CHARACTERSET';

 DBMS_OUTPUT.PUT_LINE( 'Oracle Text Health Check Tool ' || TO_CHAR(SYSDATE, 'MM-DD-YYYY HH24:MI:SS'));
 display_banner;
 DBMS_OUTPUT.PUT_LINE('Database:');
 display_banner;
 DBMS_OUTPUT.PUT_LINE ('--> name:                    ' || db_name );
 DBMS_OUTPUT.PUT_LINE ('--> version:                 ' || db_version );
 DBMS_OUTPUT.PUT_LINE ('--> compatible:              ' || db_compat );
 DBMS_OUTPUT.PUT_LINE ('--> db characterset:         ' || db_charset );
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
 FOR v_feat IN c_feat LOOP
   DBMS_OUTPUT.PUT_LINE( '--> ' || rpad(v_feat.comp_name, 35) || ' '
     || rpad(v_feat.version, 10) || '   ' || rpad(v_feat.status, 10));
 END LOOP;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Oracle Text Parameters (CTX_PARAMETERS):');
 display_banner;
 FOR v_par IN c_par LOOP
   DBMS_OUTPUT.PUT_LINE( '.. ' || rpad(v_par.par_name, 30) || ':     '
     || rpad(v_par.par_value, 20) );
 END LOOP;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('System-level Enabled Text-related Events:');
 display_banner;
 v_count := 0;
 FOR l_event IN 30579..30582 LOOP
   DBMS_SYSTEM.READ_EV(l_event,l_level);
   IF l_level > 0 THEN
     DBMS_OUTPUT.PUT_LINE('Event '||TO_CHAR (l_event)||' is set at level '||TO_CHAR (l_level));
     v_count := v_count + 1;
   END IF;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no Text-related events enabled');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Invalid Objects in CTXSYS Schema:');
 display_banner;
 v_count := 0;
 FOR v_inval IN c_inval LOOP
   DBMS_OUTPUT.PUT_LINE( '.. CTXSYS.' || rpad(v_inval.object_name,30) ||
     ' -  ' || v_inval.object_type );
   v_count := c_inval%ROWCOUNT;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no invalid objects in the CTXSYS schema');
   DBMS_OUTPUT.PUT_LINE ('.');
 END IF;

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Possible Text-related Objects under the SYS schema:');
 display_banner;
 v_count := 0;
 FOR v_other_objects IN c_other_objects LOOP
   DBMS_OUTPUT.PUT_LINE( '.. ' || v_other_objects.owner || '.' ||
    v_other_objects.object_name || ' -  ' || v_other_objects.object_type ||
    ' -  ' || v_other_objects.status );
   v_count := c_other_objects%ROWCOUNT;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no Text-related Objects under the SYS schema');
 ELSE
   DBMS_OUTPUT.PUT_LINE ('  ');
   DBMS_OUTPUT.PUT_LINE('In 12.2 and above, we expect to see *only* SYS.CTXAGGIMP listed above.');
   DBMS_OUTPUT.PUT_LINE('In 12.1 and below, if objects are listed, review the following notes:');
   DBMS_OUTPUT.PUT_LINE('  Note 1313273.1 - Invalid SYS-Owned Text Objects / How To Remove');
   DBMS_OUTPUT.PUT_LINE('      Text Objects From The SYS Schema When Text Is Installed/In Use?');
   DBMS_OUTPUT.PUT_LINE('  Note 558894.1  - Invalid Oracle Text Object Under User SYS Even');
   DBMS_OUTPUT.PUT_LINE('      When Oracle Text is not Installed');
   DBMS_OUTPUT.PUT_LINE('If Oracle Text is invalid, open a Service Request.');
   DBMS_OUTPUT.PUT_LINE('  Support, see INTERNAL Note.746970.1.');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Compilation errors of invalid Text-related objects under');
 DBMS_OUTPUT.PUT_LINE (' CTXSYS and SYS schemas:');
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
   DBMS_OUTPUT.PUT_LINE('There are no errors from Text-related objects under');
   DBMS_OUTPUT.PUT_LINE(' CTXSYS and SYS schemas');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ( 'Summary count of CTXSYS schema objects:');
 display_banner;
 FOR v_count_obj IN c_count_obj LOOP
   DBMS_OUTPUT.PUT_LINE('.. ' || rpad(v_count_obj.object_type,14) ||
                        '   ' || lpad(v_count_obj.count,3));
 END LOOP;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Text Indexes:');
 display_banner;
 v_count := 0;
 FOR v_text_indexes IN c_text_indexes LOOP
 DBMS_OUTPUT.PUT('.. ' || v_text_indexes.idx_owner ||
   '.' || v_text_indexes.idx_name || ' is ');
 IF (v_text_indexes.status != 'VALID' OR
     v_text_indexes.domidx_status != 'VALID' OR
     v_text_indexes.domidx_opstatus != 'VALID') THEN
   DBMS_OUTPUT.PUT_LINE('INVALID');
   DBMS_OUTPUT.PUT_LINE('.... INDEX STATUS => '||v_text_indexes.status);
   DBMS_OUTPUT.PUT_LINE('.... DOMAIN INDEX STATUS => '||v_text_indexes.domidx_status);
   DBMS_OUTPUT.PUT_LINE('.... DOMAIN INDEX OPERATION STATUS => '
     ||v_text_indexes.domidx_opstatus);
 ELSE
   DBMS_OUTPUT.PUT_LINE('VALID');
 END IF;
 DBMS_OUTPUT.PUT('.... Table: ' || v_text_indexes.idx_table_owner
   || '.' || v_text_indexes.idx_table);
 DBMS_OUTPUT.PUT_LINE(', Indexed Column: ' || v_text_indexes.idx_text_name);
 DBMS_OUTPUT.PUT('.... Index Type: ' || v_text_indexes.idx_type);
 DBMS_OUTPUT.PUT_LINE(', SYNC Type: ' || NVL(v_text_indexes.idx_sync_type,'MANUAL'));
 IF (v_text_indexes.idx_sync_type = 'AUTOMATIC') THEN
   DBMS_OUTPUT.PUT_LINE('.... Automatic SYNC Interval: '||v_text_indexes.idx_sync_interval);
 END IF; 
 v_count := c_text_indexes%ROWCOUNT;
 END LOOP;
 IF v_count = 0 then
   DBMS_OUTPUT.PUT_LINE('There are no Text indexes');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Ten (10) most recent text index errors (ctx_index_errors):');
 display_banner;
 v_count := 0;
 FOR v_errors IN c_errors LOOP
   EXIT WHEN (c_errors%NOTFOUND) OR (c_errors%ROWCOUNT > 9);
   DBMS_OUTPUT.PUT_LINE(to_char(v_errors.ERR_TIMESTAMP,'Dy Mon DD HH24:MI:SS YYYY'));
   DBMS_OUTPUT.PUT_LINE('.. Index name: ' || v_errors.err_index_owner
     || '.' || v_errors.err_index_name || '     Rowid: ' || v_errors.err_textkey);
   DBMS_OUTPUT.PUT_LINE('.. Error: ');
   DBMS_OUTPUT.PUT_LINE('   '||
     rtrim(replace(v_errors.err_text,chr(10),chr(10)||'   '),chr(10)||'   '));
   v_count := c_errors%ROWCOUNT;
 END LOOP;
 IF v_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('There are no errors logged in CTX_INDEX_ERRORS');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;
 DBMS_OUTPUT.PUT_LINE ('Testing Text Index Creation:');
 display_banner;
 -- Create tfaora_ctx_hc user
 SELECT COUNT (1) INTO v_ctxuser FROM dba_users
  WHERE username = 'TFAORA_CTX_HC';
 IF v_ctxuser < 1 THEN
  DBMS_OUTPUT.PUT_LINE ('..Creating user TFAORA_CTX_HC');
  v_stmt := 'GRANT connect,resource TO tfaora_ctx_hc IDENTIFIED BY tfaora_ctx_hc';
  EXECUTE IMMEDIATE (v_stmt);
  DBMS_OUTPUT.PUT_LINE ('....User TFAORA_CTX_HC created successfully');
 ELSE
  DBMS_OUTPUT.PUT_LINE ('..Using existing TFAORA_CTX_HC user');
  BEGIN
   EXECUTE IMMEDIATE ('DROP TABLE tfaora_ctx_hc.tfaora_ctx_hc_tab PURGE');
  EXCEPTION
   WHEN not_exist THEN NULL;
  END;
 END IF;
 EXECUTE IMMEDIATE ('GRANT ctxapp to tfaora_ctx_hc');
 EXECUTE IMMEDIATE ('GRANT create table to tfaora_ctx_hc');
 EXECUTE IMMEDIATE ('GRANT unlimited tablespace to tfaora_ctx_hc');
 -- Create context index
 DBMS_OUTPUT.PUT_LINE ('..Testing creation of Text index type CONTEXT');
 v_stmt :=
     'CREATE TABLE tfaora_ctx_hc.tfaora_ctx_hc_tab (quick_id NUMBER '
   || 'constraint tfaora_ctx_hc_pk PRIMARY KEY, '
   || 'text VARCHAR2(80))';
 DBMS_OUTPUT.PUT_LINE('....Creating table TFAORA_CTX_HC_TAB');
 EXECUTE IMMEDIATE(v_stmt);
 DBMS_OUTPUT.PUT_LINE('....Inserting test data');
 v_stmt :=
      'INSERT INTO tfaora_ctx_hc.tfaora_ctx_hc_tab VALUES (1,'
   || '''The cat sat on the mat'')';
 EXECUTE IMMEDIATE(v_stmt);
 v_stmt :=
      'INSERT INTO tfaora_ctx_hc.tfaora_ctx_hc_tab VALUES (2,'
   || '''The quick brown fox jumps over the lazy dog'')';
 EXECUTE IMMEDIATE(v_stmt);
 EXECUTE IMMEDIATE('COMMIT');
 v_stmt :=
      'CREATE INDEX tfaora_ctx_hc.tfaora_ctx_hc_idx '
   || 'ON tfaora_ctx_hc.tfaora_ctx_hc_tab(text) INDEXTYPE IS CTXSYS.CONTEXT';
 DBMS_OUTPUT.PUT_LINE('....Creating text index TFAORA_CTX_HC_IDX');
 EXECUTE IMMEDIATE(v_stmt);
 DBMS_OUTPUT.PUT_LINE ('....Text index TFAORA_CTX_HC_IDX created successfully');
 DBMS_OUTPUT.PUT_LINE ('  ');
 IF v_ctxuser < 1 THEN
  DBMS_OUTPUT.PUT_LINE ('..Dropping user TFAORA_CTX_HC');
  EXECUTE IMMEDIATE ('DROP USER tfaora_ctx_hc CASCADE');
  DBMS_OUTPUT.PUT_LINE ('....User TFAORA_CTX_HC dropped successfully');
 ELSE
  DBMS_OUTPUT.PUT_LINE ('..Dropping TFAORA_CTX_HC objects created by health check');
  EXECUTE IMMEDIATE ('DROP TABLE tfaora_ctx_hc.tfaora_ctx_hc_tab PURGE');
  DBMS_OUTPUT.PUT_LINE ('....Text health check objects dropped successfully');
 END IF;
 DBMS_OUTPUT.PUT_LINE ('  ');
 DBMS_OUTPUT.PUT_LINE ('Text Index Creation Test complete');
 DBMS_OUTPUT.PUT_LINE ('.');

 display_banner;

 EXCEPTION
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
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
PROMPT
Rem===========================================================================================================================================
set verify on echo on
@?/rdbms/admin/sqlsessend.sql
exit