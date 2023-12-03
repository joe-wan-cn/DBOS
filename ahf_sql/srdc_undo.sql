Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_undo.sql /main/4 2021/03/24 11:11:29 bvongray Exp $
Rem
Rem srdc_undo.sql
Rem
Rem Copyright (c) 2019, 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_undo.sql - script to collect Undo related diagnostic data 
Rem
Rem    NOTES
Rem      * This script collects the data related to the Undo issues 
Rem		   including the configuration, parameters , statistics etc
Rem		   and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_undo.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_undo.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray   03/19/21 - script updates
Rem    slabraha   02/19/21 - modifed queries to collect 1 week data and not more.
Rem    slabraha   04/14/20 - added a few checks
Rem    slabraha   03/14/19 - made a few corrections
Rem    xiaodowu   02/11/19 - Called by ora1555 SRDC collection, srdc_ora1555
Rem    xiaodowu   02/11/19 - Created
Rem
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_Undo'
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
prompt                            ++ UNDO Parameters ++
prompt ============================================================================================
prompt
set echo on
select 'Undo_Parameter1' "CHECK_NAME",a.inst_id,a.name,a.type,a.value "SP_Parameter",b.value "from_pfile" from gv$spparameter a, gv$parameter b where a.name=b.name and a.name in ('temp_undo_enabled', 'undo_management','undo_tablespace','undo_retention','fast_start_parallel_rollback' ,'parallel_max_servers')
/
select 'Undo_Parameter2' "CHECK_NAME",inst_id,name,type,value from gv$parameter where name like '%undo%' OR name like 'fast_start_parallel_rollback' OR name like 'parallel_max_servers'
/
select  'Hidden Parameters' "CHECK_NAME",a.inst_id, a.ksppinm  "Parameter",
             b.ksppstvl "Session Value",
             c.ksppstvl "Instance Value"
      from x$ksppi a, x$ksppcv b, x$ksppsv c
     where a.indx = b.indx and a.indx = c.indx
       and a.inst_id=b.inst_id and b.inst_id=c.inst_id
       and a.ksppinm in ('_undo_autotune', '_smu_debug_mode',
                         '_highthreshold_undoretention','_disable_flashback_archiver',
				'event', '_first_spare_parameter','_rollback_segment_count')
order by 2
/
set echo off
prompt
prompt ============================================================================================
prompt                       ++ UNDO Tablespace Configuration ++
prompt ============================================================================================
prompt
set echo on
select 'Undo_Tablespace' "CHECK_NAME",tablespace_name,block_size,status,retention,extent_management,status,bigfile from dba_tablespaces where contents='UNDO'
/
SELECT 'Undo_Datafiles' "CHECK_NAME",tablespace_name,file_name,autoextensible,(bytes)/(1024*1024*1024) space_In_GB,(maxbytes)/(1024*1024*1024) MaxBytes_In_GB FROM dba_data_files WHERE tablespace_name in (select value from v$parameter where name= 'undo_tablespace')
/
SELECT 'Free_Space' "CHECK_NAME",tablespace_name, SUM(BYTES/1048576) total_space_MB, max(BYTES)/1048576 largest_extent_MB FROM DBA_FREE_SPACE WHERE TABLESPACE_NAME in (select value from v$parameter where name= 'undo_tablespace') group by tablespace_name
/
SELECT 'Capacity_Planning-1' "CHECK_NAME",(UR * (UPS * DBS))/1024/1024/1024 AS "Min_Required_Space_GB" FROM (SELECT value AS UR FROM v$parameter WHERE name = 'undo_retention'), (SELECT undoblks/((end_time-begin_time)*86400) AS UPS FROM v$undostat WHERE undoblks = (SELECT MAX(undoblks) FROM v$undostat)), (SELECT block_size AS DBS FROM dba_tablespaces WHERE tablespace_name = (SELECT UPPER(value) FROM v$parameter WHERE name = 'undo_tablespace'))
/

