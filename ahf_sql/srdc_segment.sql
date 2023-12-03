Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_segment.sql /main/1 2021/06/01 13:25:12 bvongray Exp $
Rem
Rem srdc_segment.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_segment.sql - script to collect segment space allocation  related diagnostic data 
Rem
Rem    NOTES
Rem      * This script collects the data related to the segment space allocation 
Rem		   and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_segment.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem    slabraha   01/10/2020 - created script
Rem
Rem
@@?/rdbms/admin/sqlsessstart.sql
CLEAR BUFFER
DEFINE Schema_name = &1
DEFINE Obj_name = &2
DEFINE Obj_type = &3
Rem 
Rem
define SRDCNAME='DB_SEGMENT'
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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

REM === -- end of standard header -- ===

alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Database Details ++
prompt ============================================================================================
prompt
set echo on
select * from gv$version
/
select 'Instance_status' "CHECK_NAME",sysdate, instance_name,startup_time,instance_role from gv$instance
/
SELECT 'Database_status' "CHECK_NAME",name,platform_id,open_mode from v$database
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Object details ++
prompt ============================================================================================
prompt
set echo on
select 'Selection' "CHECK_NAME",upper('&&Schema_name')  Owner ,upper('&&Obj_name') Object  from dual
/
SELECT 'Object_Status' "CHECK_NAME",owner,object_name,object_id,object_type,status from dba_objects 
where owner = upper('&&Schema_name') and object_name = upper('&&Obj_name')
/
select * from dba_objects where owner= upper('&&Schema_name') and object_name = upper('&&Obj_name')
/
SELECT 'Segment_Status' "CHECK_NAME",SEGMENT_NAME, SEGMENT_TYPE,OWNER,TABLESPACE_NAME,BYTES, BLOCKS,EXTENTS, INITIAL_EXTENT, MIN_EXTENTS,MAX_EXTENTS, NEXT_EXTENT, PCT_INCREASE FROM DBA_SEGMENTS WHERE SEGMENT_NAME =upper('&&Obj_name')
/
select * from dba_extents where segment_name=upper('&&Obj_name')
/
SELECT 'LOB_Status' "CHECK_NAME",COLUMN_NAME,SEGMENT_NAME, TABLESPACE_NAME,PCTVERSION,RETENTION,IN_ROW,PARTITIONED,SECUREFILE,RETENTION_TYPE,RETENTION_VALUE from dba_lobs where owner = upper('&&Schema_name') and table_name = upper('&&Obj_name')
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Recyclebin Usage ++
prompt ============================================================================================
prompt
set echo on
select * from dba_recyclebin where OWNER=UPPER('&&Schema_name') AND ORIGINAL_NAME=UPPER('&&Obj_name')
/
select owner, count(*) from dba_recyclebin group by owner
/

set echo off
prompt
prompt ============================================================================================
prompt                         ++ Space Usage ++
prompt ============================================================================================
prompt
set echo on
set serveroutput on
declare
   v_unformatted_blocks number;
   v_unformatted_bytes  number;
   v_fs1_blocks         number;
   v_fs1_bytes          number;
   v_fs2_blocks         number;
   v_fs2_bytes          number;
   v_fs3_blocks         number;
   v_fs3_bytes          number;
    v_fs4_blocks         number;
    v_fs4_bytes          number;
    v_full_blocks        number;
    v_full_bytes         number;
  begin
    dbms_space.space_usage(segment_owner=>UPPER('&&Schema_name'), segment_name=>UPPER('&&Obj_name'), segment_type=>UPPER('&&Obj_type'),
      unformatted_blocks=>v_unformatted_blocks, unformatted_bytes=>v_unformatted_bytes,
      fs1_blocks=>v_fs1_blocks, fs1_bytes=>v_fs1_bytes,
      fs2_blocks=>v_fs2_blocks, fs2_bytes=>v_fs2_bytes,
      fs3_blocks=>v_fs3_blocks, fs3_bytes=>v_fs3_bytes,
      fs4_blocks=>v_fs4_blocks, fs4_bytes=>v_fs4_bytes,
      full_blocks=>v_full_blocks, full_bytes=>v_full_bytes
    );
    dbms_output.put_line('Unformatted Blocks = '||v_unformatted_blocks);
    dbms_output.put_line('0 - 25% free blocks= '||v_fs1_blocks);
    dbms_output.put_line('25- 50% free blocks= '||v_fs2_blocks);
    dbms_output.put_line('50- 75% free blocks= '||v_fs3_blocks);
    dbms_output.put_line('75-100% free blocks= '||v_fs4_blocks);
    dbms_output.put_line('Full Blocks        = '||v_full_blocks);
    dbms_output.put_line('0 - 25% Bytes= '||v_fs1_bytes);
    dbms_output.put_line('25- 50% Bytes= '||v_fs2_bytes);
    dbms_output.put_line('50- 75% Bytes= '||v_fs3_bytes);
    dbms_output.put_line('75-100% Bytes= '||v_fs4_bytes);
    dbms_output.put_line('Full Bytes         = '||v_full_bytes);
  end;
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Unused Space++
prompt ============================================================================================
prompt
set echo on
set serveroutput on

DECLARE
 v_total_blocks number;
 v_total_bytes number;
 v_unused_blocks number;
 v_unused_bytes number;
 v_last_used_extent_file_id number;
 v_last_used_extent_block_id number;
 v_last_used_block number;
BEGIN 
    dbms_space.unused_space(segment_owner 		=> UPPER('&&Schema_name'), 
	     segment_name  				=> UPPER('&&Obj_name'), 
		segment_type 				=> UPPER('&&Obj_type'),
		total_blocks  				=> v_total_blocks, 
		total_bytes  				=> v_total_bytes, 
		unused_blocks 				=> v_unused_blocks, 
		unused_bytes  				=> v_unused_bytes,
		last_used_extent_file_id    => v_last_used_extent_file_id, 
		last_used_extent_block_id   => v_last_used_extent_block_id,
		last_used_block				=> v_last_used_block);
dbms_output.put_line('total_bytes = '||v_total_bytes);
dbms_output.put_line('v_total_blocks   :' || v_total_blocks);
dbms_output.put_line('v_unused_blocks	:' || v_unused_blocks);
dbms_output.put_line('unused_bytes = '||v_unused_bytes);
dbms_output.put_line('last_used_blocks = '||v_last_used_block);
END;
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Growth Trend++
prompt ============================================================================================
prompt
set echo on
SELECT *
FROM TABLE(dbms_space.object_growth_trend(object_owner=>UPPER('&&Schema_name'), object_name=>UPPER('&&Obj_name'), object_type=>UPPER('&&Obj_type')))
/
set echo off
prompt
prompt ============================================================================================
prompt            +++++++++++++++++++++End of SRDC Data Collection+++++++++++++ 
prompt ============================================================================================
prompt
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT======================================================================================================================================
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem======================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
exit;
