Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_tablespace.sql /main/1 2021/06/01 13:25:12 bvongray Exp $
Rem
Rem srdc_tablespace.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_tablespace.sql - script to collect Space Usage and storage related diagnostic data 
Rem
Rem    NOTES
Rem      * This script collects the data related to the Tablespaces, datafiles ,storage structures in the database
Rem		   and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_tablespace.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem    slabraha   01/10/2020 - created script
Rem
Rem
Rem
@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_Tablespace'
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
prompt                            ++ Configuration ++
prompt ============================================================================================
prompt
set echo on
select * from v$datafile
/
select * from dba_data_files
/
select * from dba_tablespaces
/
select * from v$tablespace
/
select * from database_properties
/
select * from v$recover_file
/
select tablespace_name, max(blocks) "Continuos free blocks", max(bytes)/1024/1024 "Continuous space in MB" from dba_free_space group by tablespace_name
/

SELECT /*+ first_rows */ d.tablespace_name "TS NAME", NVL(a.bytes / 1024 / 1024, 0) "size MB", NVL(a.bytes - NVL(f.bytes, 0), 0)/1024/1024 "Used MB", NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0) "Used %",
a.autoext "Autoextend", NVL(f.bytes, 0) / 1024 / 1024 "Free MB", d.status "STAT", a.count "# of datafiles", d.contents "TS type", d.extent_management "EXT MGMT", d.segment_space_management "Seg Space MGMT" FROM sys.dba_tablespaces d, (select tablespace_name,
sum(bytes) bytes, count(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)), 0, 'NO', 'YES') autoext from dba_data_files group by tablespace_name) a,
(select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = f.tablespace_name(+)
AND NOT d.contents = 'UNDO' AND NOT (d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY') AND d.tablespace_name like '%%' UNION ALL SELECT d.tablespace_name, NVL(a.bytes / 1024 / 1024, 0),
NVL(t.bytes, 0)/1024/1024, NVL(t.bytes / a.bytes * 100, 0), a.autoext, (NVL(a.bytes ,0)/1024/1024 - NVL(t.bytes, 0)/1024/1024), d.status, a.count, d.contents, d.extent_management,
d.segment_space_management FROM sys.dba_tablespaces d, (select tablespace_name, sum(bytes) bytes, count(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)), 0, 'NO', 'YES') autoext
from dba_temp_files group by tablespace_name) a, (select ss.tablespace_name , sum((ss.used_blocks*ts.blocksize)) bytes from gv$sort_segment ss, sys.ts$ ts where ss.tablespace_name = ts.name
group by ss.tablespace_name) t WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = t.tablespace_name(+) AND d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY'
and d.tablespace_name like '%%' UNION ALL SELECT d.tablespace_name, NVL(a.bytes / 1024 / 1024, 0), NVL(u.bytes, 0) / 1024 / 1024, NVL(u.bytes / a.bytes * 100, 0), a.autoext, NVL(a.bytes - NVL(u.bytes, 0), 0)/1024/1024,
d.status, a.count, d.contents, d.extent_management, d.segment_space_management FROM sys.dba_tablespaces d, (SELECT tablespace_name, SUM(bytes) bytes, COUNT(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)),
0, 'NO', 'YES') autoext FROM dba_data_files GROUP BY tablespace_name) a, (SELECT tablespace_name, SUM(bytes) bytes FROM (SELECT tablespace_name,sum (bytes) bytes,status from dba_undo_extents WHERE status ='ACTIVE'
group by tablespace_name,status UNION ALL SELECT tablespace_name,sum(bytes) bytes,status from dba_undo_extents WHERE status ='UNEXPIRED' group by tablespace_name,status ) group by tablespace_name ) u
WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = u.tablespace_name(+) AND d.contents = 'UNDO' AND d.tablespace_name LIKE '%%' ORDER BY 1
/
set echo off
prompt
prompt ============================================================================================
prompt                             ++ Tablespace Alerts And Usage Metrics ++
prompt ============================================================================================
prompt
set echo on
select 'Tbs_Alerts' "CHECK_NAME",object_name, reason from dba_outstanding_alerts
/
select 'Tbs_alert_history' "CHECK_NAME",CREATION_TIME,METRIC_VALUE, reason, suggested_action from DBA_ALERT_HISTORY
/
select * from dba_tablespace_usage_metrics
/
set echo off
prompt
prompt ============================================================================================
prompt                             ++ Free space ++
prompt ============================================================================================
prompt
set echo on
SELECT df.tablespace_name "Tablespace",
  totalusedspace "Used MB",
  (df.totalspace - tu.totalusedspace) "Free MB",
  df.totalspace "Total MB",
  ROUND(100 * ( (df.totalspace - tu.totalusedspace)/ df.totalspace)) "% Free"
