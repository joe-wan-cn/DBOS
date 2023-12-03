Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_corruption_1578_info.sql /main/5 2022/10/11 15:47:03 smuthuku Exp $
Rem
Rem srdc_corruption_1578_info.sql
Rem
Rem Copyright (c) 2020, 2022, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      srdc_corruption_1578_info.sql
Rem
Rem    DESCRIPTION
Rem      Called by ora1578 SRDC collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_corruption_1578_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    09/22/22 - bug 34534512
Rem    bvongray    08/05/21 - bug 32988384
Rem    bvongray    04/02/21 - script updates
Rem    bvongray    03/18/21 - script update
Rem    xiaodowu    05/14/20 - Called by ora1578 SRDC collection
Rem    xiaodowu    05/14/20 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_corruption_1578.sql:  Collection information for corruption error ORA-01578 within Oracle11g.
define SRDCNAME='CORRUPTION_1578_INFO'
SET MARKUP HTML ON spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(value)||'_'||
      to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME
from v$parameter where lower(name)='instance_name';

REM
spool &&SRDCSPOOLNAME..htm
set heading off;
select '+----------------------------------------------------+' from dual
union all
select '| Script version:  '||'24-Aug-2022' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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

Set heading on;
set echo off
set feedback on;
set numwidth 30;
set pagesize 50000;
alter session set nls_date_format = 'DD-MON-RRRR HH24:MI:SS';
set null NULL;
select systimestamp from dual;

prompt *****************************************************************
prompt ++ DATABASE DETAILS ++
prompt *****************************************************************

prompt select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;
select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;

prompt Select name, dbid, database_role, force_logging, log_mode, flashback_on, db_unique_name,
prompt controlfile_type, resetlogs_change#, resetlogs_time, standby_became_primary_scn from v$database;

Select name, dbid, database_role, force_logging, log_mode, flashback_on, db_unique_name,
controlfile_type, resetlogs_change#, resetlogs_time, standby_became_primary_scn from v$database;

prompt SQL> select dbid, name, cdb container from v$database;
select dbid, name, cdb container from v$database;

prompt select d.dest_id,d.dest_name,s.type,d.status,recovery_mode,d.error,d.destination
prompt from v$archive_dest d, v$archive_dest_status s
prompt where d.dest_id=s.dest_id
prompt and d.dest_id <>32 and d.destination is not null;

select d.dest_id,d.dest_name,s.type,d.status,recovery_mode,d.error,d.destination
from v$archive_dest d, v$archive_dest_status s
where d.dest_id=s.dest_id
and d.dest_id <>32 and d.destination is not null;

prompt show pdbs
show pdbs

prompt select con_id,name,open_mode,restricted from v$containers;
select con_id,name,open_mode,restricted from v$containers;

prompt *****************************************************************
prompt ++ CORRUPTION DETAILS ++
prompt ++ NOTE:  If PDB is not open, details on PDB corruption will NOT be included.
prompt *****************************************************************

prompt SQL> select file#,block#,blocks,corruption_change#,corruption_type from v$database_block_corruption order by file#, corruption_type;
select file#,block#,blocks,corruption_change#,corruption_type from v$database_block_corruption order by file#, corruption_type;

prompt SQL> Select file#, corruption_type, sum(blocks), t.name from v$database_block_corruption c, v$containers t where t.con_id=c.con_id group by file#, corruption_type, t.name;

Select file#, corruption_type, sum(blocks), t.name from 
v$database_block_corruption c, v$containers t
where t.con_id=c.con_id
group by file#, corruption_type, t.name;

prompt SQL> Select file#, sum(blocks), t.name from v$database_block_corruption c, v$containers t where t.con_id=c.con_id group by file#, t.name; 
Select file#, sum(blocks), t.name from v$database_block_corruption c, v$containers t where t.con_id=c.con_id group by file#, t.name; 

prompt SQL>  select file#,block#,blocks,corruption_change#,corruption_type from v$database_block_corruption where corruption_type in ('LOGICAL','NOLOGGING');
select file#,block#,blocks,corruption_change#,corruption_type from v$database_block_corruption where corruption_type in ('LOGICAL','NOLOGGING');

prompt *****************************************************************
prompt ++ CORRUPTED DATAFILE DETAILS ++
prompt *****************************************************************

prompt SELECT FILE#, RFILE#, d.NAME, block_size, c.name FROM V$DATAFILE d, v$container c
prompt where d.con_id=c.con_id and d.file# in (select distinct(FILE#) from v$database_block_corruption);

SELECT FILE#, RFILE#, d.NAME, d.block_size, c.name FROM V$DATAFILE d, v$containers c
where d.con_id=c.con_id and d.file# in (select distinct(FILE#) from v$database_block_corruption);

prompt SELECT FILE#, RFILE#, d.NAME, d.block_size, c.name FROM V$DATAFILE d, v$containers c
prompt where d.con_id=c.con_id and d.file# in (select distinct(FILE#) from v$nonlogged_block);