SELECT 'Capacity_Planning-2' "CHECK_NAME",(UR * (UPS * DBS))/1024/1024/1024 AS "Required_Space_GB" FROM (SELECT max(tuned_undoretention) AS UR from dba_hist_undostat), (SELECT undoblks/((end_time-begin_time)*86400) AS UPS FROM dba_hist_undostat WHERE undoblks = (SELECT MAX(undoblks) FROM dba_hist_undostat)), (SELECT block_size AS DBS FROM dba_tablespaces WHERE tablespace_name = (SELECT UPPER(value) FROM v$parameter WHERE name = 'undo_tablespace'))
/
set echo off
prompt
prompt ============================================================================================
prompt                            ++ Specific to 12cR2 and above ++
prompt ============================================================================================
prompt
set echo on
select '12c_Undo_mode' "CHECK_NAME",property_name,property_value from database_properties where property_name='LOCAL_UNDO_ENABLED'
/
select 'CDB_Undo_Tablespace' "CHECK_NAME",a.CON_ID,a.TABLESPACE_NAME,b.FILE_NAME from cdb_tablespaces a,CDB_DATA_FILES b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.con_id=b.con_id and a.CONTENTS='UNDO'
/
select 'Historial_Data_PDBs' "CHECK_NAME",con_id,max(maxquerylen), max(tuned_undoretention),max(maxconcurrency), max(undoblks), max(txncount) 
from dba_hist_undostat where end_time > sysdate-10
group by con_id
/
set echo off
prompt
prompt ============================================================================================
prompt                               ++ UNDO Allocation Details ++
prompt ============================================================================================
prompt
set echo on
select 'Undo_Segments' "CHECK_NAME",tablespace_name, status, count(*) from dba_rollback_segs group by tablespace_name,status
/
select 'Undo_Extent_Status' "CHECK_NAME",tablespace_name, 
round(sum(case when status = 'UNEXPIRED' then bytes else 0 end) / 1048675,2) unexpired_MB ,
round(sum(case when status = 'EXPIRED' then bytes else 0 end) / 1048576,2) expired_MB ,
round(sum(case when status = 'ACTIVE' then bytes else 0 end) / 1048576,2) active_MB 
from dba_undo_extents group by tablespace_name
/
SELECT 'Largest_Undo_Extents' "CHECK_NAME",segment_name, bytes "Extent_Size", count(extent_id) "Extent_Count", bytes * count(extent_id) "Extent_Bytes" FROM dba_undo_extents WHERE rownum < 11 group by segment_name, bytes order by 1, 3 desc
/
SELECT 'Largest_Active_Extents' "CHECK_NAME",segment_name, bytes "Extent_Size", count(extent_id) "Extent_Count", bytes * count(extent_id) "Extent_Bytes" FROM dba_undo_extents WHERE rownum < 11 and status = 'ACTIVE' group by segment_name, bytes order by 1, 3 desc
/
select 'Undo_Temp_Usage' "CHECK_NAME",'UNDO' as NAME, total_undo_mb as total_mb,USED_MB,round(USED_MB/total_undo_mb*100) as USED_PERCENT
from ( 
select round((select sum(BYTES)/1024/1024 from dba_DatA_files where tablespace_name like 'UNDO%')) as total_undo_mb,
round((b.total_ublk * (select value from v$parameter where name='db_block_size'))/1024/1024) as USED_MB
from (select sum(used_ublk) as total_ublk from v$transaction) b ) 
union all 
select 'Undo_Temp_Usage' "CHECK_NAME",'TEMP' as NAME, total_temp_mb as total_mb,USED_MB,round(USED_MB/total_temp_mb*100) as USED_PERCENT
from ( 
select round((select sum(BYTES)/1024/1024 from dba_temp_files)) as total_temp_mb,
round((b.total_ublk * (select value from v$parameter where name='db_block_size'))/1024/1024) as USED_MB
from (select sum(blocks) as total_ublk from v$sort_usage) b ) 
/
set echo off
prompt
prompt ============================================================================================
prompt                             ++ Undo Statistics ++
prompt ============================================================================================
prompt
set echo on
select 'Undo_Stats-1' "CHECK_NAME",name, waits, gets  from   v$rollstat, v$rollname  where  v$rollstat.usn = v$rollname.usn  
/  
col pct head "< 2% ideal"
select 'Undo_Stats-2' "CHECK_NAME",'The average of waits/gets is '||round((sum(waits) / sum(gets)) * 100,2)||'%' PCT From    v$rollstat  
/
select 'Undo_Stats-3' "CHECK_NAME",class, count  from   v$waitstat  
where  class in ('system undo header', 'system undo block', 'undo header','undo block' )    
/
select * from v$enqueue_stat where eq_type='US'
union
select * from v$enqueue_stat where eq_type='HW'
/
select 'Undo_Locks' "CHECK_NAME",a.SID, b.process, b.OSUSER,  b.MACHINE,  b.PROGRAM,addr, kaddr, lmode, request, round(ctime/60/60,0) "Time|(Mins)", block "Blocking?"
from v$lock a, v$session b where a.sid=b.sid and a.type='US'
/
select 'Undo_Tune_Statistics' "CHECK_NAME", name, value from v$sysstat
where name like '%down retention%' or name like 'une down%'
or name like '%undo segment%' or name like '%rollback%'
or name like '%undo record%'
/
set echo off
prompt
prompt ============================================================================================
prompt                                   ++ V$UNDOSTAT Output ++
prompt ============================================================================================
prompt
set echo on

