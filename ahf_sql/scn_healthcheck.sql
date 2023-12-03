Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/scn_healthcheck.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem scn_healthcheck.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      scn_healthcheck.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/scn_healthcheck.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    11/27/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
Rem
Rem
Rem scn_healthcheck.sql
Rem
Rem Copyright (c) 2012, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      scnhealthcheck.sql - Scn Health check
Rem
Rem    DESCRIPTION
Rem      Checks scn health of a DB
Rem
Rem    NOTES
Rem      .
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    tbhukya     01/11/12 - Created
Rem    slabraha    11/19/17 - modified for SRDC document
Rem
Rem
define SRDCNAME='DB_SCN_HEALTHCHECK'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name : ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine : ' , host_name from v$instance
union all
select 'Version : ',version from v$instance
union all
select 'DBName : ',name from v$database
union all
select 'Instance : ',instance_name from v$instance
/

set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/

define LOWTHRESHOLD=10
define MIDTHRESHOLD=62
define VERBOSE=TRUE

set veri off;
set feedback off;

set serverout on
DECLARE
 verbose boolean:=&&VERBOSE;
BEGIN
 For C in (
  select 
   version, 
   date_time,
   dbms_flashback.get_system_change_number current_scn,
   indicator
  from
  (
   select
   version,
   to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS') DATE_TIME,
   ((((
    ((to_number(to_char(sysdate,'YYYY'))-1988)*12*31*24*60*60) +
    ((to_number(to_char(sysdate,'MM'))-1)*31*24*60*60) +
    (((to_number(to_char(sysdate,'DD'))-1))*24*60*60) +
    (to_number(to_char(sysdate,'HH24'))*60*60) +
    (to_number(to_char(sysdate,'MI'))*60) +
    (to_number(to_char(sysdate,'SS')))
    ) * (16*1024)) - dbms_flashback.get_system_change_number)
   / (16*1024*60*60*24)
   ) indicator
   from v$instance
  ) 
 ) LOOP
  dbms_output.put_line( '-----------------------------------------------------'
                        || '---------' );
  dbms_output.put_line( 'ScnHealthCheck' );
  dbms_output.put_line( '-----------------------------------------------------'
                        || '---------' );
  dbms_output.put_line( 'Current Date: '||C.date_time );
  dbms_output.put_line( 'Current SCN:  '||C.current_scn );
  if (verbose) then
    dbms_output.put_line( 'SCN Headroom: '||round(C.indicator,2) );
  end if;
  dbms_output.put_line( 'Version:      '||C.version );
  dbms_output.put_line( '-----------------------------------------------------'
                        || '---------' );

  IF C.version > '10.2.0.5.0' and 
     C.version NOT LIKE '9.2%' THEN
    IF C.indicator>&MIDTHRESHOLD THEN 
      dbms_output.put_line('Result: A - SCN Headroom is good');
      dbms_output.put_line('Apply the latest recommended patches');
      dbms_output.put_line('based on your maintenance schedule');
      IF (C.version < '11.2.0.2') THEN
        dbms_output.put_line('AND set _external_scn_rejection_threshold_hours='
                             || '24 after apply.');
      END IF;
    ELSIF C.indicator<=&LOWTHRESHOLD THEN
      dbms_output.put_line('Result: C - SCN Headroom is low');
      dbms_output.put_line('If you have not already done so apply' );
      dbms_output.put_line('the latest recommended patches right now' );
      IF (C.version < '11.2.0.2') THEN
        dbms_output.put_line('set _external_scn_rejection_threshold_hours=24 '
                             || 'after apply');
      END IF;
      dbms_output.put_line('AND contact Oracle support immediately.' );
    ELSE
      dbms_output.put_line('Result: B - SCN Headroom is low');
      dbms_output.put_line('If you have not already done so apply' );
      dbms_output.put_line('the latest recommended patches right now');
      IF (C.version < '11.2.0.2') THEN
        dbms_output.put_line('AND set _external_scn_rejection_threshold_hours='
                             ||'24 after apply.');
      END IF;
    END IF;
  ELSE
    IF C.indicator<=&MIDTHRESHOLD THEN
      dbms_output.put_line('Result: C - SCN Headroom is low');
      dbms_output.put_line('If you have not already done so apply' );
      dbms_output.put_line('the latest recommended patches right now' );
      IF (C.version >= '10.1.0.5.0' and 
          C.version <= '10.2.0.5.0' and 
          C.version NOT LIKE '9.2%') THEN
        dbms_output.put_line(', set _external_scn_rejection_threshold_hours=24'
                             || ' after apply');
      END IF;
      dbms_output.put_line('AND contact Oracle support immediately.' );
    ELSE
      dbms_output.put_line('Result: A - SCN Headroom is good');
      dbms_output.put_line('Apply the latest recommended patches');
      dbms_output.put_line('based on your maintenance schedule ');
      IF (C.version >= '10.1.0.5.0' and
          C.version <= '10.2.0.5.0' and
          C.version NOT LIKE '9.2%') THEN
       dbms_output.put_line('AND set _external_scn_rejection_threshold_hours=24'
                             || ' after apply.');
      END IF;
    END IF;
  END IF;
  dbms_output.put_line(
    'For further information review MOS document id 1393363.1');
  dbms_output.put_line( '-----------------------------------------------------'
                        || '---------' );
 END LOOP;
end;
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
 
