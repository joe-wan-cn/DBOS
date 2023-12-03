Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_cdb_recovery_info.sql /main/10 2023/03/20 15:50:26 smuthuku Exp $
Rem
Rem srdc_cdb_recovery_info.sql
Rem
Rem Copyright (c) 2018, 2023, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_cdb_recovery_info.sql
Rem
Rem    DESCRIPTION
Rem      Query for RMAN CDB information.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_cdb_recovery_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    03/08/23 - ER 	35156270 	
Rem    smuthuku    10/06/22 - bug 34534499
Rem    bvongray    08/05/21 - bug 32988384
Rem    bvongray    03/18/21 - script update
Rem    bvongray    11/06/20 - SRDC Script Updates
Rem    bvongray    09/25/20 - Script Updates
Rem    xiaodowu    05/21/20 - Modify script
Rem    xiaodowu    04/22/20 - Update script for RMAN related SRDC collections
Rem    xiaodowu    03/11/19 - Update script
Rem    xiaodowu    03/29/18 - Changed the output file name to be used for consolidated dbrman SRDC collection
Rem    xiaodowu    01/18/18 - For dbrmanrr SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

REM srdc_rman_restore_dbinfo.sql - collect RMAN datafile information for restore/recover.
define SRDCNAME='RMAN_RESTORE_CDB_DBINFO'
SET MARKUP HTML ON spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(value)||'_'||
      to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME 
from v$parameter where lower(name)='instance_name';

REM
spool &&SRDCSPOOLNAME..htm
set header off;
select '+----------------------------------------------------+' from dual
union all
select '| Script version:  '||'02-Jun-2022' from dual
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
set header on;
set echo on
set linesize 200 trimspool on
col name form a60
col dbname form a15
col member form a80
col inst_id form 999
col resetlogs_time form a25
col created form a25
col db_unique_name form a15
col stat form 9999999999
col thr form 99999
col "Uptime" form a80
col file# form 999999
col checkpoint_change# form 999999999999999
col first_change# form 999999999999999
col change# form 999999999999999
set numwidth 30;
set pagesize 50000;
alter session set nls_date_format = 'DD-MON-RRRR HH24:MI:SS';

select sysdate from dual;

select decode(count(cell_path),0,'Non-Exadata','Exadata') "System" from v$cell;
show user

REM
REM ++++++++++ FRA ++++++++++++
REM
show parameter db_recovery_file_dest;

REM
REM ++++++++++ DATABASE INFORMATION ++++++++++++
REM

-- Information on how long the instance has been up.  

select   inst_id, instance_name, status, startup_time || ' - ' ||
trunc(SYSDATE-(STARTUP_TIME) ) || ' day(s), ' || trunc(24*((SYSDATE-STARTUP_TIME) -
trunc(SYSDATE-STARTUP_TIME)))||' hour(s), ' || mod(trunc(1440*((SYSDATE-STARTUP_TIME) - trunc(SYSDATE-STARTUP_TIME))), 60) ||' minute(s), ' || mod(trunc(86400*((SYSDATE-STARTUP_TIME) - trunc(SYSDATE-STARTUP_TIME))), 60) ||' seconds' "Uptime"
from     gv$instance
order by inst_id
/

-- The following query gives us some general information on the database.  
-- We see the database_role (primary vs standby) and the open_mode (mounted, read write, read only).  
-- It is important to note if controlfile_type is current, standby, or backup.  
-- The resetlog information must match that of the datafile resetlogs (v$datafile_header)

select dbid, name, db_unique_name, database_role, created, resetlogs_change#, resetlogs_time, open_mode, log_mode, checkpoint_change#, controlfile_type, controlfile_change#, controlfile_time from v$database;
select dbid, name, cdb from v$database;

-- A quick view of archivelog configuration.  Location where archivelog files are being created.  Current online log.  
-- Comparing the 'next to archive' and 'current' can tell you quickly if archiving is stuck.  

archive log list;

-- The following query tells us the location and names of the controlfiles being used by the database and if they reside in the FRA. 

select * from v$controlfile;

-- At every resetlogs a new database incarnation is created.  This query gives us the details of all incarnations of the database.  
-- The status column tells us the CURRENT incarnation.  The details must match that of the datafiles (v$datafile_header)

