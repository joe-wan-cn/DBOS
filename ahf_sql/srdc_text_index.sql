Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_text_index.sql /main/4 2021/10/12 12:46:51 bvongray Exp $
Rem
Rem srdc_text_index.sql
Rem
Rem Copyright (c) 2018, 2021, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_text_index.sql
Rem
Rem    DESCRIPTION
Rem      Called by dbtextupgrade and dbtextinstall SRDC collections
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_text_index.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/24/21 - ER 33285667
Rem    xiaodowu    02/08/19 - Modified per Rehab Farid
Rem    xiaodowu    11/13/18 - Called by dbtextupgrade SRDC collection
Rem    xiaodowu    11/13/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_text_index.sql - collect Oracle Text Index information
define SRDCNAME='Text_Index_Information'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
        to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
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
REM
set HEADING OFF MARKUP html preformat on
SET LINESIZE 200;
SET SERVEROUTPUT ON FORMAT WRAP;
SET LONG 2000000000
SET LONGCHUNKSIZE 10000
SET PAGESIZE 10000
SET TRIMOUT ON TRIMSPOOL ON

var datastore_owner VARCHAR2(200);
var datastore_proc  VARCHAR2(200);

col obj_ddl format a300

DEFINE OWN = &1
DEFINE IND = &2


-- First get Datastore Information if necessary

exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', true);
exec Dbms_metadata.set_transform_param(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);

DECLARE
 datastore_test  NUMBER;
 datastore_name  VARCHAR2(200);
 v_pos NUMBER;

BEGIN

 DBMS_OUTPUT.ENABLE(900000);
 SELECT o.ixo_obj_id||o.ixo_acnt INTO datastore_test
 FROM   ctxsys.dr$index_object o, ctxsys.dr$index i, sys.user$ u
 WHERE  u.name = upper('&&OWN')
 AND    u.user# = i.idx_owner#
 AND    i.idx_name = upper('&&IND')
 AND    i.idx_id = o.ixo_idx_id
 AND    o.ixo_cla_id = 1;

IF (datastore_test >= 50 AND datastore_test < 60) THEN

     SELECT trim(ixv_value)
     INTO   datastore_name
     FROM   ctxsys.dr$index_value v, ctxsys.dr$index i, sys.user$ u
     WHERE  u.name = upper('&&OWN')
     AND    u.user# = i.IDX_OWNER#
     AND    i.idx_name = upper('&&IND')
     AND    i.idx_id = v.ixv_idx_id
     AND    v.ixv_oat_id = 10501;

     v_pos           := instr(datastore_name,'.');
     :datastore_owner := NVL(ltrim(rtrim(substr(datastore_name,1,v_pos-1),'"'),'"'),'CTXSYS');
     :datastore_proc  := ltrim(rtrim(substr(datastore_name,v_pos+1),'"'),'"');

END IF;
END;
/

SELECT
 CASE
   WHEN length(:datastore_proc) > 0 THEN
     (
      SELECT dbms_metadata.get_ddl('PROCEDURE',:datastore_proc,:datastore_owner)
      AS obj_ddl
      FROM dual
     )
   END Datastore
FROM dual;

-- Now get Index Information
select ctx_report.create_index_script('&&OWN..&&IND') from dual;

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
