Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/saas_db_validation.sql /main/1 2022/09/01 13:57:18 bvongray Exp $
Rem
Rem saas_db_validation.sql
Rem
Rem Copyright (c) 2022, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      saas_db_validation.sql - Database validations for FASaaS environments
Rem
Rem    DESCRIPTION
Rem      Database Healthchecks and Validations for FASaaS envornments.
Rem
Rem    NOTES
Rem      
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/saas_db_validation.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    08/16/22 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql

set lines 299
set pages 39999
set long 99999
set serveroutput on
set verify off
set feedback off
set echo off
SET MARKUP HTML ON HEAD "<title>Process Estimation</title> -
<style type='text/css'> -
body   {font:10pt  Arial,Helvetica,Geneva,sans-serif; color:#336699; background:white;} -
h1     {font:9pt;font-size:12pt; font-weight:bold; color:#336699; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} -
h2     {font:9pt;font-size:12pt; font-weight:bold; color:#336699; solid #cccc99; margin-top:0pt; margin-bottom:0pt;} -
h3     {font:10pt;font-size:10pt; font-weight:bold; color:#336699; solid #cccc99; margin-top:0pt; margin-bottom:0pt;} -
h4     {font:9pt Courier New,Courier; font-size:9pt; font-weight:bold; color:#336699; background-color:powderblue; border:1px blue; margin-top:4pt; - margin-bottom:0pt;} -
pre    {font:8pt monospace;Monaco,Courier New,Courier;} -
a      {font-size:9pt; font-weight:bold; color:#336699; margin-top:0pt; margin-bottom:0pt;} -
mark {color:#336699; background:#ffffff;  margin-top:0pt; margin-bottom:0pt;} -
table  {font-size:8pt; border_collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #336699;} -
li     {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:0px;} -
th     {font-weight:bold; color:white; background:#336699; padding-left:4px; padding-right:4px; padding-bottom:0px;} -
td     {color:black; background:#fcfcf0; vertical-align:top; border:1px solid #cccc99;} -
td.c   {text-align:center;} -
font.n {font-size:8pt; font-style:italic; color:#336699;} -
font.f {font-size:8pt; color:#999999; border-top:1px solid #cccc99; margin-top:0pt;} -
</style>" -
BODY "" -
TABLE "border='1' style='float:center' summary='Script output'" -
SPOOL ON ENTMAP OFF


column dt new_value filedt
SELECT Upper(substr(name,1,4))||'_'||to_char(sysdate,'MMDDYYYY_HH24_MI_SS') dt
                     FROM   v$active_services
                     WHERE  (
                                   goal = 'SERVICE_TIME'
                            OR     aq_ha_notification = 'YES' )
                     AND    ROWNUM = 1;


spool &filedt..html

Set escape '\'

SET MARKUP HTML ENTMAP OFF
PROMPT <H1> Table of Contents </H1>

PROMPT <a font:9pt;font-size:10pt; href="#Section1"> 1.) DB Details and DB Healthcheck </a>
    PROMPT <a font:9pt;font-size:8pt; href="#Section1.1" style="text-decoration:none"  > \&nbsp; \&nbsp; \&nbsp; \&nbsp;        1.1 Host CPU, Load, Inst CPU, Memeory info </a> 
    PROMPT <a font:9pt;font-size:8pt; href="#Section1.2" style="text-decoration:none"  > \&nbsp; \&nbsp; \&nbsp; \&nbsp;        1.2 Critical/Warnings if any observed</a> 
PROMPT <a href="#Section2"> 2.) Resources Requirement when 1 instance down and status </a>
    PROMPT  <a href="#Section2.1" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  2.1 Average active sessions count that are on CPU, IO and OTHER (eg:library cache lock, gc buffer busy acquire...etc) waits in last 5 mins</a> 
PROMPT <a href="#Section3"> 3.) UNDO, SGA, PGA Shared Server Queue Wait Time Status </a>
    PROMPT  <a href="#Section3.1" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp; 3.1 Undo Tablespace Utilization</a>
    PROMPT  <a href="#Section3.2" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  3.2 Shared Server and Avg Queue Wait time</a>
    PROMPT  <a href="#Section3.3" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  3.3 Dispatcher Usage</a>
    PROMPT  <a href="#Section3.4" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  3.4 Common Queue wait</a>
    PROMPT  <a href="#Section3.4" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  3.5 SGA Current Utilization and Errors If any    </a>
    PROMPT  <a href="#Section3.4" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  3.6 PGA Current Utilization </a> 
PROMPT <a href="#Section4"> 4.) Process and Session Details </a>
    PROMPT   <a href="#Section4.1" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.1 Process count by type and con_id    </a> 
    PROMPT <a href="#Section4.2" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.2 Sessions count by server type and con_id    </a> 
    PROMPT <a href="#Section4.3" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;   4.3 Sessions count by server type,inst_id,con_id,status    </a> 
    PROMPT <a href="#Section4.4" style="text-decoration:none">  \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.4 Sessions count by server type,program,process,inst_id,con_id,status    </a> 
    PROMPT  <a href="#Section4.5" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.5 Sessions count by server type,program,process,machine,inst_id,con_id,status    </a> 
    PROMPT <a href="#Section4.6" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.6 Session count by  user vs recursive  </a> 
    PROMPT <a href="#Section4.7" style="text-decoration:none">  \&nbsp; \&nbsp; \&nbsp; \&nbsp;  4.7 Sessions that are running in fail over mode and failover has occured </a>  
PROMPT <a href="#Section5"> 5.) Services and Running Jobs Details </a>
    PROMPT  <a href="#Section5.1" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  5.1 Database Services Info </a> 
    PROMPT <a href="#Section5.2" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  5.2 Running Scheduler Jobs ( CDB level)    </a>  
PROMPT <a href="#Section6"> 6.) INACTIVE SESSIONS Details </a>
    PROMPT  <a href="#Section6.1" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  6.1 INACTIVE SESSIONS COUNT BY HOUR FOR NQSSERVER PROGRAM </a>  
    PROMPT <a href="#Section6.2" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  6.2 INACTIVE SESSIONS COUNT MORE THAN ONE HOUR BY PROGRAM </a>  
    PROMPT  <a href="#Section6.3" style="text-decoration:none" > \&nbsp; \&nbsp; \&nbsp; \&nbsp;  6.3 TOP WAIT EVENTS WAIT > 300 SECONDS </a>  
    PROMPT <a href="#Section6.4" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  6.4 TOP SESSIONS IN LAST 30 MINUTES </a>
    PROMPT <a href="#Section6.5" style="text-decoration:none"> \&nbsp; \&nbsp; \&nbsp; \&nbsp;  6.5 TOP ESS JOBS SESSION DETAILS  IN LAST 30 MINUTES </a>    
PROMPT <a href="#Section7">  7.) ESS Jobs Current STATUS Details </a> 
PROMPT <a href="#Section8">  8.) Current Active and Inactive Session Details </a> 


PROMPT
PROMPT
PROMPT
SET MARKUP HTML ENTMAP OFF
PROMPT <a name="Section1"> <H3> <mark> 1.) DB Details and DB Healthcheck </H3> </a> 
SET MARKUP HTML ENTMAP ON

break on ID ON ID DUPLICATES

 SELECT DISTINCT *
    FROM ((
    (SELECT 1 ID,
        'Database name' NAME,
        NAME VALUE
    FROM GV$DATABASE
    )
    UNION ALL
    (SELECT 2 ID,
        'DBID' NAME,
        to_char(DBID) VALUE
    FROM GV$DATABASE
    )
    UNION ALL
    ( SELECT 3 ID, 'Instance count' NAME, TO_CHAR(COUNT(1)) FROM GV$INSTANCE
    )
    UNION ALL
    ( SELECT 4 ID,'POD NAME' NAME,Upper(name) pod_name
                        FROM   v$active_services
                        WHERE  (
                                    goal = 'SERVICE_TIME'
                                OR     aq_ha_notification = 'YES' )
                        AND    ROWNUM = 1
    )
    UNION ALL
    (SELECT 5 ID,
        'DB SHAPE as per SGA' NAME,
        val
    FROM
        (SELECT CASE
                    WHEN round(value/1024/1024/1024) >= 192 THEN 'LARGE'
                    WHEN round(value/1024/1024/1024) BETWEEN 42 AND    192 THEN 'MEDIUM'
                    WHEN round(value/1024/1024/1024) BETWEEN 22 AND    41 THEN 'SMALL'
                    ELSE 'XSMALL'
                END val
            FROM   v$parameter
            WHERE  name = 'sga_target'
        )
    WHERE rownum=1
    )  
    UNION ALL
    (SELECT 6 ID,
        'DB PATCHSET' NAME,
        Action
    FROM
        (SELECT description
        ||' --- '
        || ACTION_TIME Action
        FROM cdb_registry_sqlpatch
        WHERE description IS NOT NULL
        ORDER BY ACTION_TIME DESC
        )
    WHERE rownum=1
    )
    UNION ALL
    (SELECT 7 ID,
        'CPUs' NAME,
        TO_CHAR(VALUE) VALUE
    FROM GV$OSSTAT
    WHERE STAT_NAME = 'NUM_CPUS'
    )
    UNION ALL
    (SELECT 8 ID,
        'CPU cores' NAME,
        TO_CHAR(VALUE) VALUE
    FROM GV$OSSTAT
    WHERE STAT_NAME = 'NUM_CPU_CORES'
    )
    UNION ALL
    (SELECT 9 ID,
        'SGA_TARGET(GB)' NAME,
        TO_CHAR(ROUND(VALUE / 1024 / 1024 / 1024, 2)) VALUE
    FROM V$parameter
    WHERE upper(name)='SGA_TARGET'
    )
    UNION ALL
    (SELECT 10 ID,
        'Blocking Sessions waiting >300sec' NAME,
        to_char(COUNT(1))  VALUE
    FROM gv$session
    WHERE blocking_session_status = 'VALID'
    AND seconds_in_wait>300
    ) 
    UNION ALL
    (SELECT 11 ID,
        'Physical memory (GB)' NAME,
        TO_CHAR(ROUND(VALUE / 1024 / 1024 / 1024, 2)) VALUE
    FROM GV$OSSTAT
    WHERE STAT_NAME = 'PHYSICAL_MEMORY_BYTES'
    )
    ))
    ORDER BY 1;

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section1.1"></a> <mark>  1.1 Host CPU, Load, Inst CPU, Memeory info </span> </H3> 

SET MARKUP HTML ENTMAP ON


with sysm as
(
SELECT inst_id, metric_name, round(avg(value)) average, round(max(value)) maxval, max(end_time) end_time
  FROM gV$SYSMETRIC_history h
 WHERE metric_name IN ('Host CPU Usage Per Sec', 'Host CPU Utilization (%)',     -- Host vs OSStat
                      'CPU Usage Per Sec', 'Background CPU Usage Per Sec',     -- database -> vs time_model
                      'Current OS Load','Average Active Sessions'
                     )
   AND begin_time > sysdate - (15/(24*60))
   AND group_id = 2
 GROUP BY metric_name, inst_id
)
, inst as (select instance_number, instance_name, host_name, version_full from gv$instance)
, pod as (select name pod_name from v$active_services s where s.name like '%fb' and rownum=1)
, mem as (select INST_ID ,STAT_NAME,round(VALUE/1024/1024/1024,2) Val_GB from gv$osstat where stat_name in ('SWAP_FREE_BYTES','FREE_MEMORY_BYTES') )
, podsize as
(
SELECT CASE
         WHEN value >= 72 THEN 'L'
         WHEN value >= 40 THEN 'M'
         WHEN value >= 18 THEN 'S'
         ELSE 'XS'
       END pod_size
  FROM   v$parameter
 WHERE  name = 'cpu_count'
)
SELECT
        sysm.inst_id,
        inst.host_name,
        inst.version_full,
        trunc(max(end_time), 'mi')  end_time,
        max(case when STAT_NAME = 'SWAP_FREE_BYTES' then round(Val_GB,2) else 0 end) AS SWAP_FREE_GB,
        max(case when STAT_NAME = 'FREE_MEMORY_BYTES' then round(Val_GB,2) else 0 end) AS FREE_MEM_GB,
        max(case when metric_name = 'Current OS Load' then round(maxval,2) else 0 end) AS os_load,
        max(case when metric_name = 'Host CPU Utilization (%)' then round(maxval,2) else 0 end) AS host_cpu_util,
        max(case when metric_name = 'Host CPU Usage Per Sec' then round(maxval/100,2) else 0 end) AS host_cpu_db,
        max(case when metric_name = 'CPU Usage Per Sec' then round(maxval/100,2) else 0 end) as db_fg_cpu,
        max(case when metric_name = 'Background CPU Usage Per Sec' then round(maxval/100,2) else 0 end) as db_bg_cpu,
        max(case when metric_name = 'Average Active Sessions' then round(maxval,2) else 0 end) as db_aas,
        round(100*
              (max(case when metric_name = 'CPU Usage Per Sec' then round(maxval/100,2) else 0 end) +
               max(case when metric_name = 'Background CPU Usage Per Sec' then round(maxval/100,2) else 0 end)
              )/(max(case when metric_name = 'Host CPU Usage Per Sec' then round(maxval/100,2) else 0 end))
              , 2) "hostCPUUtl%_thisDB"
   FROM sysm, pod, podsize, inst,mem
  WHERE 1=1
    and inst.instance_number = sysm.inst_id
    and mem.inst_id=sysm.inst_id
 group by sysm.inst_id, inst.host_name, inst.version_full;




CREATE GLOBAL TEMPORARY TABLE PSR_DATA_COLL (
  INST_ID           NUMBER,
  parameter  VARCHAR2(30),
  limit number,
  exp_cnt number,
  status varchar2(30),
  curr_util number,
  otherinst_util number
) ON COMMIT PRESERVE ROWS;

DECLARE
TYPE res_det IS RECORD
(
inst_id number,
proc number,
proc_bg number,
proc_ded number,
proc_limit number,
sess number,
sess_recur number,
sess_limit number,
sess_shared number,
sess_none number,
sess_ded number,
sess_bg number,
ss number,
ss_limit number,
ss_usage number,
ss_othusage number,
jq number,
jq_limit number,
jq_othmax number,
pq number,
pq_limit number,
pq_othmax number,
max_otherded number,
max_otherss number,
max_othersess number,
max_otherjoq number,
max_otherpx number,
expected_processes number,
expected_sessions number,
expected_ss number,
expected_jq number,
expected_pq number,
expected_processes_status varchar2(20),
expected_session_status varchar2(20),
expected_ss_status varchar2(20),
expected_joq_status varchar2(20),
expected_px_status varchar2(20)
);

TYPE res_det_tbl IS TABLE OF res_det; res_usage res_det_tbl:= res_det_tbl();
i integer :=1;
inst_cnt number :=0;
est_proc number :=0;
proc_buffer number := 0;
est_sess number := 0;
sess_buffer number :=0;
min_inst_id number:=1;
min_inst_id_temp number:=1;
max_inst_id number:=2;


begin

 select count(inst_id),min(inst_id),max(inst_id) into inst_cnt,min_inst_id,max_inst_id from gv$instance;

min_inst_id_temp:=min_inst_id;

for i in 1..inst_cnt
loop
res_usage.extend;
select current_utilization,limit_value into res_usage(min_inst_id).sess,res_usage(min_inst_id).sess_limit from gv$resource_limit where inst_id=min_inst_id and resource_name='sessions';
select current_utilization,limit_value  into res_usage(min_inst_id).proc,res_usage(min_inst_id).proc_limit from gv$resource_limit where inst_id=min_inst_id and resource_name='processes';
select current_utilization,limit_value  into res_usage(min_inst_id).ss,res_usage(min_inst_id).ss_limit from gv$resource_limit where inst_id=min_inst_id and resource_name='max_shared_servers';
select current_utilization into res_usage(min_inst_id).pq from gv$resource_limit where inst_id=min_inst_id and resource_name='parallel_max_servers';
select count(*) into res_usage(min_inst_id).jq from cdb_scheduler_running_jobs;
select count(1) into res_usage(min_inst_id).proc_bg from gv$process where BACKGROUND=1 AND inst_id=min_inst_id;
select count(1) into res_usage(min_inst_id).proc_ded from gv$session WHERE type='USER' and server='DEDICATED' AND inst_id=min_inst_id;
select sum(recursive_session_count) into res_usage(min_inst_id).sess_recur from gv$sessions_count where inst_id=min_inst_id;
select count(1) into res_usage(min_inst_id).sess_shared from gv$session WHERE server='SHARED' AND inst_id=min_inst_id;
select count(1) into res_usage(min_inst_id).sess_none from gv$session WHERE server='NONE' AND inst_id=min_inst_id;
select count(1) into res_usage(min_inst_id).sess_ded from gv$session WHERE type='USER' and server='DEDICATED' AND inst_id=min_inst_id;
select count(1) into res_usage(min_inst_id).sess_bg from gv$session WHERE type='BACKGROUND' AND inst_id=min_inst_id;
select max(cnt) into res_usage(min_inst_id).max_otherded  from ( select inst_id,count(1) cnt from gv$session WHERE type='USER' and server='DEDICATED' AND inst_id!=min_inst_id group by inst_id);
select max(cnt) into res_usage(min_inst_id).max_otherss from ( select inst_id,current_utilization cnt from gv$resource_limit WHERE resource_name='max_shared_servers' AND inst_id!=min_inst_id );
select max(cnt) into res_usage(min_inst_id).max_othersess  from ( select inst_id,count(1) cnt from gv$session WHERE type='USER' AND inst_id!=min_inst_id group by inst_id);

select nvl(count(*),0) into res_usage(min_inst_id).ss_usage from gv$shared_server where inst_id=min_inst_id and status='EXEC';
select nvl(max(cnt),0) into res_usage(min_inst_id).ss_othusage from ( select inst_id,nvl(count(*),0) cnt from gv$shared_server WHERE inst_id!=min_inst_id and status='EXEC' group by inst_id );


select value into res_usage(min_inst_id).jq_limit from gv$parameter where name='job_queue_processes' and inst_id=min_inst_id;
select nvl(count(*),0) into res_usage(min_inst_id).jq from cdb_scheduler_running_jobs where RUNNING_INSTANCE=min_inst_id;
select nvl(max(cnt),0) into res_usage(min_inst_id).jq_othmax from (select RUNNING_INSTANCE,nvl(count(*),0) cnt from cdb_scheduler_running_jobs 
where RUNNING_INSTANCE!=min_inst_id group by RUNNING_INSTANCE);

select value into res_usage(min_inst_id).pq_limit from gv$parameter where name='parallel_max_servers' and inst_id=min_inst_id;
select nvl(count(*),0) into res_usage(min_inst_id).pq from GV$PX_PROCESS where status='IN USE' and IS_GV='FALSE' and inst_id=min_inst_id;
select nvl(max(cnt),0) into res_usage(min_inst_id).pq_othmax from (select inst_id,nvl(count(*),0) cnt from GV$PX_PROCESS where status='IN USE' and IS_GV='FALSE' and inst_id!=min_inst_id group by inst_id);

min_inst_id:=min_inst_id+1;
end loop;

min_inst_id:=min_inst_id_temp;

for i in 1..inst_cnt
loop

res_usage(min_inst_id).expected_processes:=res_usage(min_inst_id).proc + res_usage(min_inst_id).max_otherded + res_usage(min_inst_id).pq_othmax + res_usage(min_inst_id).jq_othmax;
res_usage(min_inst_id).expected_sessions:=res_usage(min_inst_id).sess +  res_usage(min_inst_id).max_othersess;
res_usage(min_inst_id).expected_jq:=res_usage(min_inst_id).jq+res_usage(min_inst_id).jq_othmax;
res_usage(min_inst_id).expected_pq:=res_usage(min_inst_id).pq+res_usage(min_inst_id).pq_othmax;

res_usage(min_inst_id).expected_ss:=res_usage(min_inst_id).ss_usage +  res_usage(min_inst_id).ss_othusage;


IF round((res_usage(min_inst_id).expected_processes*100/res_usage(min_inst_id).proc_limit),2) >= 90 THEN
res_usage(min_inst_id).expected_processes_status:='CRITICAL';
ELSIF round((res_usage(min_inst_id).expected_processes*100/res_usage(min_inst_id).proc_limit),2) >=70 and round((res_usage(min_inst_id).expected_processes*100/res_usage(min_inst_id).proc_limit),2) <90 THEN
res_usage(min_inst_id).expected_processes_status:='WARNING';
ELSE
res_usage(min_inst_id).expected_processes_status:='GOOD';
END IF;


insert into PSR_DATA_COLL values(min_inst_id,'PROCESSES',res_usage(min_inst_id).proc_limit,res_usage(min_inst_id).expected_processes,res_usage(min_inst_id).expected_processes_status,res_usage(min_inst_id).proc,res_usage(min_inst_id).max_otherded);
commit;


IF round((res_usage(min_inst_id).expected_sessions*100/res_usage(min_inst_id).sess_limit),2) >= 90 THEN
res_usage(min_inst_id).expected_session_status:='CRITICAL';
ELSIF round((res_usage(min_inst_id).expected_sessions*100/res_usage(min_inst_id).sess_limit),2) >=70 and round((res_usage(min_inst_id).expected_processes*100/res_usage(min_inst_id).proc_limit),2) <90 THEN
res_usage(min_inst_id).expected_session_status:='WARNING';
ELSE
res_usage(min_inst_id).expected_session_status:='GOOD';
END IF;

insert into PSR_DATA_COLL values(min_inst_id,'SESSIONS',res_usage(min_inst_id).sess_limit,res_usage(min_inst_id).expected_sessions,res_usage(min_inst_id).expected_session_status,res_usage(min_inst_id).sess,res_usage(min_inst_id).max_othersess);
commit;


IF round((res_usage(min_inst_id).expected_ss*100/res_usage(min_inst_id).ss_limit),2) >= 90 and res_usage(min_inst_id).ss_limit>1 THEN
res_usage(min_inst_id).expected_ss_status:='CRITICAL';
ELSIF round((res_usage(min_inst_id).expected_ss*100/res_usage(min_inst_id).ss_limit),2) >=70 and round((res_usage(min_inst_id).expected_ss*100/res_usage(min_inst_id).ss_limit),2) <90 and res_usage(min_inst_id).ss_limit>1 THEN
res_usage(min_inst_id).expected_ss_status:='WARNING';
ELSE
res_usage(min_inst_id).expected_ss_status:='GOOD';
END IF;

insert into PSR_DATA_COLL values(min_inst_id,'SHARED SERVER',res_usage(min_inst_id).ss_limit,res_usage(min_inst_id).expected_ss,res_usage(min_inst_id).expected_ss_status,res_usage(min_inst_id).ss_usage,res_usage(min_inst_id).ss_othusage);
commit;

IF round(((res_usage(min_inst_id).jq+res_usage(min_inst_id).jq_othmax)*100/res_usage(min_inst_id).jq_limit),2) >= 90 THEN
res_usage(min_inst_id).expected_joq_status:='CRITICAL';
ELSIF round(((res_usage(min_inst_id).jq+res_usage(min_inst_id).jq_othmax)*100/res_usage(min_inst_id).jq_limit),2) >= 70 and round(((res_usage(min_inst_id).jq+res_usage(min_inst_id).jq_othmax)*100/res_usage(min_inst_id).jq_limit),2) <90 THEN
res_usage(min_inst_id).expected_joq_status:='WARNING';
ELSE
res_usage(min_inst_id).expected_joq_status:='GOOD';
END IF;


insert into PSR_DATA_COLL values(min_inst_id,'JOB QUEUE UTILIZATION',res_usage(min_inst_id).jq_limit,res_usage(min_inst_id).expected_jq,res_usage(min_inst_id).expected_joq_status,res_usage(min_inst_id).jq,res_usage(min_inst_id).jq_othmax);
commit;

IF round(((res_usage(min_inst_id).pq+res_usage(min_inst_id).pq_othmax)*100/res_usage(min_inst_id).pq_limit),2) >= 90 THEN
res_usage(min_inst_id).expected_px_status:='CRITICAL';
ELSIF round(((res_usage(min_inst_id).pq+res_usage(min_inst_id).pq_othmax)*100/res_usage(min_inst_id).pq_limit),2) >= 70 and round(((res_usage(min_inst_id).pq+res_usage(min_inst_id).pq_othmax)*100/res_usage(min_inst_id).pq_limit),2) <90 THEN
res_usage(min_inst_id).expected_px_status:='WARNING';
ELSE
res_usage(min_inst_id).expected_px_status:='GOOD';
END IF;

insert into PSR_DATA_COLL values(min_inst_id,'PARALLEL SERVER',res_usage(min_inst_id).pq_limit,res_usage(min_inst_id).expected_pq,res_usage(min_inst_id).expected_px_status,res_usage(min_inst_id).pq,res_usage(min_inst_id).pq_othmax);
commit;


min_inst_id:=min_inst_id+1;
end loop;


end;
/

/* INSERT INTO PSR_DATA_COLL 
SELECT INST_ID,'DBHEALTHCHECK',ROUND((AVG(aas_total)*100)/MAX(value),2) aas_total,
	ROUND((AVG(aas_Other)*100)/MAX(value),2) aas_other_pct,
		CASE
			WHEN ROUND((AVG(aas_Other)*100)/MAX(value),2) >= 60 THEN 'DB HEALTH CRITICAL'
            WHEN ROUND((AVG(aas_Other)*100)/MAX(value),2) <= 40 and ROUND((AVG(aas_Other)*100)/MAX(value),2) >= 30 THEN 'DB HEALTH WARNING'
            ELSE 'GOOD'
        END DBHEALTH,
 ROUND((AVG(aas_on_cpu)*100)/MAX(value),2) aas_cpu_pct,
    ROUND((AVG(aas_UserIO)*100)/MAX(value),2) aas_io_pct
  FROM
    (SELECT INST_ID,sample_time ,
      COUNT(*) aas_total ,
      SUM(
      CASE
        WHEN session_state = 'ON CPU'
        THEN 1
        ELSE 0
      END) aas_on_cpu ,
      SUM(
      CASE
        WHEN session_state = 'WAITING'
        AND wait_class  not in ('User I/O','System I/O','ON CPU')
        THEN 1
        ELSE 0
      END) aas_Other ,
      SUM(
      CASE
        WHEN session_state = 'WAITING'
        AND wait_class     in ('User I/O','System I/O')
        THEN 1
        ELSE 0
      END) aas_UserIO 
    FROM gv$active_session_history ash
    WHERE sample_time > systimestamp - interval '5' minute
    AND session_type  ='FOREGROUND'
    GROUP BY sample_time,INST_ID
    ) t_ash,
    (SELECT value FROM v$parameter WHERE name='cpu_count'
    ) t_param
	group by inst_id;
	
commit;

*/



SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section1.2"></a> <mark> 1.2 Critical/Warnings if any observed </span> </H3> 

SET MARKUP HTML ENTMAP ON

select INST_ID,PARAMETER,STATUS from PSR_DATA_COLL where STATUS!='GOOD';

SET MARKUP HTML ENTMAP OFF

Prompt
Prompt
SET MARKUP HTML ENTMAP OFF
PROMPT <a name="Section2"></a> <H3> <mark>  2.) Resources Requirement when 1 instance down and status </H3>
set head on

SET MARKUP HTML ENTMAP ON

select INST_ID,PARAMETER,LIMIT,CURR_UTIL,OTHERINST_UTIL,EXP_CNT "EXPECTED CNT",STATUS from PSR_DATA_COLL;


SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section2.1"></a> <mark>   Average active sessions count that are on CPU, IO and OTHER (eg:library cache lock, gc buffer busy acquire...etc) waits in last 5 mins </span> </H3> 

SET MARKUP HTML ENTMAP ON

SELECT INST_ID,ROUND((AVG(aas_on_cpu)*100)/MAX(value),2) aas_cpu_pct,
    ROUND((AVG(aas_UserIO)*100)/MAX(value),2) aas_io_pct,
	    ROUND((AVG(aas_Other)*100)/MAX(value),2) aas_other_pct,
		CASE
			WHEN ROUND((AVG(aas_Other)*100)/MAX(value),2) >= 60 THEN 'DB HEALTH CRITICAL'
            WHEN ROUND((AVG(aas_Other)*100)/MAX(value),2) < 60 and ROUND((AVG(aas_Other)*100)/MAX(value),2) >= 30 THEN 'DB HEALTH WARNING'
            ELSE 'GOOD'
        END DBHEALTH 
  FROM
    (SELECT INST_ID,sample_time ,
      COUNT(*) aas_total ,
      SUM(
      CASE
        WHEN session_state = 'ON CPU'
        THEN 1
        ELSE 0
      END) aas_on_cpu ,
      SUM(
      CASE
        WHEN session_state = 'WAITING'
        AND wait_class  not in ('User I/O','System I/O','ON CPU')
        THEN 1
        ELSE 0
      END) aas_Other ,
      SUM(
      CASE
        WHEN session_state = 'WAITING'
        AND wait_class     in ('User I/O','System I/O')
        THEN 1
        ELSE 0
      END) aas_UserIO 
    FROM gv$active_session_history ash
    WHERE sample_time > systimestamp - interval '5' minute
    AND session_type  ='FOREGROUND'
    GROUP BY sample_time,INST_ID
    ) t_ash,
    (SELECT value FROM v$parameter WHERE name='cpu_count'
    ) t_param
	group by inst_id;

truncate table PSR_DATA_COLL;
DROP TABLE PSR_DATA_COLL;

SET MARKUP HTML ENTMAP OFF

Prompt
SET MARKUP HTML ENTMAP OFF
PROMPT <a name="Section3"></a> <H3> <mark>  3.) UNDO, SGA, PGA Shared Server Queue Wait Time Status </H3>
set head on

PROMPT <H3> <a name="Section3.1"></a> <mark>   Undo Tablespace Utilization </span> </H3> 

SET MARKUP HTML ENTMAP ON

SELECT ( tuneundoretention - max_query_len ) tuneret_alert_if_lessthan_0,
  ( tablespace_size_gb     - estimated_gb ) space_alert_if_lessthan_0,
  round(( tuneundoretention *100)/undo_retention,2) TUNED_UNDO_PCT,
  undo_tablespace,
  undo_retention,
  highthreshold_undoretention,
  tablespace_size_gb,
  TABLESPACE_FREE_GB,
  free_PCT,
  estimated_gb
FROM
  (SELECT undo_tablespace,
    undo_retention,
    (SELECT value
    FROM v$parameter
    WHERE lower(name) = '_highthreshold_undoretention'
    ) highthreshold_undoretention,
    max_tuned_retention tuneundoretention,
    max_query_len,
    (SELECT ROUND(m.tablespace_size * t.block_size / 1024 / 1024 / 1024, 2) tbs_size_gb
    FROM dba_tablespace_usage_metrics m,
      dba_tablespaces t
    WHERE m.tablespace_name = undo_tablespace
    AND t.tablespace_name   = m.tablespace_name
    ) TABLESPACE_SIZE_GB,
    (SELECT ROUND((m.tablespace_size - m.used_space) * t.block_size/1024/1024/1024,2) free_size_gb
    FROM dba_tablespace_usage_metrics m,
      dba_tablespaces t
    WHERE m.tablespace_name = undo_tablespace
    AND t.tablespace_name   = m.tablespace_name
    ) TABLESPACE_FREE_GB,
    (SELECT ROUND(100-used_percent,2) free_PCT
    FROM dba_tablespace_usage_metrics
    WHERE tablespace_name = undo_tablespace
    ) free_PCT,
    ROUND(((total_blks *(blk_size) / duration_sec) *(NVL(max_tuned_retention, undo_retention)) * 1.3 / 1024 / 1024 / 1024 ), 2) estimated_gb
  FROM
    (SELECT
      ( SELECT DISTINCT name
      FROM v$tablespace
      WHERE ts#   = undotsn
      AND con_id IN ( 0, 1 )
      ) undo_tablespace,
      ( SELECT value FROM v$parameter WHERE lower(name) = 'db_block_size'
      ) blk_size,
      SUM((end_time - begin_time) * 86400) duration_sec,
      SUM(undoblks) total_blks,
      MAX(tuned_undoretention) max_tuned_retention,
      MAX(maxquerylen) max_query_len,
      ( SELECT value FROM v$parameter WHERE lower(name) = 'undo_retention'
      ) undo_retention
    FROM v$undostat
    GROUP BY undotsn
    )
  );



PROMPT
PROMPT
PROMPT

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section3.2"></a> <mark>   Shared Server and Avg Queue Wait time </span> </H3> 

SET MARKUP HTML ENTMAP ON



SELECT inst_id,MAXIMUM_CONNECTIONS "MAX CONN", MAXIMUM_SESSIONS "MAX SESS", SERVERS_STARTED "STARTED", SERVERS_TERMINATED "TERMINATED",
SERVERS_HIGHWATER "HIGHWATER" FROM GV$SHARED_SERVER_MONITOR order by inst_id;

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section3.3"></a> <mark>   Dispatcher Usage  </span> </H3> 

SET MARKUP HTML ENTMAP ON


SELECT INST_ID,NAME "NAME", SUBSTR(NETWORK,1,23) "PROTOCOL", OWNED,STATUS "STATUS", ROUND((BUSY/(BUSY + IDLE)) * 100,2) "%TIME BUSY" FROM GV$DISPATCHER ORDER BY INST_ID;

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section3.4"></a> <mark>   Common Queue wait  </span> </H3> 

SET MARKUP HTML ENTMAP ON



SELECT inst_id,
       Round(Avg(Decode(totalq, 0, 0,
                                ( wait / totalq ) / 100)), 5) AVG_QUE_WAIT
FROM   gv$queue Q
WHERE  type = 'COMMON'
GROUP  BY inst_id
ORDER  BY inst_id; 


SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section3.5"></a> <mark>   SGA Current Utilization and Errors If any  </span> </H3> 

SET MARKUP HTML ENTMAP ON


select inst_id,COMPONENT,round(CURRENT_SIZE/1024/1024/1024,2) CUR_SZ_GB,round(USER_SPECIFIED_SIZE/1024/1024/1024,2) USRSP_SZ_GB,OPER_COUNT,LAST_OPER_TYPE,LAST_OPER_MODE,LAST_OPER_TIME,GRANULE_SIZE/1024/1024 GRAN_SZ_MB,CON_ID
from gv$memory_dynamic_components
where CURRENT_SIZE>0
order by 1,2; 

select * from gv$sga_current_resize_ops ;


SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section3.6"></a> <mark>   PGA Current Utilization  </span> </H3> 

SET MARKUP HTML ENTMAP ON


SELECT  inst_id, 
round(sum(pga_max_mem)/1024/1024/1024,2)      pga_max_mem,
            round(sum(pga_alloc_mem)/1024/1024/1024,2)    pga_alloc_mem,
            round(sum(pga_used_mem)/1024/1024/1024,2) pga_used_mem,
            round(sum(pga_freeable_mem)/1024/1024/1024,2) pga_freeable_mem,
            (SELECT round(value/1024/1024/1024,2) 
    FROM v$parameter
    WHERE lower(name) = 'pga_aggregate_limit')   pga_aggregate_limit
FROM GV$PROCESS p
group by inst_id
order by 1;



SET MARKUP HTML ENTMAP OFF
PROMPT <a name="Section4"></a> <H3> <mark>  4.) Process and Session Details </H3>
SET MARKUP HTML ENTMAP ON

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section4.1"></a> <mark>   Process count by type and con_id  </span> </H3> 

