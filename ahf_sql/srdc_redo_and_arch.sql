Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_redo_and_arch.sql /main/1 2021/07/26 08:55:41 bvongray Exp $
Rem
Rem srdc_redo_and_arch.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_redo_and_arch.sql - script to collect Redo and Archivelog related diagnostic data
Rem
Rem    DESCRIPTION
Rem      script to collect Redo and Archivelog related diagnostic data
Rem
Rem    NOTES
Rem      * This script collects the data related to the Redo and Archivelog related issues
Rem                including the configuration, parameters , statistics etc
Rem                and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_redo_and_arch.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_redo_and_arch.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/22/21 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_REDO_AND_ARCH'
set long 2000000000
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
set echo off
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '      ||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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

set echo off
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
prompt
prompt ============================================================================================
prompt                     ++ Redo log and archive configurations ++
prompt ============================================================================================
prompt

set echo on
select l.thread#,
    l.group#,
    l.bytes/1024/1024 as size_MB,
    l.status, l.archived,
    lf.member 
from v$log l,v$logfile lf
where l.group# = lf.group#
order by l.thread#, l.group#;

set echo off
prompt **** v$logfile ****
set echo on
select * from v$logfile order by 1;

set echo off
prompt **** v$log ****
set echo on
select * from v$log order by 1,2;

set echo off
prompt **** v$database ****
set echo on
select * from v$database;

set echo off
prompt **** archive log list ****
set echo on
archive log list

set echo off
prompt **** archive related parameters ****
set echo on
select name,value from v$parameter where name like '%archive%' order by 1;
select OPTIMAL_LOGFILE_SIZE from v$instance_recovery;
show parameter log_buffer;
show parameter log_checkpoint_interval;
show parameter log_checkpoint_timeout;
show parameter fast_start_mttr_target;
show parameter archive_lag_target;
show parameter filesystem
show parameter disk
select name,value from v$parameter where name like '%log_archive%' and value <> 'enable';
select name from v$controlfile;
PROMPT top_redo.sql
col machine for a15
col username for a10
col redo_MB for 999G990 heading "Redo |Size MB"
column sid_serial for a13;
select b.inst_id,
       lpad((b.SID || ',' || lpad(b.serial#,5)),11) sid_serial,
       b.username,
       machine,
       b.osuser,
       b.status,
       a.redo_mb
from (select n.inst_id, sid,
             round(value/1024/1024) redo_mb
        from gv$statname n, gv$sesstat s
        where n.inst_id=s.inst_id
              and n.name = 'redo size'
              and s.statistic# = n.statistic#
        order by value desc
     ) a,
     gv$session b
where b.inst_id=a.inst_id
  and a.sid = b.sid
and   rownum <= 30;

prompt **** Amount of Redo Generation ****
select to_char(first_time,'YYYY-MON-DD') "Date", to_char(first_time,'DY') day,
to_char(sum(decode(to_char(first_time,'HH24'),'00',1,0)),'999') "00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',1,0)),'999') "01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',1,0)),'999') "02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',1,0)),'999') "03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',1,0)),'999') "04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',1,0)),'999') "05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',1,0)),'999') "06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',1,0)),'999') "07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',1,0)),'999') "08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',1,0)),'999') "09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',1,0)),'999') "10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',1,0)),'999') "11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',1,0)),'999') "12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',1,0)),'999') "13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',1,0)),'999') "14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',1,0)),'999') "15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',1,0)),'999') "16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',1,0)),'999') "17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',1,0)),'999') "18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',1,0)),'999') "19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',1,0)),'999') "20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',1,0)),'999') "21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',1,0)),'999') "22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',1,0)),'999') "23" ,
count(*) Total
from v$log_history
group by to_char(first_time,'YYYY-MON-DD'), to_char(first_time,'DY')
order by to_date(to_char(first_time,'YYYY-MON-DD'),'YYYY-MON-DD')
/
select to_char(COMPLETION_TIME,'DD/MON/YYYY') Day,
trunc(sum(blocks*block_size)/1048576/1024,2) "Size(GB)",count(sequence#) "Total Archives"
from
(select distinct sequence#,thread#,COMPLETION_TIME,blocks,block_size from v$archived_log)
group by to_char(COMPLETION_TIME,'DD/MON/YYYY')
order by to_date(to_char(COMPLETION_TIME,'DD/MON/YYYY'),'DD/MON/YYYY')
;
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