FROM
  (SELECT tablespace_name,
    ROUND(SUM(bytes) / 1048576) TotalSpace
  FROM dba_data_files
  GROUP BY tablespace_name
  ) df,
  (SELECT ROUND(SUM(bytes)/(1024*1024)) totalusedspace,
    tablespace_name
  FROM dba_segments
  GROUP BY tablespace_name
  ) tu
WHERE df.tablespace_name = tu.tablespace_name
/
set echo off
prompt
prompt ============================================================================================
prompt                             ++ Tablespace Fragmentation ++
prompt ============================================================================================
prompt
set echo on
column "CONTIGUOUS BYTES"       format 999,999,999,999,999,999   
column "COUNT"                  format 999   
column "TOTAL BYTES"            format 999,999,999,999,999,999 
WITH a
AS
(
SELECT tablespace_name,file_id,block_id,bytes,blocks,LEVEL,CONNECT_BY_ROOT block_id as root,
COUNT(*) OVER(PARTITION BY tablespace_name, file_id, CONNECT_BY_ROOT block_id) as EXTENTS,
SUM(bytes) OVER(PARTITION BY tablespace_name, file_id, CONNECT_BY_ROOT block_id) as CONTIGUOUS_BYTES
FROM dba_free_space
CONNECT BY PRIOR (block_id+blocks) = block_id 
AND PRIOR tablespace_name = tablespace_name
AND PRIOR file_id = file_id
)
SELECT TABLESPACE_NAME  "TABLESPACE NAME", 
CONTIGUOUS_BYTES "CONTIGUOUS BYTES"
FROM a
WHERE (tablespace_name, file_id, block_id) IN
(SELECT tablespace_name, file_id, block_id 
FROM a
GROUP BY tablespace_name, file_id, block_id 
HAVING COUNT(*)=1
)
ORDER BY 1,2 DESC
/

WITH a
AS
(
SELECT tablespace_name,file_id,block_id,bytes,blocks,LEVEL,CONNECT_BY_ROOT block_id as root,
COUNT(*) OVER(PARTITION BY tablespace_name, file_id, CONNECT_BY_ROOT block_id) as EXTENTS,
SUM(bytes) OVER(PARTITION BY tablespace_name, file_id, CONNECT_BY_ROOT block_id) as CONTIGUOUS_BYTES
FROM dba_free_space
CONNECT BY PRIOR (block_id+blocks) = block_id 
AND PRIOR tablespace_name = tablespace_name
AND PRIOR file_id = file_id
)
SELECT tablespace_name,count(*) "# OF EXTENTS",sum(CONTIGUOUS_BYTES) "TOTAL BYTES",max(CONTIGUOUS_BYTES) "BIGGEST CONTIGUOUS BYTES",min(CONTIGUOUS_BYTES) "SMALLEST CONTIGUOUS BYTES"
FROM a
WHERE (tablespace_name, file_id, block_id) IN
(SELECT tablespace_name, file_id, block_id 
FROM a
GROUP BY tablespace_name, file_id, block_id 
HAVING COUNT(*)=1
)
GROUP BY tablespace_name
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Segment Advisor Autotask ++
prompt ============================================================================================
prompt
set echo on
select 'SA_Autotask' "CHECK_NAME",log_date, status, additional_info from dba_scheduler_job_run_details 
where job_name like '%ORA$AT_SA_SPC%' and LOG_DATE > (sysdate -7) order by log_date desc
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Segment Advisor Recommendations ++
prompt ============================================================================================
prompt
set echo on
SELECT tablespace_name, segment_owner, segment_name, segment_type,
allocated_space, used_space, reclaimable_space
FROM (
  SELECT *
  FROM TABLE(dbms_space.asa_recommendations('TRUE','TRUE','TRUE')))
  /

SELECT segment_owner, segment_name, recommendations
FROM (
  SELECT *
  FROM TABLE(dbms_space.asa_recommendations('TRUE','TRUE','TRUE')))
  /