SET MARKUP HTML ENTMAP ON


break on inst_id skip 0
compute sum of cnt on inst_id
col background for a20
select inst_id, con_id,count(*) cnt ,background from gv$process group by inst_id, con_id,background order by inst_id,con_id,background;

SET MARKUP HTML ENTMAP OFF

PROMPT <H3> <a name="Section4.2"></a> <mark>   Sessions count by server type and con_id  </span> </H3> 

SET MARKUP HTML ENTMAP ON


select inst_id, con_id,  server,count(*) cnt ,type from gv$session
group by inst_id, con_id, server,type
order by inst_id, con_id, server,type;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section4.3"></a> <mark>   Sessions count by server type,inst_id,con_id,status </span> </H3> 
SET MARKUP HTML ENTMAP ON



select inst_id, con_id,  server,count(*) cnt ,type,status from gv$session
group by inst_id, con_id, server,type,status
order by inst_id, con_id, server,type,status;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section4.4"></a> <mark>   Sessions count by server type,program,process,inst_id,con_id,status </span> </H3> 
SET MARKUP HTML ENTMAP ON

break on con_id skip 1
compute sum of cnt on con_id
select inst_id, con_id,  server,program, process, count(*) cnt from gv$session where type='USER'
group by inst_id, con_id, server,program,process
order by inst_id, con_id, server,program,process;


SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section4.5"></a> <mark>   Sessions count by server type,program,process,machine,inst_id,con_id,status </span> </H3> 
SET MARKUP HTML ENTMAP ON


break on con_id skip 1
compute sum of cnt on con_id
select inst_id, con_id,  server,program, process,machine, count(*) cnt from gv$session where type='USER'
group by inst_id, con_id, server,program,process,machine
order by inst_id, con_id, server,program,process;

break on off
-- session count by  user vs recursive


SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section4.6"></a> <mark>   Session count by  user vs recursive </span> </H3> 
SET MARKUP HTML ENTMAP ON


select inst_id,con_id ,USER_SESSION_COUNT,recursive_session_count from gv$sessions_count group by inst_id,con_id,USER_SESSION_COUNT,recursive_session_count order by inst_id,con_id,USER_SESSION_COUNT,recursive_session_count;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section4.7"></a> <mark>   Sessions that are running in fail over mode and failover has occured </span> </H3> 
SET MARKUP HTML ENTMAP ON


select * from v$session where failed_over='YES' order by inst_id,con_id
break on off

SET MARKUP HTML ENTMAP OFF
PROMPT <a name="Section5"></a> <H3> <mark>  5.) Services Info and DBA scheduler running Jobs Details </H3>
set head on

SET MARKUP HTML ENTMAP ON

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section5.1"></a> <mark>   Database Services Info  </span> </H3> 
SET MARKUP HTML ENTMAP ON


