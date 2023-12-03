Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_rman_08137_info.sql /main/10 2021/08/12 07:48:58 bvongray Exp $
Rem
Rem srdc_rman_08137_info.sql
Rem
Rem Copyright (c) 2018, 2021, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_rman_08137_info.sql - RMAN_8137 Health check
Rem
Rem    DESCRIPTION
Rem      Checks RMAN_8137 health of a DB
Rem
Rem    NOTES
Rem      .
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_rman_08137_info.sql
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
Rem    bvongray    09/25/20 - Script Updates
Rem    xiaodowu    05/06/20 - Update script
Rem    xiaodowu    04/22/20 - Update script for RMAN related SRDC collections
Rem    xiaodowu    04/02/19 - Modify script
Rem    recornej    09/26/18 - XbranchMerge recornej_bug-28570494 from main
Rem    recornej    08/31/18 - Adding changes requested by SME.
Rem    xiaodowu    01/18/18 - For dbrman8137_8120 SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

set echo off;
define SRDCNAME='RMAN_8137'

set markup html on spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(value)||'_'||
      to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME 
from v$parameter where lower(name)='instance_name';
REM
spool &&SRDCSPOOLNAME..htm
Set heading off;
select '+----------------------------------------------------+' from dual
union all
select '| Script version:  '||'03-Mar-2021' from dual
union all
select '| Diagnostic-Name:'||'&&SRDCNAME' from dual
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
prompt ++ ARCHIVELOG DESTINATIONS ++
prompt *****************************************************************
prompt

prompt SQL> select d.dest_id,d.dest_name,s.type,d.status,recovery_mode,d.error,d.destination from v$archive_dest d ,v$archive_dest_status s
prompt      where d.dest_id=s.dest_id
prompt      and d.dest_id <>32
prompt      and d.destination is not null;

select d.dest_id,d.dest_name,s.type,d.status,recovery_mode,d.error,d.destination from v$archive_dest d ,v$archive_dest_status s
where d.dest_id=s.dest_id
and d.dest_id <>32
and d.destination is not null;

prompt SQL> select dest_id, status, target, dependency, valid_now, valid_type, valid_role from v$archive_dest; 

select dest_id, status, target, dependency, valid_now, valid_type, valid_role from v$archive_dest; 

prompt SQL> select * from v$archive_dest where (valid_now = 'UNKNOWN' AND status = 'DEFERRED');

select * from v$archive_dest where (valid_now = 'UNKNOWN' AND status = 'DEFERRED') ;

prompt
prompt *****************************************************************
prompt ++ REQUIRED SCN ++
prompt *****************************************************************
prompt

prompt SQL> execute sys.dbms_rcvman.getRequiredSCN(:reqscn, :reqrls); 

variable reqscn number; 
variable reqrls number; 
execute sys.dbms_rcvman.getRequiredSCN(:reqscn, :reqrls); 
print reqscn;
print reqrls;

prompt
prompt *****************************************************************
prompt ++ RMAN, FRA, RESTORE_POINT INFORMATION ++
prompt *****************************************************************
prompt

prompt SQL> Select dbid, name, cdb container from v$database;
Select dbid, name, cdb container from v$database;

prompt SQL> select * from v$rman_configuration;
select * from v$rman_configuration;

prompt SQL> select name, scn, guarantee_flashback_database from v$restore_point;
select name, scn, guarantee_flashback_database from v$restore_point; 

prompt SQL> select current_scn, min_required_capture_change#, database_role from v$database; 
select current_scn, min_required_capture_change#, database_role from v$database; 

prompt SQL> select * from V$flash_recovery_area_usage;
select * from V$flash_recovery_area_usage;

prompt SQL> select * from V$recovery_file_dest; 
select * from V$recovery_file_dest; 

prompt
prompt *****************************************************************
prompt ++ CAPTURE INFORMATION ++
prompt *****************************************************************
prompt

prompt SQL> select capture_name, capture_type, status, queue_owner, capture_user, start_scn, oldest_scn, required_checkpoint_scn from dba_capture;

select capture_name, capture_type, status, queue_owner, capture_user, start_scn, oldest_scn, required_checkpoint_scn from dba_capture;

prompt
prompt *****************************************************************
prompt ++ LAST APPLIED ARCHIVELOG FILE ++
prompt *****************************************************************
prompt

