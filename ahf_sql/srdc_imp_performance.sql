Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_imp_performance.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_imp_performance.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_imp_performance.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_imp_performance.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/18/18 - For dbimp SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_imp_performance.sql - Gather Information for IMP Performance Issues

define SRDCNAME = 'IMP_PERFORMANCE'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off verify off TRIMSPOOL on HEADING off
set lines 132 pages 10000
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper ('&&SRDCNAME')||'_'||upper (instance_name)||'_'||to_char (sysdate, 'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on 
REM
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||to_char (systimestamp, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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
Column sid format 99999 heading "SESS|ID"
Column serial# format 9999999 heading "SESS|SER|#"
Column session_id format 99999 heading "SESS|ID"
Column session_serial# format 9999999 heading "SESS|SER|#"
Column event format a40
Column total_waits format 9,999,999,999 heading "TOTAL|TIME|WAITED|MICRO"
Column pga_used_mem format 9,999,999,999 
Column pga_alloc_mem format 9,999,999,999
Column status heading 'Status' format a20
Column timeout heading 'Timeout' format 999999
Column error_number heading 'Error Number' format 999999
Column error_msg heading 'Message' format a44 
Column sql_text heading 'Current SQL statement' format a44 
Column Number_of_objects format 99999999
Column object_type format a35
ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';

SET MARKUP HTML ON PREFORMAT ON

--====================Retrieve sid, serial#, PGA details for the active import process(es)===========================
SET HEADING OFF
SELECT '=================================================================================================================================' FROM dual
UNION ALL
SELECT 'Determine sid, serial#, PGA details for the active import process(es)' FROM dual
UNION ALL
SELECT '=================================================================================================================================' FROM dual;
SET HEADING ON
set feedback on
SELECT sid, s.serial#, p.PGA_USED_MEM, p.PGA_ALLOC_MEM
FROM   v$process p, v$session s
WHERE  p.addr = s.paddr AND 
       UPPER (s.program) LIKE 'IMP%';
set feedback off

--====================Retrieve the number of objects per object_type===========================
SET HEADING OFF
SELECT '=================================================================================================================================' FROM dual
UNION ALL
SELECT 'Determine the number of objects per object_type' FROM dual
UNION ALL
SELECT '=================================================================================================================================' FROM dual;
SET HEADING ON
SELECT count(*) number_of_objects, object_type 
FROM   dba_objects
group  by object_type order by number_of_objects desc;

--====================Retrieve all wait events and time in wait for the running import process(es)====================
SET HEADING OFF
SELECT '=================================================================================================================================' FROM dual
UNION ALL
SELECT 'All wait events and time in wait for the active import process(es)' FROM dual
UNION ALL
SELECT '=================================================================================================================================' FROM dual;
SET HEADING ON
select session_id, session_serial#, Event, sum(time_waited) total_waits
from   v$active_session_history
where  sample_time > sysdate - 1 and 
       UPPER (program) LIKE 'IMP%' and 
       session_id in (select sid 
                      from   v$session where UPPER (program) LIKE 'IMP%') and 
       session_state = 'WAITING' and 
       time_waited > 0
group  by session_id, session_serial#, Event
order  by session_id, session_serial#, total_waits desc;

--====================Import progress - retrieve current sql id and statement====================
SET HEADING OFF
SELECT '=================================================================================================================================' FROM dual
UNION ALL
SELECT 'Import progress - retrieve current sql id and statement' FROM dual
UNION ALL
SELECT '=================================================================================================================================' FROM dual;
SET HEADING ON
select sysdate, a.sid, a.sql_id, a.event, b.sql_text
from   v$session a, v$sql b
where  a.sql_id = b.sql_id and 
       UPPER (a.program) LIKE 'IMP%'
order  by a.sid desc;

SET HEADING OFF MARKUP HTML OFF
SET SERVEROUTPUT ON FORMAT WRAP

declare
  CURSOR c_fix IS select v.KSPPSTVL value 
                  FROM   x$ksppi n, x$ksppsv v 
                  WHERE  n.indx = v.indx and 
                         n.ksppinm = 'fixed_date';  

  v_long_op_flag Number := 0 ;                        
  v_target varchar2(100); 
  v_sid number;
  v_totalwork Number;    
  v_opname varchar2(200);
  v_sofar Number;                        
  v_time_remain Number;  
  stmt varchar2(2000);
  v_fix c_fix%ROWTYPE; 
begin
  stmt := 'select count(*) from v$session_longops where sid in (select sid from v$session where UPPER(program) LIKE '||
          '''IMP%'')'||' and totalwork <> sofar';
  DBMS_OUTPUT.PUT_LINE ('<pre>');
  dbms_output.put_line ('=================================================================================================================================');
  dbms_output.put_line ('Check v$session_longops - Import pending work');
  dbms_output.put_line ('=================================================================================================================================');
  dbms_output.put_line (chr (10));
  execute immediate stmt into v_long_op_flag;
  if (v_long_op_flag > 0 ) then      
    dbms_output.put_line ('The number of long running import processes is:   '||v_long_op_flag);
    dbms_output.put_line (chr (10));                        
    for longop in (select sid, target,opname, sum (totalwork) totwork, sum (sofar) sofar, sum (totalwork-sofar) blk_remain, Round (sum (time_remaining / 60), 2) time_remain
                   from   v$session_longops 
                   where  sid in (select sid 
                                  from   v$session 
                                  where  UPPER (program) LIKE 'IMP%') and 
                          opname NOT LIKE '%aggregate%' and 
                          totalwork <> sofar 
                   group  by sid, target, opname)                        
    loop  
      dbms_output.put_line (Rpad ('Import SID', 40, ' ')||chr (9)||':'||chr (9)||longop.sid); 
      dbms_output.put_line (Rpad ('Object being read', 40, ' ')||chr (9)||':'||chr (9)||longop.target);      
      dbms_output.put_line (Rpad ('Operation being executed', 40, ' ')||chr (9)||':'||chr (9)||longop.opname); 
      dbms_output.put_line (Rpad ('Total blocks to be read', 40, ' ')||chr (9)||':'||chr (9)||longop.totwork);                        
      dbms_output.put_line (Rpad ('Total blocks already read', 40, ' ')||chr (9)||':'||chr (9)||longop.sofar);                        
      dbms_output.put_line (Rpad ('Remaining blocks to be read', 40, ' ')||chr (9)||':'||chr (9)||longop.blk_remain);                        
      dbms_output.put_line (Rpad ('Estimated time remaining for the process', 40, ' ')||chr (9)||':'||chr (9)||longop.time_remain||' Minutes'); 
      dbms_output.put_line (chr (10));
    end Loop;
  else
    DBMS_OUTPUT.PUT_LINE ('No import session is found in v$session_longops');
    dbms_output.put_line (chr (10)); 
  end If;
  dbms_output.put_line ('=================================================================================================================================');
  DBMS_OUTPUT.PUT_LINE ('Is the fixed_date parameter set?'); 
  dbms_output.put_line ('=================================================================================================================================');
  open c_fix; 
  fetch c_fix into v_fix;
  if nvl (to_char (v_fix.value), '1') = to_char ('1') then
    DBMS_OUTPUT.PUT_LINE ('No value is found for fixed_date parameter');
  else
    DBMS_OUTPUT.PUT_LINE ('The fixed_date parameter is set for this database and the value is: '||v_fix.value);
  end if;
  dbms_output.put_line ('=================================================================================================================================');
  DBMS_OUTPUT.PUT_LINE ('</pre>');
end;
/

spool off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm

exit

@?/rdbms/admin/sqlsessend.sql
 