select name,pdb,failover_method,failover_type,failover_retries,failover_delay,goal,clb_goal from cdb_services;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section5.2"></a> <mark>   Running Scheduler Jobs ( CDB level) </span> </H3> 
SET MARKUP HTML ENTMAP ON

select running_instance,con_id,owner,job_name,job_subname,session_id,SLAVE_OS_PROCESS_ID,resource_consumer_group,elapsed_time,cpu_used from cdb_scheduler_running_jobs order by running_instance,con_id;

SET MARKUP HTML ENTMAP OFF

PROMPT <a name="Section6"></a> <H3> <mark>  6.) INACTIVE SESSIONS Details </H3>
set head on

SET MARKUP HTML ENTMAP ON

SELECT to_char(sysdate,'DD-Mon-YYYY') Current_Date,inst_id,COUNT(1) total,  
  (SELECT COUNT(1) INACTIVE_1HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
 and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >1
 and inst_id=s.inst_id
  ) INACTIVE_1HR_OLD,
  (SELECT COUNT(1) INACTIVE_2HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >2
  and inst_id=s.inst_id
  ) INACTIVE_2HR_OLD,
  (SELECT COUNT(1) INACTIVE_3HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >3
  and inst_id=s.inst_id
  ) INACTIVE_3HR_OLD,
  (SELECT COUNT(1) INACTIVE_4HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
  and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >4
  and inst_id=s.inst_id
  ) INACTIVE_4HR_OLD,