set echo off
prompt
prompt ============================================================================================
prompt                         ++ Temporary Tablespace Details ++
prompt ============================================================================================
prompt
set echo on
SELECT substr(vs.username,1,20) "db user", substr(vs.osuser,1,20) "os user", vs.status , substr(vsn.name,1,20) "Type of Sort", vss.value FROM v$session vs, v$sesstat vss, v$statname vsn
WHERE (vss.statistic#=vsn.statistic#) AND (vs.sid = vss.sid) AND (vsn.name like '%sort%') ORDER by 1
/
select OWNER, SEGMENT_NAME, SEGMENT_TYPE, TABLESPACE_NAME from DBA_SEGMENTS where SEGMENT_TYPE = 'TEMPORARY'
/
select TABLESPACE_NAME, SEGMENT_FILE Seg_file, SEGMENT_BLOCK Seg_blk, TOTAL_BLOCKS Total, USED_BLOCKS Used, FREE_BLOCKS Free, current_users from v$sort_segment
/
SELECT TABLESPACE_NAME,TABLESPACE_SIZE/1024/1024 "TABLESPACE_SIZE (MB)",ALLOCATED_SPACE/1024/1024 "ALLOCATED_SPACE (MB)",FREE_SPACE/1024/1024 "FREE_SPACE (MB)" from DBA_TEMP_FREE_SPACE
/
select username, tablespace, segtype, count(*), sum(blocks), SQL_ID from v$tempseg_usage group by username, tablespace, segtype,SQL_ID
/
SELECT a.username, a.sid, a.serial#, a.osuser, b.tablespace, b.blocks, (b.blocks*8192)/1024/1024 "Size MB", c.sql_text FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr AND c.address= a.sql_address AND c.hash_value = a.sql_hash_value ORDER BY b.tablespace, b.blocks
/
--- Historical data for temp usage.. This query covers last 2 days 
select distinct sample_time,sql_id,max(TEMP_SPACE_ALLOCATED)/(1024*1024*1024) gig from DBA_HIST_ACTIVE_SESS_HISTORY where sample_time > sysdate-2 and 
TEMP_SPACE_ALLOCATED > (2*1024*1024*1024)group by sql_id,sample_time order by sql_id,sample_time
/
-- Configuration checks
select tablespace_name, group_name from DBA_TABLESPACE_GROUPS
/
select username, temporary_tablespace,DEFAULT_TABLESPACE from sys.dba_users order by 1
/
select * from sys.dba_temp_files
/
select NAME, CREATION_TIME, BYTES/1024/1024 MB, BLOCKS from v$tempfile
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ RAC Specific Details ++
prompt ============================================================================================
prompt
set echo on
select inst_id, tablespace_name, segment_file, total_blocks, used_blocks, free_blocks, max_used_blocks, max_sort_blocks from gv$sort_segment
/
select inst_id, tablespace_name, blocks_cached, blocks_used, extents_cached, extents_used from gv$temp_extent_pool
/
select sum(bytes), owner from gv$temp_extent_map group by owner
/
select inst_id,tablespace_name, blocks_used, blocks_free from gv$temp_space_header
/
select * from gv$tablespace
/
select username, TEMPORARY_TABLESPACE, LOCAL_TEMP_TABLESPACE,DEFAULT_TABLESPACE from dba_users order by username
/
Sho parameter LOCAL_TEMP_TABLESPACE
/
set echo off
prompt
prompt ============================================================================================
prompt                         ++ PDB related checks - 12c specific ++
prompt ============================================================================================
prompt
set echo on
SHOW con_name
/
select NAME,CDB from v$database
/
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS
/
select * from v$pdbs
/
select * from pdb_spfile$
/
SELECT PDB, NETWORK_NAME, CON_ID FROM CDB_SERVICES   WHERE PDB IS NOT NULL AND CON_ID > 2 ORDER BY PDB
/
SELECT DB_NAME, CON_ID, PDB_NAME, OPERATION, OP_TIMESTAMP, CLONED_FROM_PDB_NAME  FROM CDB_PDB_HISTORY  WHERE CON_ID > 2  ORDER BY CON_ID
/
select cause, type, message from PDB_PLUG_IN_VIOLATIONS where status='PENDING' 
/
select con_id, tablespace_name, contents, plugged_in from cdb_tablespaces
/
select con_id, file_name tablespace_name, Bytes, status,autoextensible,maxbytes/(1024*1024*1024),user_bytes/(1024*1024*1024) from cdb_temp_files order by 1
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