select * from v$database_incarnation;

-- Details on PDBs

show pdbs;
select con_id,name,open_mode,restricted from v$containers;
select * from v$pdbs;
select * from v$pdb_incarnation;
select name, con_id, dbid, con_uid, guid from v$containers order by con_id;

REM
REM ++++++++++ DATAFILE INFORMATION ++++++++++++
REM

-- When an 'alter database/tablespace begin backup' command is executed, the status column within the following query will show ACTIVE.

select distinct(status), count(*)  from V$BACKUP group by status;

-- This query gives a list of all datafiles, the tablespace to which they belong, as well as the datafile status.  

select 'ROOT', d.con_id, file#,  d.name, t.name, status, enabled, creation_change#, creation_time, plugin_change#, foreign_dbid
from v$datafile d, v$tablespace t
where d.con_id=1 and d.ts#=t.ts# and
d.con_id=t.con_id
UNION
select c.name, d.con_id, file#,  d.name, t.name, status, enabled, d.creation_change#, d.creation_time, plugin_change#, foreign_dbid
from v$datafile d, v$tablespace t, v$pdbs c
where d.con_id=c.con_id and d.ts#=t.ts# and t.con_id=c.con_id
order by 2;

-- This query gives details on tablespaces.  

select * from v$tablespace;

-- This query returns a list of all tempfiles.  Note, if a controlfile is recreated, this view will report no rows.  

select * from v$tempfile;

-- The v$datafile_header view gives you information directly from the datafiles.  
-- The queries from this view give you accurate checkpoint information.   This is useful in determining date/time fo the data before opening the database.  
-- A zero checkpoint value indicates that we cannot read the file.  This can be because the datafile is missing or 
-- the path/name does not correspond with the actual path/name of the datafile.  

select 'ROOT', d.con_id, file#, status, checkpoint_change#, checkpoint_time, resetlogs_change#, resetlogs_time, fuzzy
from v$datafile_header d
where d.con_id=1 
UNION
select c.name, d.con_id, file#, status, checkpoint_change#, checkpoint_time, resetlogs_change#, resetlogs_time, fuzzy 
from v$datafile_header d, v$pdbs c
where d.con_id=c.con_id 
order by con_id, file#;

-- This is a summary of all the datafiles.  
-- Excluding read only datafiles, the following query should return 1 row with fuzzy=NO.  
-- Multiple rows indicates that the datafiles are not consistent.  
-- A fuzzy=YES, indicates that more recovery is needed or the database is open in read/write.

column con_id noprint;
select 'ROOT',status,checkpoint_change#,checkpoint_time, resetlogs_change#, resetlogs_time, count(*), fuzzy,h.con_id from v$datafile_header h
where h.con_id=1
group by status,checkpoint_change#,checkpoint_time, resetlogs_change#,
resetlogs_time, fuzzy,h.con_id
UNION
select p.name,status,checkpoint_change#,checkpoint_time, resetlogs_change#, resetlogs_time, count(*), fuzzy,h.con_id from v$datafile_header h, v$pdbs p
where  h.con_id=p.con_id
group by p.name, status,checkpoint_change#,checkpoint_time, resetlogs_change#,
resetlogs_time, fuzzy,h.con_id
order by con_id;
column con_id print

-- The datafiles listed in this query need to be recovered.

select * from v$recover_file order by 1;

-- Distinct status of all the datafiles in with database.  

select distinct(status)from v$datafile;

-- This query will give the total size of the database.  Note, tempfiles are not included. 

select round(sum(bytes)/1024/1024/1024,0) db_size_GB from v$datafile;

-- See INTERNAL ONLY Note:Understanding and Deciphering X$KCVFH.FHSTA column value (Doc ID 2013384.1)
-- V$datafile_header can be used for most of the information in this view.  
-- The FHRBA_SEQ column tells you the next archivelog sequence needed by the datafile. 
-- The lowest FHRBA_SEQ is the start of recovery.  

select FHTHR Thread, FHRBA_SEQ Sequence, count(1)
from X$KCVFH
group by FHTHR, FHRBA_SEQ
order by FHTHR, FHRBA_SEQ;