(SELECT COUNT(1) INACTIVE_5HR_OLD
  FROM gv$session
  WHERE 1=1
   and state='WAITING' and type='USER'
   and status='INACTIVE'
  AND ROUND(LAST_CALL_ET/60/60,2) >5
  and inst_id=s.inst_id
  ) INACTIVE_5HR_OLD,
  (SELECT COUNT(1) INACTIVE_6HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >6
  and inst_id=s.inst_id
  ) INACTIVE_6HR_OLD,
  (SELECT COUNT(1) INACTIVE_7HR_OLD
  FROM gv$session
  WHERE 1=1
   and state='WAITING' and type='USER'
   and status='INACTIVE'
  AND ROUND(LAST_CALL_ET/60/60,2) >7
  and inst_id=s.inst_id
  ) INACTIVE_7HR_OLD,
  (SELECT COUNT(1) INACTIVE_8HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >8
  and inst_id=s.inst_id
  ) INACTIVE_8HR_OLD,
(SELECT COUNT(1) INACTIVE_9HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'
 AND state='WAITING'
AND ROUND(LAST_CALL_ET/60/60,2) >9
 and inst_id=s.inst_id
  ) INACTIVE_9HR_OLD,
  (SELECT COUNT(1) INACTIVE_10HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'
 AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >10
  and inst_id=s.inst_id
  ) INACTIVE_10HR_OLD,
  (SELECT COUNT(1) INACTIVE_11HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >11
  and inst_id=s.inst_id
  ) INACTIVE_11HR_OLD,
  (SELECT COUNT(1) INACTIVE_12HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >12
  and inst_id=s.inst_id
  ) INACTIVE_12HR_OLD