prompt SQL> select dest_id,thread#,sequence# "sequence#",first_time,first_change#,next_time,next_change# from v$archived_log
prompt 2 where (dest_id,thread#,sequence#) in
prompt 3 (select dest_id,thread#,max(sequence#) from v$archived_log where dest_id in
prompt 4 (select to_number(ltrim(name,'log_archive_dest_')) from v$parameter where lower(name) like 'log_archive_dest%' and upper(value) like '%SERVICE=%' 
prompt 5 minus
prompt 6 select dest_id from v$archive_dest where VALID_ROLE  in ('STANDBY_ROLE')) and applied='YES' group by dest_id,thread#)
prompt 7 and activation# in (select activation# from v$database) 
prompt 8 and 'PRIMARY' =(select database_role from v$database)
prompt 9 union 
prompt 10 select dest_id,thread#,sequence# "sequence#",first_time,first_change#,next_time,next_change# from v$archived_log
prompt 11 where (dest_id,thread#,sequence#) in
prompt 12 (select dest_id,thread#,max(sequence#) from v$archived_log where dest_id in (select dest_id from v$archive_dest where destination is not null and upper(VALID_ROLE) in ('ALL_ROLES','STANDBY_ROLE') and dest_id <> 32) and applied='YES' group by dest_id,thread#)
prompt 13 and activation# in (select activation# from v$database) 
prompt 14 and 'PHYSICAL STANDBY' =(select database_role from v$database);

select dest_id,thread#,sequence# "sequence#",first_time,first_change#,next_time,next_change# from v$archived_log
where (dest_id,thread#,sequence#) in
(select dest_id,thread#,max(sequence#) from v$archived_log where dest_id in
(select to_number(ltrim(name,'log_archive_dest_')) from v$parameter where lower(name) like 'log_archive_dest%' and upper(value) like '%SERVICE=%' 
minus
select dest_id from v$archive_dest where VALID_ROLE  in ('STANDBY_ROLE')) and applied='YES' group by dest_id,thread#)
and activation# in (select activation# from v$database) 
and 'PRIMARY' =(select database_role from v$database)
union 
select dest_id,thread#,sequence# "sequence#",first_time,first_change#,next_time,next_change# from v$archived_log
where (dest_id,thread#,sequence#) in
(select dest_id,thread#,max(sequence#) from v$archived_log where dest_id in (select dest_id from v$archive_dest where destination is not null and upper(VALID_ROLE) in ('ALL_ROLES','STANDBY_ROLE') and dest_id <> 32) and applied='YES' group by dest_id,thread#)
and activation# in (select activation# from v$database) 
and 'PHYSICAL STANDBY' =(select database_role from v$database) 
;

prompt
prompt ************************************
prompt ++ ARCHIVELOG APPLY RANGE ++
prompt ************************************


prompt SQL> select b.dest_id,a.thread#,a.sequence# "latest archivelog" ,b.sequence# "latest archive applied",a.sequence# - b.sequence# "# Not Applied" from
prompt 2 (select dest_id,thread#,max(sequence#) sequence# from v$archived_log 
prompt 3 where dest_id in (select to_number(ltrim(name,'log_archive_dest_')) from v$parameter where lower(name) like 'log_archive_dest%' and upper(value) like '%SERVICE=%' 
prompt 4 minus
prompt 5 select dest_id from v$archive_dest where VALID_ROLE  in ('STANDBY_ROLE')) 
prompt 6 and applied='YES' group by dest_id,thread#) b,
prompt 7 (select thread#,max(sequence#) sequence#  from v$archived_log where activation# in (select activation# from v$database) group by thread#) a
prompt 8 where a.thread#=b.thread#
prompt 9 and 'PRIMARY' =(select database_role from v$database)
prompt 10 union 
prompt 11 select b.dest_id,a.thread#,a.sequence# "latest archivelog" ,b.sequence# "latest archive applied",a.sequence# - b.sequence# "# Not Applied" from
prompt 12 (select dest_id,thread#,max(sequence#) sequence# from v$archived_log where applied='YES' and  dest_id in ( select dest_id from v$archive_dest where destination is not null and upper(VALID_ROLE) in ('ALL_ROLES','STANDBY_ROLE') and dest_id <> 32 ) group by dest_id,thread#) b,
prompt 13 (select thread#,max(sequence#) sequence#  from v$archived_log where activation# in (select activation# from v$database) group by thread#) a
prompt 14 where a.thread#=b.thread#
prompt 15 and 'PHYSICAL STANDBY' =(select database_role from v$database); 

select b.dest_id,a.thread#,a.sequence# "latest archivelog" ,b.sequence# "latest archive applied",a.sequence# - b.sequence# "# Not Applied" from
(select dest_id,thread#,max(sequence#) sequence# from v$archived_log 
where dest_id in (select to_number(ltrim(name,'log_archive_dest_')) from v$parameter where lower(name) like 'log_archive_dest%' and upper(value) like '%SERVICE=%' 
minus
select dest_id from v$archive_dest where VALID_ROLE  in ('STANDBY_ROLE')) 
 and applied='YES' group by dest_id,thread#) b,
(select thread#,max(sequence#) sequence#  from v$archived_log where activation# in (select activation# from v$database) group by thread#) a
where a.thread#=b.thread#
and 'PRIMARY' =(select database_role from v$database)
union 
select b.dest_id,a.thread#,a.sequence# "latest archivelog" ,b.sequence# "latest archive applied",a.sequence# - b.sequence# "# Not Applied" from
(select dest_id,thread#,max(sequence#) sequence# from v$archived_log where applied='YES' and  dest_id in ( select dest_id from v$archive_dest where destination is not null and upper(VALID_ROLE) in ('ALL_ROLES','STANDBY_ROLE') and dest_id <> 32 ) group by dest_id,thread#) b,
(select thread#,max(sequence#) sequence#  from v$archived_log where activation# in (select activation# from v$database) group by thread#) a
where a.thread#=b.thread#
and 'PHYSICAL STANDBY' =(select database_role from v$database); 

prompt 
prompt ************************************************
prompt ++ STANDBY LAST RECEIVED and LAST APPLIED ++
prompt ++   ONLY APPLIES TO STANDBY DATABASE ++
prompt ************************************************

prompt SQL> SELECT al.thrd "Thread", almax "Last Seq Received", lhmax "Last Seq Applied" 
prompt 2 FROM (select thread# thrd, MAX(sequence#) almax FROM v$archived_log WHERE 
prompt 3 resetlogs_change#=(SELECT resetlogs_change# FROM v$database) GROUP BY thread#) al, 
prompt 4 (SELECT thread# thrd, MAX(sequence#) lhmax FROM v$log_history WHERE 
prompt 5 resetlogs_change#=(SELECT resetlogs_change# 
prompt 6 FROM v$database) GROUP BY thread#) lh WHERE al.thrd = lh.thrd
prompt 7 and 'PHYSICAL STANDBY' =(select database_role from v$database); 

SELECT al.thrd "Thread", almax "Last Seq Received", lhmax "Last Seq Applied" 
FROM (select thread# thrd, MAX(sequence#) almax FROM v$archived_log WHERE 
resetlogs_change#=(SELECT resetlogs_change# FROM v$database) GROUP BY thread#) al, 
(SELECT thread# thrd, MAX(sequence#) lhmax FROM v$log_history WHERE 
resetlogs_change#=(SELECT resetlogs_change# 
FROM v$database) GROUP BY thread#) lh WHERE al.thrd = lh.thrd
and 'PHYSICAL STANDBY' =(select database_role from v$database); 

prompt
prompt ****************************************
prompt ++           MRP STATUS ++
prompt ++ ONLY APPLIES TO STANDBY DATABASE ++
prompt ****************************************

PROMPT SQL> select inst_id,thread#,sequence#,status from gv$managed_standby where process='MRP0';

select inst_id,thread#,sequence#,status from gv$managed_standby where process='MRP0';

prompt
prompt *****************************************************************
prompt ++ ARCHIVELOG INFORMATION (Last 2 days) ++
prompt *****************************************************************
prompt

prompt select thread#, sequence#, first_change#, next_change#, first_time, applied, backup_count,standby_dest from v$archived_log L, v$database D where L.resetlogs_change#=D.resetlogs_change# 
prompt and first_time > sysdate-2 and status='A' 
prompt and dest_id in (select dest_id from v$archive_dest where target='PRIMARY')
prompt and 'PRIMARY' =(select database_role from v$database) 
prompt union
prompt select thread#, sequence#, first_change#, next_change#, first_time, applied, backup_count,standby_dest from v$archived_log L, v$database D where L.resetlogs_change#=D.resetlogs_change# 
prompt and first_time > sysdate-2 and status='A' 
prompt and dest_id in (select dest_id from v$archive_dest where target='LOCAL')
prompt and 'PHYSICAL STANDBY' =(select database_role from v$database) 
prompt order by 1,2
prompt ;

select thread#, sequence#, first_change#, next_change#, first_time, applied, backup_count,standby_dest from v$archived_log L, v$database D where L.resetlogs_change#=D.resetlogs_change# 
and first_time > sysdate-2 and status='A' 
and dest_id in (select dest_id from v$archive_dest where target='PRIMARY')
and 'PRIMARY' =(select database_role from v$database) 
union
select thread#, sequence#, first_change#, next_change#, first_time, applied, backup_count,standby_dest from v$archived_log L, v$database D where L.resetlogs_change#=D.resetlogs_change# 
and first_time > sysdate-2 and status='A' 
and dest_id in (select dest_id from v$archive_dest where target='LOCAL')
and 'PHYSICAL STANDBY' =(select database_role from v$database) 
order by 1,2
;


set markup html off spool off
@?/rdbms/admin/sqlsessend.sql
exit