select 'Undo_Errors' "CHECK_NAME",sum(ssolderrcnt) "1555 Errors",sum(nospaceerrcnt) "Undo Space Errors" from v$undostat
/
select 'Concurrency_7Days' "CHECK_NAME",max(maxconcurrency) "Max Concurrent|Last 7 Days" from v$undostat
/
select 'Concurrency_Startup' "CHECK_NAME",max(maxconcurrency) "Max Concurrent|Since Startup" from sys.wrh$_undostat
/
select end_time, undoblks/((end_time-begin_time)*86400) "Peak Undo Block Generation" FROM v$undostat WHERE undoblks=(SELECT MAX(undoblks) FROM v$undostat)
/
select  'Retention_Tuning' "CHECK_NAME",min(tuned_undoretention) "Lowest Tuned Value", max(tuned_undoretention) "Highest Tuned Value" from v$undostat
/
Select 'Retention_Tuning-2' "CHECK_NAME",max(maxquerylen),max(tuned_undoretention) from v$undostat
/
select * from v$undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/
select * from sys.wrh$_undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/
select 'Undo_Extent_Stealing' "CHECK_NAME",unxpstealcnt "UnexStolen", expstealcnt "ExStolen",  unxpblkreucnt "UnexReuse", expblkreucnt "ExReuse"
from v$undostat
where (unxpstealcnt > 0 or expstealcnt > 0)
/

SELECT 'Runaway_Queries' "CHECK_NAME",st.begin_time,st.maxquerylen,st.maxqueryid, s.SQL_TEXT  
FROM v$undostat st INNER JOIN v$sql s ON s.sql_id = st.maxqueryid   where rownum <11 order by maxquerylen desc
/
column UNXPSTEALCNT heading "# Unexpired|attempt"
column EXPSTEALCNT heading "# Expired|attempt"
column SSOLDERRCNT heading "ORA-1555|Error"
column NOSPACEERRCNT heading "Out-Of-space|Error"
column MAXQUERYLEN heading "Max Query|Length"
column ACTIVEBLKS heading "Active Blocks"
column UNEXPIREDBLKS heading "Unexpired Blocks"
column EXPIREDBLKS heading "Expired Blocks"
column TUNED_UNDORETENTION heading "Tuned Undo retention"
column UNXPBLKRELCNT heading "Unexpired|Removed for reuse"
column UNXPBLKREUCNT heading "Unexpired|Reused by Transactions"
column EXPBLKRELCNT heading "Expired| Stolen from other"
column EXPBLKREUCNT heading "Expired| Stolen from same"
column UNDOBLKS heading "Undo Blocks"

