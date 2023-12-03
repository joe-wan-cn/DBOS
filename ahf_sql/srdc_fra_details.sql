Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_fra_details.sql /main/5 2021/08/12 07:48:58 bvongray Exp $
Rem
Rem srdc_fra_details.sql
Rem
Rem Copyright (c) 2020, 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_fra_details.sql
Rem
Rem    DESCRIPTION
Rem      Called by dbrman SRDC collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_fra_details.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    08/05/21 - bug 32988384
Rem    bvongray    03/18/21 - script update
Rem    bvongray    11/06/20 - SRDC Script Updates
Rem    bvongray    09/25/20 - Script updates
Rem    xiaodowu    05/06/20 - Called by dbrman SRDC
Rem    xiaodowu    05/06/20 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql

set echo off;
REM srdc_fra_details.sql - collect FRA information
define SRDCNAME='FRA_DETAILS'
set markup html on spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
     to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
REM
spool &&SRDCSPOOLNAME..htm
Set heading off;
select '+----------------------------------------------------+' from dual
union all
select '| Script version:  '||'01-May-2021' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||
to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine: '||host_name from v$instance
union all
select '| Version: '||version from v$instance
union all
select '| DBName: '||name from v$database
union all
select '| Instance: '||instance_name from v$instance
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

prompt SQL> select sysdate from dual;
select sysdate from dual;

prompt SQL> select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;
select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;

prompt
prompt *****************************************************************
prompt ++ DATABASE PARAMETERS  ++
prompt *****************************************************************
prompt

prompt SQL> select name,value from v$parameter where lower(name) in ('db_recovery_file_dest','db_recovery_file_dest_size','db_flashback_retention_target');

select name,value from v$parameter where lower(name) in 
('db_recovery_file_dest',
'db_recovery_file_dest_size',
'db_flashback_retention_target');

prompt
prompt *****************************************************************
prompt ++ DATABASE INCARNATION ++
prompt *****************************************************************
prompt

prompt  SQL> select * from gv$database_incarnation;
select * from gv$database_incarnation;

prompt
prompt *****************************************************************
prompt ++ RMAN BACKUP INFORMATION ++
prompt *****************************************************************
prompt

prompt SQL> select count(*), trunc(completion_time), decode(backup_type, 'D', 'DATABASE', 'L', 'ARCHIVELOG') from v$backup_set where trunc(completion_time) > sysdate-14 group by trunc(completion_time), backup_type;

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
prompt 20  AND trunc(p.completion_time) > SYSDATE - 14;

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
     AND trunc(p.completion_time) > SYSDATE - 14;

prompt
prompt *****************************************************************
prompt ++ FLASHBACK DATABASE INFORMATION ++
prompt *****************************************************************
prompt

prompt SQL> select database_role, open_mode, log_mode, flashback_on from v$database;
select database_role, open_mode, log_mode, flashback_on  from v$database;

prompt SQL> select dbid, name, cdb container from v$database;
select dbid, name, cdb container from v$database;

prompt SQL> select * from v$restore_point;
select * from v$restore_point;

prompt SQL> select * from v$flashback_database_log;
select * from v$flashback_database_log;

prompt SQL> select * from v$flashback_database_logfile;
select * from v$flashback_database_logfile;

prompt SQL> select min(first_time) from v$flashback_database_logfile;
select min(first_time) from v$flashback_database_logfile;

prompt SQL> select min(first_change#) from v$flashback_database_logfile;
select min(first_change#) from v$flashback_database_logfile;

prompt SQL> select * from v$flashback_database_stat;
select * from v$flashback_database_stat;

prompt
prompt *****************************************************************
prompt ++ ARCHIVELOG DESTINATIONS ++
prompt *****************************************************************
prompt

prompt SQL> select dest_id, dest_name, status, target from v$archive_dest where status != 'INACTIVE';
select dest_id, dest_name, destination, status, target from v$archive_dest where status != 'INACTIVE';

prompt
prompt ***************************************************************
prompt ++ FAST RECOVERY AREA - FRA ++
prompt ***************************************************************
prompt

prompt
prompt =============================================================== 
prompt ++ Non-default RMAN configuration' from dual ++
prompt =============================================================== 
prompt

prompt SQL> select * from v$rman_configuration;
select * from v$rman_configuration;

prompt
prompt ============================================================== 
prompt ++ FRA Usage by file ++
prompt ============================================================== 
prompt

prompt SQL> select * from V$FLASH_RECOVERY_AREA_USAGE;
select * from V$FLASH_RECOVERY_AREA_USAGE;

prompt SQL> select sum(percent_space_used) || ' %' used,sum(percent_space_reclaimable) || ' %' reclaimable from v$flash_recovery_area_usage;
select sum(percent_space_used) || ' %' used, 
sum(percent_space_reclaimable) || ' %' reclaimable 
from v$flash_recovery_area_usage;

prompt
prompt ============================================================================================
prompt ++ FRA Size Usage ++
prompt ============================================================================================
prompt

prompt SQL> select * from V$RECOVERY_FILE_DEST;
select * from V$RECOVERY_FILE_DEST;

set markup html off spool off
@?/rdbms/admin/sqlsessend.sql
exit
