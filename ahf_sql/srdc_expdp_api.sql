Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_expdp_api.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_expdp_api.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_expdp_api.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_expdp_api.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/18/18 - For dbexpdpapi SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_expdp_api.sql - Gather useful information to debug the EXPDP API errors
define SRDCNAME='EXPDP_API'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off verify off TRIMSPOOL on HEADING off
set lines 132 pages 10000
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on 
REM
spool &&SRDCSPOOLNAME..htm
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

set concat "#"
SET PAGESIZE 9999
SET LINESIZE 256
SET TRIMOUT ON
SET TRIMSPOOL ON
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';

SET HEADING OFF MARKUP HTML OFF
SET SERVEROUTPUT ON FORMAT WRAP

declare
  cursor c_ver is SELECT version 
                  FROM v$instance;

  CURSOR c_feat IS SELECT comp_name, status, version 
                   FROM   dba_registry
                   ORDER  BY comp_id;

  CURSOR c_count is select count(*) 
                    FROM   dba_objects 
                    WHERE  status != 'VALID';

  CURSOR c_invalid IS SELECT owner, object_type, count(*) nr_of_invalids 
                      FROM   dba_objects 
                      WHERE  status != 'VALID' 
                      GROUP  BY owner, object_type 
                      ORDER  BY owner;

  v_ver c_ver%ROWTYPE;
  v_feat c_feat%ROWTYPE;
  v_count NUMBER;
  stmt varchar2(200);
begin
  open c_ver; 
  fetch c_ver into v_ver; 
  DBMS_OUTPUT.PUT_LINE ('<pre>');
  dbms_output.put_line ('============================================Check version for CATALOG, CATPROC, JAVAVM and XDB===================================');
  if v_ver.version != dbms_registry.version ('CATALOG') then
    DBMS_OUTPUT.PUT_LINE ('Database is at version '||v_ver.version||', CATALOG is at version '||dbms_registry.version ('CATALOG'));
  else 
    if v_ver.version != dbms_registry.version ('CATPROC') then
      DBMS_OUTPUT.PUT_LINE ('Database is at version '||v_ver.version||', CATPROC is at version '||dbms_registry.version ('CATPROC'));
    else
      if v_ver.version != dbms_registry.version ('JAVAVM') then
        DBMS_OUTPUT.PUT_LINE ('Database is at version '||v_ver.version||', JAVAVM is at version '||dbms_registry.version ('JAVAVM'));
      else
        if v_ver.version != dbms_registry.version ('XDB') then
          DBMS_OUTPUT.PUT_LINE('Database is at version '||v_ver.version||', XDB is at version '||dbms_registry.version ('XDB')); 
        else
          DBMS_OUTPUT.PUT_LINE ('Database version and Oracle Compenents: CATALOG, CATPROC, JAVAVM and XDB are at the same version: '||v_ver.version);
        end if;
      end if;
    end if;
  end if;
  dbms_output.put_line ('================================================================================================================================='); 
  dbms_output.put_line (chr (10));

  DBMS_OUTPUT.PUT_LINE ('=================================================Database Registry Status========================================================'); 
  FOR v_feat IN c_feat LOOP 
    DBMS_OUTPUT.PUT_LINE ('--> '||rpad (v_feat.comp_name, 35)||' '||rpad (v_feat.version, 10)||'   '||rpad(v_feat.status, 10)); 
  END LOOP; 
  dbms_output.put_line ('================================================================================================================================='); 
  dbms_output.put_line (chr (10));

  DBMS_OUTPUT.PUT_LINE ('=================================================Number of Invalid Objects per schema============================================'); 
  open c_count;
  fetch c_count into v_count;
  if v_count > 0 then
    BEGIN
      DBMS_OUTPUT.PUT_LINE (rpad ('ONWER', 35)||' '||rpad ('OBJECT_TYPE', 30)||'   '||rpad ('NUMBER_OF_INVALIDS', 25));
      DBMS_OUTPUT.PUT_LINE (rpad ('--------', 35)||' '||rpad ('--------------', 30)||'   '||rpad ('---------------------', 25));
      FOR v_invalid IN c_invalid LOOP 
        DBMS_OUTPUT.PUT_LINE (rpad (v_invalid.owner, 35)||' '||rpad (v_invalid.object_type, 30)||'   '||rpad (v_invalid.nr_of_invalids, 25)); 
      END LOOP;
    end;   
  else
    DBMS_OUTPUT.PUT_LINE ('There are no invalid objects in this database'); 
    dbms_output.put_line (chr (10));
  END IF; 
  dbms_output.put_line ('=================================================================================================================================');
end;
/

COL parameter format a30
COL value format a64

begin
  dbms_output.put_line(chr(10));
  DBMS_OUTPUT.PUT_LINE ('=====================================================NLS database parameters====================================================='); 
end;
/

select * from nls_database_parameters;

begin
  dbms_output.put_line(chr(10));
  DBMS_OUTPUT.PUT_LINE ('======================================================NLS instance parameters====================================================='); 
end;
/

select * from nls_instance_parameters;

begin
  dbms_output.put_line(chr(10));
  DBMS_OUTPUT.PUT_LINE ('======================================================NLS session parameters====================================================='); 
end;
/

select * from nls_session_parameters;

begin
  dbms_output.put_line ('=================================================================================================================================');
  DBMS_OUTPUT.PUT_LINE ('</pre>');
end;
/

spool off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm

exit;

@?/rdbms/admin/sqlsessend.sql