select 'Undostat_2days' "CHECK_NAME",inst_id, to_char(begin_time,'MM/DD/YYYY HH24:MI') begin_time, UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, ACTIVEBLKS,UNEXPIREDBLKS,EXPIREDBLKS,UNXPBLKRELCNT,UNXPBLKREUCNT,EXPBLKRELCNT,EXPBLKREUCNT,MAXQUERYLEN, TUNED_UNDORETENTION from gv$undostat 
where begin_time > sysdate -2 order by inst_id, begin_time
/
select count(*) from gv$undostat where (ssolderrcnt > 0 or nospaceerrcnt > 0)
/
select * from gv$undostat where (ssolderrcnt > 0 or nospaceerrcnt > 0) and begin_time > sysdate - 7
/
select count(*) from dba_hist_undostat where (ssolderrcnt > 0 or nospaceerrcnt > 0)
/
select * from dba_hist_undostat where (ssolderrcnt > 0 or nospaceerrcnt > 0) and begin_time > sysdate - 7
/
select 'Long Running Query History' "CHECK_NAME",end_time, maxquerysqlid, runawayquerysqlid "Runaway SQL ID", status,
        decode(status,1,'Slot Active',4,'Reached Best Retention',5,'Reached Best Retention',
                    8, 'Runaway Query',9,'Runaway Query-Active',10,'Space Pressure',
                   11,'Space Pressure Currently',
                   16, 'Tuned Down (to undo_retention) due to Space Pressure', 
                   17,'Tuned Down (to undo_retention) due to Space Pressure-Active',
                   18, 'Tuning Down due to Runaway', 19, 'Tuning Down due to Runaway-Active',
                   28, 'Runaway tuned down to last tune down value',
                   29, 'Runaway tuned down to last tune down value',
                   32, 'Max Tuned Down - Not Auto-Tuning',
                   33, 'Max Tuned Down - Not Auto-Tuning (Active)',
                   37, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   38, 'Max Tuned Down - Not Auto-Tuning', 
                   39, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   40, 'Max Tuned Down - Not Auto-Tuning', 
                   41, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   42, 'Max Tuned Down - Not Auto-Tuning', 
                   44, 'Max Tuned Down - Not Auto-Tuning', 
                   45, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   'Other ('||status||')') "Space Issues", spcprs_retention "Tuned Down|Retention"