FROM gv$session s where type='USER' and status='INACTIVE'
group by s.inst_id
order by s.inst_id;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section6.1"></a> <mark>   Inactive Sessions Count By Hour For NQSERVER PROGRAM </span> </H3> 
SET MARKUP HTML ENTMAP ON



SELECT to_char(sysdate,'DD-Mon-YYYY') Current_Date,'nqsserver', inst_id,COUNT(1) total,  
  (SELECT COUNT(1) INACTIVE_1HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'
 and state='WAITING' and program like '%nqsserver%'
  AND ROUND(LAST_CALL_ET/60/60,2) >1
 and inst_id=s.inst_id
  ) INACTIVE_1HR_OLD,
  (SELECT COUNT(1) INACTIVE_2HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'  and program like '%nqsserver%'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >2
  and inst_id=s.inst_id
  ) INACTIVE_2HR_OLD,
  (SELECT COUNT(1) INACTIVE_3HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'  and program like '%nqsserver%'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >3
  and inst_id=s.inst_id
  ) INACTIVE_3HR_OLD,
  (SELECT COUNT(1) INACTIVE_4HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'  and program like '%nqsserver%'
  and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >4
  and inst_id=s.inst_id
  ) INACTIVE_4HR_OLD,
(SELECT COUNT(1) INACTIVE_5HR_OLD
  FROM gv$session
  WHERE 1=1
   and state='WAITING' and type='USER'  and program like '%nqsserver%'
   and status='INACTIVE'
  AND ROUND(LAST_CALL_ET/60/60,2) >5
  and inst_id=s.inst_id
  ) INACTIVE_5HR_OLD,
  (SELECT COUNT(1) INACTIVE_6HR_OLD
  FROM gv$session
  WHERE 1=1
  and type='USER' and status='INACTIVE'  and program like '%nqsserver%'
   and state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >6
  and inst_id=s.inst_id
  ) INACTIVE_6HR_OLD,
  (SELECT COUNT(1) INACTIVE_7HR_OLD
  FROM gv$session
  WHERE 1=1
   and state='WAITING' and type='USER'  and program like '%nqsserver%'
   and status='INACTIVE'
  AND ROUND(LAST_CALL_ET/60/60,2) >7
  and inst_id=s.inst_id
  ) INACTIVE_7HR_OLD,
  (SELECT COUNT(1) INACTIVE_8HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'  and program like '%nqsserver%'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >8
  and inst_id=s.inst_id
  ) INACTIVE_8HR_OLD,