-- In order to open the database, all datafiles must be recovered through the 'absolute fuzzy' to ensure consistence and 
-- in order for the database to open

select hxfil file#, substr(hxfnm, 1, 50) name, fhscn checkpoint_change#, fhafs Absolute_Fuzzy_SCN, 
max(fhafs) over () Min_PIT_SCN
from x$kcvfh where fhafs!=0 ;

select substr(FHTNM,1,20) ts_name, HXFIL File_num,FHSCN SCN, FHSTA status, substr(HXFNM,1,80) name, 
FHRBA_SEQ Sequence, FHTIM checkpoint_time, FHBCP_THR Thread
from X$KCVFH;

select con_id, HXFIL File_num, FHSCN SCN, FHSTA status, FHDBN dbname, FHDBI DBID, FHRBA_SEQ Sequence
from X$KCVFH
order by con_id, hxfil;

select fhsta, count(*) from X$KCVFH group by fhsta;

select min(fhrba_Seq), max(fhrba_Seq) from X$KCVFH x join 
v$datafile d on (x.hxfil=d.file#) and d.enabled not in ('READ ONLY');

REM +++++++++++ IF THE FOLLOWING QUERIES FAIL, THE DATABASE IS NOT OPEN ++++++++++

select pdb_id, pdb_name, status from dba_pdbs order by pdb_id;

select p.pdb_id, p.pdb_name, u.username from dba_pdbs p, cdb_users u
where  p.pdb_id=u.con_id order by p.pdb_id;

select p.pdb_id, p.pdb_name, d.file_id, d.tablespace_name, d.file_name 
from dba_pdbs p, cdb_data_files d 
where p.pdb_id=d.con_id
order by p.pdb_id;

select con_id, file_id, tablespace_name, file_name 
from cdb_temp_files order by con_id;

select tablespace_name, contents 
from dba_tablespaces where contents = 'UNDO';

select pdb, network_name, con_id 
from cdb_services 
where pdb is not null and con_id > 2 order by pdb;

select con_id, file_id, tablespace_name, file_name from cdb_temp_files order by con_id;

SELECT tablespace_name, contents from dba_tablespaces where contents = 'UNDO';

select db_name, con_id, pdb_name, operation, op_timestamp, cloned_from_pdb_name 
from cdb_pdb_history order by con_id;


REM
REM ++++++++++ LOGFILE INFORMATION ++++++++++++
REM

-- Online log file information.  Status=CURRENT indicates the online log the system was writing.  
-- The information in this query will ONLY be accurate if the controlfile_type=CURRENT.  

select v1.thread#, v1.group#, v1.sequence#, v1.first_change#, v1.first_time,
v1.archived, v1.status,v2.member
from v$log v1, v$logfile v2 where v1.group#=v2.group#
order by v1.first_time;

REM
REM ++++++++++ RMAN INFORMATION ++++++++++++
REM

-- The following query will show all NON-Default RMAN configuration.  

select * from v$rman_configuration;

-- The following output is RMAN standard output for the last 5 days.  

select o.output
from v$rman_output o, v$rman_backup_job_details d 
where O.session_recid=d.session_recid 
and o.session_stamp=d.session_stamp
and d.end_time > sysdate-5;

REM
REM ++++++++++ CONTROLFILE RECORD INFORMATION ++++++++++++
REM

-- Best practice if for control_file_record_keep to be no larger than 10 days.  

show parameter control_file_record_keep;

-- RMAN performance issues sometimes may be caused by very large totals (records_total column) of 
-- a particular controlfile section.

select * from v$controlfile_record_section;

REM
REM ++++++++++ FLASHBACK DATABASE INFORMATION ++++++++++++
REM

-- Flashback information.  Min values are the lowest flashback allowed for flashback database outside 
-- a particular restore point.  

select database_role, open_mode, log_mode, flashback_on from v$database;
select * from v$restore_point;
select * from v$flashback_database_log;
select min(first_time) from v$flashback_database_logfile;
select min(first_change#) from v$flashback_database_logfile;

set markup html off spool off
@?/rdbms/admin/sqlsessend.sql
exit