from sys.wrh$_undostat
where status > 1
/
select 'Long Running Query Details' "CHECK_NAME",sql_id, sql_fulltext, last_load_time "Last Load", 
round(elapsed_time/1000000/60/60/24,0) "Elapsed Days" 
from v$sql where sql_id in 
(select maxquerysqlid from sys.wrh$_undostat 
where status > 1) end_time >sysdate - 7
/
select 'Historial_Data' "CHECK_NAME",end_time, round(maxquerylen/60,0) "Query|Maximum|Minutes", maxquerysqlid,
undotsn, undoblks, txncount, unexpiredblks, expiredblks, 
round(tuned_undoretention/60,0) Tuned
from dba_hist_undostat
where end_time > sysdate-10
order by end_time
/
set echo off
prompt
prompt ============================================================================================
prompt                                       ++ Active Transactions ++
prompt ============================================================================================
prompt
set echo on
select 'Active_Transactions' "CHECK_NAME",b.sid,b.serial#,b.username,a.start_date,a.start_time, a.start_scn, a.status, c.sql_text,a.used_urec,a.used_ublk from v$transaction a, v$session b, v$sqlarea c
where b.saddr=a.ses_addr and c.address=b.sql_address and b.sql_hash_value=c.hash_value
/
select 'SCN' "CHECK_NAME",current_scn from v$database
/
select 'Active_Undo_Usage' "CHECK_NAME",start_time, username, r.name, ubafil, ubablk, t.status, (used_ublk*p.value)/1024 blk, used_urec
from v$transaction t, v$rollname r, v$session s, v$parameter p
where t.xidusn=r.usn and s.saddr(+)=t.ses_addr and p.name = 'db_block_size'
order by 1
/
SELECT 'top_10_Undo_users' "CHECK_NAME",s.sid, s.serial#, s.username, u.segment_name, count(u.extent_id) "Extent Count", t.used_ublk, t.used_urec, s.program
FROM v$session s, v$transaction t, dba_undo_extents u
WHERE s.taddr = t.addr and u.segment_name like '_SYSSMU'||t.xidusn||'_%$' and u.status = 'ACTIVE' and rownum<11
GROUP BY s.sid, s.serial#, s.username, u.segment_name, t.used_ublk, t.used_urec, s.program
ORDER BY t.used_ublk desc, t.used_urec desc, s.sid, s.serial#, s.username, s.program
/
set echo off
prompt
prompt ============================================================================================
prompt                       ++ Dead transactions and recovery status ++
prompt ============================================================================================
prompt
set echo on
select 'Rollback_transactions' "CHECK_NAME",s.sid, s.serial#, s.client_info, t.addr, sum(t.used_ublk) from v$transaction t, v$session s 
where t.addr = s.taddr and bitand(t.flag,power(2,7))>0 group by s.sid, s.serial#, s.client_info, t.addr
/
SELECT 'Dead_Transactions' "CHECK_NAME",KTUXEUSN, KTUXESLT, KTUXESQN, /* Transaction ID */ KTUXESTA 
Status, KTUXECFL flags
FROM x$ktuxe WHERE ktuxesta!= 'INACTIVE' 
/
SELECT 'Distrib_Transaction-1' "CHECK_NAME",LOCAL_TRAN_ID,GLOBAL_TRAN_ID,STATE,MIXED,COMMIT# FROM DBA_2PC_PENDING
/
SELECT 'Distrib_Transaction-2' "CHECK_NAME",LOCAL_TRAN_ID,IN_OUT,DATABASE,INTERFACE FROM dba_2pc_neighbors
/
select 'Dead_Transactions_Undo' "CHECK_NAME",useg.segment_name, useg.segment_id, useg.tablespace_name, useg.status
from dba_rollback_segs useg
where useg.segment_id in (select unique ktuxeusn
from x$ktuxe
where ktuxesta <> 'INACTIVE'
and ktuxecfl like '%DEAD%')
/
SELECT * FROM v$fast_start_servers
/
SELECT 'Transaction_Recovery_Estimate' "CHECK_NAME",usn,state ,undoblockstotal "Total", undoblocksdone "Done",undoblockstotal - undoblocksdone "ToDo",
DECODE (cputime ,0, 'unknown',SYSDATE + (  (  (undoblockstotal - undoblocksdone )/ (undoblocksdone / cputime )) / 86400)) "Estimated time to complete"
FROM v$fast_start_transactions
/
select 'RAC_TXNRecovery_Estimate' "CHECK_NAME",INST_ID,usn, state, undoblockstotal "Total", undoblocksdone "Done",undoblockstotal-undoblocksdone "ToDo",decode(cputime,0,'unknown',sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400)) "Estimated time to complete" from gv$fast_start_transactions
/
select 'Transaction_Recovery' "CHECK_NAME",decode( px. qcinst_id,NULL,username ,' - '||lower(substr(s.program,length( s.program)- 4,4 ) ) ) "Username",
         decode(px. qcinst_id,NULL, 'QC', '(Slave)' ) "QC/Slave" ,
         to_char( px. server_set) "Slave Set",
         to_char(s.sid) "SID" ,
         decode(px. qcinst_id, NULL ,to_char(s .sid) , px. qcsid) "QC SID",
         px .req_degree "Requested DOP",
         px .degree "Actual DOP"
from gv$px_session px, gv$session s
where px.sid= s.sid (+)
and px. serial#=s.serial#
order by 5 , 1 desc
/
set echo off
prompt
prompt ============================================================================================
prompt                     ++ Flashback Data Archive Information ++
prompt ============================================================================================
prompt
set echo on
select 'FBDA' "CHECK_NAME",count(*),STATUS,INST_ID from SYS_FBA_BARRIERSCN group by STATUS,INST_ID
/
select * from dba_flashback_archive_tables
/
select * from dba_flashback_archive
/
 select 'FBDA_Process' "CHECK_NAME",sid,username,program,machine,status,last_call_et from v$session where program like '%FBDA%'
/
set echo off
prompt
prompt ============================================================================================
prompt                             ++ Tablespace Alerts ++
prompt ============================================================================================
prompt
set echo on
select 'Undotbs_Alerts' "CHECK_NAME",object_name, reason from dba_outstanding_alerts where OBJECT_NAME = (SELECT UPPER(value) FROM v$parameter WHERE name = 'undo_tablespace')
/
select 'Undotbs_alert_history' "CHECK_NAME",CREATION_TIME,METRIC_VALUE, reason, suggested_action from DBA_ALERT_HISTORY where OBJECT_NAME = (SELECT UPPER(value) FROM v$parameter WHERE name = 'undo_tablespace')
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
select * from PDB_PLUG_IN_VIOLATIONS
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