(SELECT COUNT(1) INACTIVE_9HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'  and program like '%nqsserver%'
 AND state='WAITING'
AND ROUND(LAST_CALL_ET/60/60,2) >9
 and inst_id=s.inst_id
  ) INACTIVE_9HR_OLD,
  (SELECT COUNT(1) INACTIVE_10HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'  and program like '%nqsserver%'
 AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >10
  and inst_id=s.inst_id
  ) INACTIVE_10HR_OLD,
  (SELECT COUNT(1) INACTIVE_11HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'  and program like '%nqsserver%'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >11
  and inst_id=s.inst_id
  ) INACTIVE_11HR_OLD,
  (SELECT COUNT(1) INACTIVE_12HR_OLD
  FROM gv$session
  WHERE 1=1
  AND type='USER' and status='INACTIVE'  and program like '%nqsserver%'
  AND state='WAITING'
  AND ROUND(LAST_CALL_ET/60/60,2) >12
  and inst_id=s.inst_id
  ) INACTIVE_12HR_OLD
FROM gv$session s where type='USER' and status='INACTIVE'  and program like '%nqsserver%'
group by s.inst_id
order by s.inst_id;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section6.2"></a> <mark>   Inactive Sessions Count more than one Hour by PROGRAM  </H3> 
SET MARKUP HTML ENTMAP ON