SELECT FILE#, RFILE#, d.NAME, d.block_size, c.name FROM V$DATAFILE d, v$containers c
where d.con_id=c.con_id and d.file# in (select distinct(FILE#) from v$nonlogged_block);

prompt *****************************************************************
prompt ++ OBJECT DETAILS ++
prompt *****************************************************************

prompt SELECT e.owner, e.segment_type, e.segment_name, e.partition_name, c.file#
prompt      , greatest(e.block_id, c.block#) corr_start_block#
prompt      , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) corr_end_block#
prompt      , least(e.block_id+e.blocks-1, c.block#+c.blocks-1)
prompt        - greatest(e.block_id, c.block#) + 1 blocks_corrupted
prompt      , corruption_type description,t.name
prompt   FROM cdb_extents e, v$database_block_corruption c,v$containers t
prompt  WHERE e.file_id = c.file#
prompt    AND e.block_id <= c.block# + c.blocks - 1
prompt    AND e.block_id + e.blocks - 1 >= c.block#
prompt    and e.con_id=t.con_id
prompt UNION
prompt SELECT s.owner, s.segment_type, s.segment_name, s.partition_name, c.file#
prompt      , header_block corr_start_block#
prompt      , header_block corr_end_block#
prompt      , 1 blocks_corrupted
prompt      , corruption_type||' Segment Header' description,t.name
prompt   FROM cdb_segments s, v$database_block_corruption c,v$containers t
prompt  WHERE s.header_file = c.file#
prompt    AND s.header_block between c.block# and c.block# + c.blocks - 1
prompt    and s.con_id=t.con_id
prompt UNION
prompt SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
prompt      , greatest(f.block_id, c.block#) corr_start_block#
prompt      , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
prompt      , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
prompt        - greatest(f.block_id, c.block#) + 1 blocks_corrupted
prompt      , 'Free Block' description,t.name
prompt   FROM cdb_free_space f, v$database_block_corruption c,v$containers t
prompt  WHERE f.file_id = c.file#
prompt    AND f.block_id <= c.block# + c.blocks - 1
prompt    AND f.block_id + f.blocks - 1 >= c.block#
prompt    and f.con_id=t.con_id
prompt order by file#, corr_start_block#;

SELECT e.owner, e.segment_type, e.segment_name, e.partition_name, c.file#
     , greatest(e.block_id, c.block#) corr_start_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1)
       - greatest(e.block_id, c.block#) + 1 blocks_corrupted
     , corruption_type description,t.name
  FROM cdb_extents e, v$database_block_corruption c,v$containers t
 WHERE e.file_id = c.file#
   AND e.block_id <= c.block# + c.blocks - 1
   AND e.block_id + e.blocks - 1 >= c.block#
   and e.con_id=t.con_id
UNION
SELECT s.owner, s.segment_type, s.segment_name, s.partition_name, c.file#
     , header_block corr_start_block#
     , header_block corr_end_block#
     , 1 blocks_corrupted
     , corruption_type||' Segment Header' description,t.name
  FROM cdb_segments s, v$database_block_corruption c,v$containers t
 WHERE s.header_file = c.file#
   AND s.header_block between c.block# and c.block# + c.blocks - 1
   and s.con_id=t.con_id
UNION
SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
     , greatest(f.block_id, c.block#) corr_start_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
       - greatest(f.block_id, c.block#) + 1 blocks_corrupted
     , 'Free Block' description,t.name
  FROM cdb_free_space f, v$database_block_corruption c,v$containers t
 WHERE f.file_id = c.file#
   AND f.block_id <= c.block# + c.blocks - 1
   AND f.block_id + f.blocks - 1 >= c.block#
   and f.con_id=t.con_id
order by file#, corr_start_block#;

prompt *****************************************************************
prompt ++ NOLOGGING DETAILS ++
prompt *****************************************************************

prompt SQL> select file#, count(*) from v$nonlogged_block group by file#;

select file#, count(*) from v$nonlogged_block group by file#;

prompt select file#, unrecoverable_change#, unrecoverable_time, first_nonlogged_scn, first_nonlogged_time
prompt from v$datafile
prompt where unrecoverable_time is not null OR
prompt first_nonlogged_time is not null;

select file#, unrecoverable_change#, unrecoverable_time, first_nonlogged_scn, first_nonlogged_time
from v$datafile
where unrecoverable_time is not null OR
first_nonlogged_time is not null;

prompt SQL>  select file#, block#, blocks, nonlogged_start_change# from V$nonlogged_block;

select file#, block#, blocks, nonlogged_start_change# from V$nonlogged_block;

prompt SELECT n.owner, n.segment_type, n.segment_name, n.partition_name, c.file#
prompt      , greatest(n.block_id, c.block#) corr_start_block#
prompt      , least(n.block_id+n.blocks-1, c.block#+c.blocks-1) corr_end_block#
prompt      , least(n.block_id+n.blocks-1, c.block#+c.blocks-1)
prompt        - greatest(n.block_id, c.block#) + 1 blocks_corrupted
prompt      , null description,t.name
prompt   FROM cdb_extents n, v$nonlogged_block c,v$containers t
prompt  WHERE n.file_id = c.file#
prompt    AND n.block_id <= c.block# + c.blocks - 1
prompt    AND n.block_id + n.blocks - 1 >= c.block#
prompt    and n.con_id=t.con_id
prompt UNION
prompt SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
prompt      , greatest(f.block_id, c.block#) corr_start_block#
prompt      , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
prompt      , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
prompt        - greatest(f.block_id, c.block#) + 1 blocks_corrupted
prompt      , 'Free Block' description,t.name
prompt   FROM cdb_free_space f, v$nonlogged_block c,v$containers t
prompt  WHERE f.file_id = c.file#
prompt    AND f.block_id <= c.block# + c.blocks - 1
prompt    AND f.block_id + f.blocks - 1 >= c.block#
prompt    and t.con_id=f.con_id
prompt order by file#, corr_start_block#;

SELECT n.owner, n.segment_type, n.segment_name, n.partition_name, c.file#
     , greatest(n.block_id, c.block#) corr_start_block#
     , least(n.block_id+n.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(n.block_id+n.blocks-1, c.block#+c.blocks-1)
       - greatest(n.block_id, c.block#) + 1 blocks_corrupted
     , null description,t.name
  FROM cdb_extents n, v$nonlogged_block c,v$containers t
 WHERE n.file_id = c.file#
   AND n.block_id <= c.block# + c.blocks - 1
   AND n.block_id + n.blocks - 1 >= c.block#
   and n.con_id=t.con_id
UNION
SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
     , greatest(f.block_id, c.block#) corr_start_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
       - greatest(f.block_id, c.block#) + 1 blocks_corrupted
     , 'Free Block' description,t.name
  FROM cdb_free_space f, v$nonlogged_block c,v$containers t
 WHERE f.file_id = c.file#
   AND f.block_id <= c.block# + c.blocks - 1
   AND f.block_id + f.blocks - 1 >= c.block#
   and t.con_id=f.con_id
order by file#, corr_start_block#;

prompt
prompt *****************************************************************
prompt ++ RMAN BACKUP INFORMATION ++
prompt *****************************************************************
prompt

prompt select count(*), trunc(completion_time), decode(backup_type, 'D', 'DATABASE', 'L', 'ARCHIVELOG')
prompt from v$backup_set where trunc(completion_time) > sysdate-14
prompt group by trunc(completion_time), backup_type;

select count(*), trunc(completion_time), decode(backup_type, 'D', 'DATABASE', 'L', 'ARCHIVELOG')
from v$backup_set where trunc(completion_time) > sysdate-14
group by trunc(completion_time), backup_type;


prompt SQL> SELECT DISTINCT p.tag, r.object_type, r.session_recid, r.start_time,
prompt 2   r.end_time,
prompt 3   round(((r.end_time - r.start_time)* 24),2) "ET(Hr)",
prompt 4   round((r.output_bytes/1048576/1024),2) "SIZE (GB)",
prompt 5   r.status,
prompt 6   r.output_device_type,
prompt 7   round((input_bytes_per_sec/1048576),2) "read (MB/sec)",
prompt 8   round((output_bytes_per_sec / 1048576),2) "output (MB/sec)"
prompt 9  FROM
prompt 10  v$backup_piece p,
prompt 11  v$rman_status r,
prompt 12  v$rman_backup_job_details d
prompt 13 WHERE
prompt 14  p.rman_status_recid = r.recid
prompt 15  AND p.rman_status_stamp = r.stamp
prompt 16  AND r.status LIKE '%COMPLETED%'
prompt 17  AND r.operation LIKE '%BACKUP%'
prompt 18  AND r.object_type LIKE 'DB%'
prompt 19  AND d.session_recid = r.session_recid
prompt 20  AND trunc(p.completion_time) > SYSDATE - 10;

SELECT DISTINCT
     p.tag,
     r.object_type,
     r.session_recid,
     r.start_time,
     r.end_time,
     round(((r.end_time - r.start_time)* 24),2) "ET(Hr)",
     round((r.output_bytes/1048576/1024),2) "SIZE (GB)",
     r.status,
     r.output_device_type,
     round((input_bytes_per_sec/1048576),2) "read (MB/sec)",
     round((output_bytes_per_sec / 1048576),2) "output (MB/sec)"
 FROM
     v$backup_piece p,
     v$rman_status r,
     v$rman_backup_job_details d
 WHERE
     p.rman_status_recid = r.recid
     AND p.rman_status_stamp = r.stamp
     AND r.status LIKE '%COMPLETED%'
     AND r.operation LIKE '%BACKUP%'
     AND r.object_type LIKE 'DB%'
     AND d.session_recid = r.session_recid
     AND trunc(p.completion_time) > SYSDATE - 10;

set markup html off spool off
@?/rdbms/admin/sqlsessend.sql
exit