select count(*), inst_id,program,service_name
from gv$session
where 1=1
and type='USER' and status='INACTIVE'
and state='WAITING'
AND ROUND(LAST_CALL_ET/60/60,2) >1
group by inst_id,program,service_name;

SET MARKUP HTML ENTMAP OFF



select lower(name) DB_NAME from v$database;
col p_name  new_value p_name print format a30
SELECT NAME p_name FROM V$CONTAINERS where NAME like'%_F';
alter session set container=&p_name;

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section6.3"></a> <mark>   TOP WAIT EVENTS WAIT > 300 SECONDS  </H3> 
SET MARKUP HTML ENTMAP ON


select sid||','||serial#||',@'||inst_id "sid_ser_instid" ,p1||':'||p2||':'||p3 ,FINAL_BLOCKING_INSTANCE,FINAL_BLOCKING_SESSION,seq#,state,status,process,module,program,sql_id,SQL_EXEC_START,round(WAIT_TIME_MICRO/1e6,6) wait_seconds,EVENT,LAST_CALL_ET,blocking_session,blocking_instance,systimestamp collection_time from gv$session where state='WAITING' and round(WAIT_TIME_MICRO/1e6,6) >= 300 and wait_class != 'Idle' order by wait_seconds desc ;

SET MARKUP HTML ENTMAP OFF

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section6.4"></a> <mark>   TOP SESSIONS IN LAST 30 MINUTES  </H3> 
SET MARKUP HTML ENTMAP ON
select /*+ materialize */ 
       max(sample_time)-min(sample_time) "elapsed"
       , round(100*(sum(CASE WHEN session_state = 'WAITING' THEN 1 ELSE 0 END) )/count(*), 2) waits_pct
       , sql_id, sql_opname, SQL_PLAN_HASH_VALUE, TOP_LEVEL_SQL_ID
       , inst_id ||'-'|| SESSION_ID ||'-'|| SESSION_SERIAL# inst_sid_serial#
       --,event
       , client_id, module, action, program
       , min(sample_time) minst, max(sample_time) maxst, count(*)  samples
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Concurrency' THEN 1 ELSE 0 END) pct_Concurrency
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Cluster' THEN 1 ELSE 0 END) pct_Cluster
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Application' THEN 1 ELSE 0 END) pct_App
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Other' THEN 1 ELSE 0 END) pct_Other
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'User I/O' THEN 1 ELSE 0 END) pct_UserIO
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Commit' THEN 1 ELSE 0 END) pct_Commit
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'System I/O' THEN 1 ELSE 0 END) pct_SystemIO
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Configuration' THEN 1 ELSE 0 END) pct_Config
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Network' THEN 1 ELSE 0 END) pct_Network
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Scheduler' THEN 1 ELSE 0 END) pct_Scheduler
  from gv$active_session_history dash 
 where 1 = 1 
   and sample_time > sysdate- (30/ (24 * 60)) 
   and not regexp_like(client_id, 'ess[0-9]{1,}-')
 group by client_id, module, action, program,
          sql_id,sql_opname, SQL_PLAN_HASH_VALUE,TOP_LEVEL_SQL_ID,
          --event,
          inst_id||'-'||SESSION_ID||'-'||SESSION_SERIAL#
 order by 14 desc fetch first 20 rows only ;
SET MARKUP HTML ENTMAP OFF

SET MARKUP HTML ENTMAP OFF
PROMPT <H3> <a name="Section6.5"></a> <mark>   TOP ESS JOBS SESSION DETAILS  IN LAST 30 MINUTES </H3> 
SET MARKUP HTML ENTMAP ON
select /*+ materialize */ 
       max(sample_time)-min(sample_time) "elapsed"
       , round(100*(sum(CASE WHEN session_state = 'WAITING' THEN 1 ELSE 0 END) )/count(*), 2) waits_pct
       , sql_id, sql_opname, SQL_PLAN_HASH_VALUE, TOP_LEVEL_SQL_ID
       , inst_id ||'-'|| SESSION_ID ||'-'|| SESSION_SERIAL# inst_sid_serial#
       --,event
       , client_id, module, action, program
       , min(sample_time) minst, max(sample_time) maxst, count(*)  samples
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Concurrency' THEN 1 ELSE 0 END) pct_Concurrency
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Cluster' THEN 1 ELSE 0 END) pct_Cluster
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Application' THEN 1 ELSE 0 END) pct_App
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Other' THEN 1 ELSE 0 END) pct_Other
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'User I/O' THEN 1 ELSE 0 END) pct_UserIO
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Commit' THEN 1 ELSE 0 END) pct_Commit
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'System I/O' THEN 1 ELSE 0 END) pct_SystemIO
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Configuration' THEN 1 ELSE 0 END) pct_Config
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Network' THEN 1 ELSE 0 END) pct_Network
       , sum(CASE WHEN session_state = 'WAITING' AND wait_class = 'Scheduler' THEN 1 ELSE 0 END) pct_Scheduler
  from gv$active_session_history dash 
 where 1 = 1 
   and sample_time > sysdate- (30/ (24 * 60)) 
   and regexp_like(client_id, 'ess[0-9]{1,}-')
 group by client_id, module, action, program,
          sql_id,sql_opname, SQL_PLAN_HASH_VALUE,TOP_LEVEL_SQL_ID,
          --event,
          inst_id||'-'||SESSION_ID||'-'||SESSION_SERIAL#
 order by 14 desc fetch first 20 rows only ;
SET MARKUP HTML ENTMAP OFF

PROMPT <a name="Section7"></a> <H3> <mark>  7.) ESS Jobs Current STATUS Details </H3>
set head on
SET MARKUP HTML ENTMAP ON

SELECT REQUESTID,PARENTREQUESTID,STATE, DEFINITION, to_char(PROCESSSTART, 'DD-MON-YYYY HH24:MI:SS') PROCESSSTART,type FROM FUSION_ORA_ESS.REQUEST_HISTORY WHERE STATE IN (3,13,7,5,2) order by 1;


SET MARKUP HTML ENTMAP OFF

PROMPT <a name="Section8"></a> <H3> <mark>  8.) Current Active and Inactive Session Details </H3>
set head on
SET MARKUP HTML ENTMAP ON

select b.* from v$session b, v$parameter c where c.name = 'cpu_count' and c.value <='18' and b.TYPE='USER';

SET MARKUP HTML ENTMAP OFF
set markup html off
spool off;

@?/rdbms/admin/sqlsessend.sql
exit; 
