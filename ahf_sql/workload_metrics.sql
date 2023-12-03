Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/workload_metrics.sql /main/1 2023/03/02 09:04:02 migufuen Exp $
Rem
Rem workload_metrics.sql
Rem
Rem Copyright (c) 2023, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      workload_metrics.sql - This script collects the workload metrics for ADBD
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/workload_metrics.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    migufuen    01/04/23 - Created
Rem

set linesize 30000;
set long 300000;
set longchunksize 30000;
col db_name format a15
col con_id format 999999
col container_name format a14
col cpu_count_value format a16
col service_name format a36

WITH ash_base AS
         -- comments for inline view "ash_base"
-- extract/compute active session history metrics
-- 1. covering the most recent, complete ten minute period
-- 2. excluding background processes
-- 3. excluding CDB$ROOT usage
-- dimensions :
--    sample_time (truncated to remove seconds)
--    container (excluding cdb$root)
--    instance number
--    service (hash value)
-- measures :
--    min and max sample ids
--    DB_SVC_AAS average active sessions by service hash (includes "on cpu" and waits)
--    DB_SVC_AAS_CPU average active sessions by service hash (includes "on cpu" only)
--    DB_SVC_AAS_WAIT average active sessions by service hash (includes waits only)
--    PDB_AAS average active sessions by pdb (includes "on cpu" and waits)
--    PDB_AAS_CPU average active sessions by pdb (includes "on cpu" only)
--    PDB_AAS_WAIT average active sessions by pdb (includes waits only)
--    CDB_INST_MINUS_ROOT_AAS average active sessions by cdb (includes "on cpu" and waits)
--    CDB_INST_MINUS_ROOT_AAS_CPU average active sessions by cdb (includes "on cpu" only)
--    CDB_INST_MINUS_ROOT_AAS_WAIT average active sessions by cdb (includes waits only)
         (SELECT	sample_time
               ,db_sample_time
               ,con_dbid
               ,con_id
               ,inst_id
               ,min_sample_id
               ,max_sample_id
               ,service_hash
               ,aas as db_svc_aas
               ,aas_cpu as db_svc_aas_cpu
               ,aas_wait as db_svc_aas_wait
               ,sum(aas) OVER (PARTITION BY inst_id, con_dbid, sample_time) as pdb_aas
               ,sum(aas_cpu) OVER (PARTITION BY inst_id, con_dbid, sample_time) as pdb_aas_cpu
               ,sum(aas_wait) OVER (PARTITION BY inst_id, con_dbid, sample_time) as pdb_aas_wait
               ,sum(aas) OVER (PARTITION BY inst_id, sample_time) as cdb_inst_minus_root_aas
               ,sum(aas_cpu) OVER (PARTITION BY inst_id, sample_time) as cdb_inst_minus_root_aas_cpu
               ,sum(aas_wait) OVER (PARTITION BY inst_id, sample_time) as cdb_inst_minus_root_aas_wait
          FROM TABLE(GV$(CURSOR(
			SELECT  sample_time
				,db_sample_time
				,con_dbid
				,con_id
				,service_hash
				,TO_NUMBER(USERENV('INSTANCE')) as inst_id
				,MIN(sample_id) as min_sample_id
				,MAX(sample_id) as max_sample_id
				,ROUND((SUM(fg_total_secs)/60),4) as aas
				,ROUND((SUM(fg_cpu_secs)/60),4) as aas_cpu
				,ROUND((SUM(fg_wait_secs)/60),4) as aas_wait
          FROM	(SELECT	ash.con_id
                  ,ash.con_dbid
                  ,to_char(trunc(cast(ash.sample_time_utc as date), 'MI'),'YYYY-MM-DD HH24:MI:SS') as sample_time
                  ,to_char(trunc(cast(ash.sample_time as date), 'MI'),'YYYY-MM-DD HH24:MI:SS') as db_sample_time
                  ,service_hash
                  ,ash.sample_id
                  ,ash.usecs_per_row / 1000000 as fg_total_secs
                  ,decode(ash.session_state,'ON CPU', ash.usecs_per_row / 1000000, 0) as fg_cpu_secs
                  ,decode(ash.session_state,'WAITING', ash.usecs_per_row / 1000000, 0) as fg_wait_secs
              FROM  v$active_session_history ash
              WHERE  ash.sample_time_utc BETWEEN TRUNC(SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '11' MINUTE,'MI') AND TRUNC(SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '1' MINUTE,'MI')-1/86400
              AND  ash.con_id > 1
              AND  ash.session_type <> 'BACKGROUND'
              )
          GROUP BY sample_time, db_sample_time, con_dbid, con_id, service_hash
         )
    )
		)
ORDER BY sample_time desc, con_id, inst_id
	),
	rsrcmgr_base AS
-- comments for inline view "rsrcmgr_base"
-- extract/compute metrics relating to resource usage and plan
-- as measured by the "database resource manager"
-- 1. excluding CDB$ROOT usage
-- dimensions :
--    begin_time_min (minutes)
--    container (excluding cdb$root)
--    instance number
-- measures :
--    cpu_wait_time cumulative time spent by sessions waiting for cpu (due to resource management)
--    num_cpus dbrm governed by cpu_count
--    avg_waiting_sessions average number of sessions waiting due to dbrm
--    iops io operations per second during prior minute by pdb
--    iombps io MB per second during prior minute by pdb
--    avg_io_throttle average io operation throttle time in ms during prior minute by pdb
--    avg_queued_parallel_stmts average number of parallel statements queued during the 1-minute metric window
--    avg_queued_parallel_servers average number of parallel servers requested by queued parallel statements during the 1-minute metric window
		(SELECT	con_id
			,inst_id
			,begin_time
			,begin_time_min
			,cpu_consumed_time
			,cpu_wait_time
			,num_cpus
			,running_sessions_limit
			,avg_running_sessions
			,avg_waiting_sessions
			,cpu_utilization_limit
			,avg_cpu_utilization
			,iops
			,iombps
			,iops_throttle_exempt
			,iombps_throttle_exempt
			,avg_io_throttle
			,avg_active_parallel_stmts
			,avg_queued_parallel_stmts
			,avg_active_parallel_servers
			,avg_queued_parallel_servers
			,parallel_servers_limit
			,sga_bytes
			,buffer_cache_bytes
			,shared_pool_bytes
			,pga_bytes
			,plan_name
		FROM  TABLE(GV$(CURSOR(
				SELECT  con_id
					,TO_NUMBER(USERENV('INSTANCE')) as inst_id
,to_char(begin_time-time_zone_in_days, 'YYYY-MM-DD HH24:MI:SS') as begin_time
,to_char(trunc(begin_time-time_zone_in_days,'MI'), 'YYYY-MM-DD HH24:MI:SS') as begin_time_min
,cpu_consumed_time
,cpu_wait_time
,num_cpus
,running_sessions_limit
,avg_running_sessions
,avg_waiting_sessions
,cpu_utilization_limit
,avg_cpu_utilization
,iops
,iombps
,iops_throttle_exempt
,iombps_throttle_exempt
,avg_io_throttle
,avg_active_parallel_stmts
,avg_queued_parallel_stmts
,avg_active_parallel_servers
,avg_queued_parallel_servers
,parallel_servers_limit
,sga_bytes
,buffer_cache_bytes
,shared_pool_bytes
,pga_bytes
,plan_name
FROM	(SELECT  r.begin_time
,r.end_time
,tz.time_zone_in_days
,r.con_id
,r.sequence#
,r.cpu_consumed_time
,r.cpu_wait_time
,r.num_cpus
,r.running_sessions_limit
,r.avg_running_sessions
,r.avg_waiting_sessions
,r.cpu_utilization_limit
,r.avg_cpu_utilization
,r.iops
,r.iombps
,r.iops_throttle_exempt
,r.iombps_throttle_exempt
,r.avg_io_throttle
,r.avg_active_parallel_stmts
,r.avg_queued_parallel_stmts
,r.avg_active_parallel_servers
,r.avg_queued_parallel_servers
,r.parallel_servers_limit
,r.sga_bytes
,r.buffer_cache_bytes
,r.shared_pool_bytes
,r.pga_bytes
,p.name as plan_name
FROM	V$RSRCPDBMETRIC_HISTORY r
,V$RSRC_PLAN p
,(SELECT ROUND((cast(latest_sample_time as date) - cast(sys_extract_utc(systimestamp) as date))*96,0)/96 as time_zone_in_days FROM v$ash_info) tz
WHERE	r.con_id > 1
AND	r.con_id = p.con_id
) ORDER BY begin_time, inst_id, con_id
)
)
)
),
-- comments for inline view "service_base"
-- extract/compute metrics relating to service
-- 1. exclude CDB$ROOT usage
-- 2. limit to metric group '6', ie. "Service Metrics"
-- dimensions :
--    begin_time_min (minutes)
--    container
--    instance number
--    service_name_hash / service_name
-- measures :
--    dbtimepercall_usec elapsed time per call (in microseconds)
--    cpupercall_usec	 CPU time per call (in microseconds)
service_base AS
(SELECT	con_id
,inst_id
,begin_time
,prev_begin_time
,begin_time_min
,service_name_hash
,service_name
,dbtimepercall_usec
,cpupercall_usec
FROM TABLE(GV$(CURSOR(
				SELECT	con_id
					,TO_NUMBER(USERENV('INSTANCE')) as inst_id
,to_char(begin_time-time_zone_in_days, 'YYYY-MM-DD HH24:MI:SS') as begin_time
,LAG(to_char(begin_time-time_zone_in_days, 'YYYY-MM-DD HH24:MI:SS')) OVER (PARTITION BY con_id, TO_NUMBER(USERENV('INSTANCE')), service_name ORDER BY begin_time) as prev_begin_time
,to_char(trunc(begin_time-time_zone_in_days,'MI'), 'YYYY-MM-DD HH24:MI:SS') as begin_time_min
,service_name_hash
,service_name
,dbtimepercall_usec
,cpupercall_usec
FROM (SELECT	sh.con_id
,sh.begin_time
,TO_DATE(TO_CHAR(SYS_EXTRACT_UTC(TO_TIMESTAMP(TO_CHAR(sh.begin_time,'dd-mon-yy hh:mi:ss am'))),'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') as utc_begin_time
,TO_DATE(TO_CHAR(SYS_EXTRACT_UTC(TO_TIMESTAMP(TO_CHAR(sh.end_time,'dd-mon-yy hh:mi:ss am'))),'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') as utc_end_time
,tz.time_zone_in_days
,sh.service_name_hash
,sh.service_name as service_name
,sh.dbtimepercall as dbtimepercall_usec
,sh.cpupercall as cpupercall_usec
FROM	v$servicemetric_history sh
,(SELECT ROUND((cast(latest_sample_time as date) - cast(sys_extract_utc(systimestamp) as date))*96,0)/96 as time_zone_in_days FROM v$ash_info) tz
WHERE  sh.group_id = 6
AND  sh.con_id > 1
)
ORDER BY begin_time DESC, con_id, service_name
)
)
)
),
-- comments for inline view "sysmetric_base"
-- extract/compute metrics relating to PDB system metrics of long duration
-- 1. excluding CDB$ROOT usage
-- 2. limit to metric group '18', ie. "PDB System Metrics Long Duration"
-- 3. filter on metrics; 'Average Active Sessions', 'SQL Service Response Time',
--    'User Calls Per Sec' and 'User Transaction Per Sec'
-- dimensions :
--    begin_time_min (minutes)
--    container
--    instance number
-- measures :
--    sql_service_response_time average response time in seconds
--    sm_aas                    sysmetric average active sessions
--    user_calls_per_sec        user calls per second
--    tps                       user transactions per second
sysmetric_base AS
(SELECT con_id, inst_id, begin_time_min, sql_service_response_time, sm_aas, user_calls_per_sec, tps
FROM TABLE(GV$(CURSOR(
				SELECT	con_id
					,TO_NUMBER(USERENV('INSTANCE')) as inst_id
,to_char(trunc(begin_time-time_zone_in_days,'MI'), 'YYYY-MM-DD HH24:MI:SS') as begin_time_min
,sql_service_response_time
,ROUND(avg_active_sessions,4) as sm_aas
,user_calls_per_sec
,user_transaction_per_sec as tps
FROM	(SELECT	sh.con_id
,sh.begin_time
,tz.time_zone_in_days
,sh.metric_name  as metric_name
,sh.value as value
FROM	v$con_sysmetric_history sh
,(SELECT ROUND((cast(latest_sample_time as date) - cast(sys_extract_utc(systimestamp) as date))*96,0)/96 as time_zone_in_days FROM v$ash_info) tz
WHERE  sh.group_id = 18
AND  sh.con_id > 1
AND  sh.metric_name in (
'Average Active Sessions'
,'SQL Service Response Time'
,'User Calls Per Sec'
,'User Transaction Per Sec'
)
)
PIVOT (MAX(value)
for metric_name in (
'Average Active Sessions'   as avg_active_sessions
,'SQL Service Response Time' as sql_service_response_time
,'User Calls Per Sec' as user_calls_per_sec
,'User Transaction Per Sec' as user_transaction_per_sec
)
)
ORDER BY begin_time
)
)
)
),
-- comments for inline view "cdb_cpu_count"
-- compute number of cpus set at the root container
cdb_cpu_count AS
(select value from v$system_parameter where name ='cpu_count' and con_id = 0),
-- comments for inline view "threads"
-- compute number of threads per core
threads AS
(SELECT num_cpus/num_cpu_cores as cpu_hw_threads FROM (SELECT os.snap_id, os.stat_name, os.value FROM dba_hist_osstat os) PIVOT ( sum(value) FOR stat_name IN('NUM_CPUS' AS num_cpus, 'NUM_CPU_CORES' AS num_cpu_cores)) WHERE rownum = 1)
-- output CDB workload metrics in a single json object
SELECT json_object ('data_type' is 'workload_metrics'
           ,'db_name' value db.name
           ,'db_unique_name' value db.db_unique_name
           ,'timestamp' value TO_CHAR(SYSTIMESTAMP,'yyyy-MM-dd"T"HH24:MI:ss.ff3TZH:TZM')
           ,'workload_metrics' is (
                        SELECT
                            json_arrayagg (
                                    json_object (
                                            'utc_sample_time' IS s.begin_time_min
                                        --,a.db_sample_time
                                        ,'container_name' IS cc.name
                                        ,'cpu_count_value' IS cc.cpu_count_value
                                        ,'service_name' IS s.service_name
                                        ,'inst_id' IS a.inst_id
                                        ,'pdb_aas_pc' IS ROUND(nvl(a.pdb_aas / (cc.cpu_count_value / t.cpu_hw_threads),0),4)
                                        ,'pdb_aas_cpu_pc' IS ROUND(nvl(a.pdb_aas_cpu / (cc.cpu_count_value / t.cpu_hw_threads),0),4)
                                        ,'db_svc_aas_pc' IS ROUND(nvl(a.db_svc_aas / (cc.cpu_count_value / t.cpu_hw_threads),0),4)
                                        ,'db_svc_aas_cpu_pc' IS ROUND(nvl(a.db_svc_aas_cpu / (cc.cpu_count_value / t.cpu_hw_threads),0),4)
                                        ,'db_time_per_call_ms' IS ROUND((s.dbtimepercall_usec/1000),4)
                                        ,'sql_response_time_per_call_ms' IS ROUND((sm.sql_service_response_time*10),4)
                                        ,'tps' IS ROUND(sm.tps,4)
                                        ,'dbrm_cpu_wait_time' IS rmgr.cpu_wait_time
                                        ,'dbrm_num_cpus' IS rmgr.num_cpus
                                        ,'dbrm_avg_waiting_sessions' IS ROUND(rmgr.avg_waiting_sessions,4)
                                        ,'iops' IS ROUND(rmgr.iops,4)
                                        ,'iombps' IS ROUND(rmgr.iombps,4)
                                        ,'avg_io_throttle' IS ROUND(rmgr.avg_io_throttle,4)
                                        ,'avg_queued_parallel_stmts' IS ROUND(rmgr.avg_queued_parallel_stmts,4)
                                        ,'avg_queued_parallel_servers' IS ROUND(rmgr.avg_queued_parallel_servers,4)
                                            RETURNING CLOB )
                                    RETURNING CLOB )
                        FROM	ash_base a
                           ,rsrcmgr_base rmgr
                           ,service_base s
                           ,sysmetric_base sm
                           ,threads t
                           ,(select  c.inst_id, c.dbid as con_dbid, c.con_id, c.name, p.parameter, p.cpu_count, nvl(p.cpu_count, cdb_cpu_count.value) as cpu_count_value
                             from	cdb_cpu_count
                                ,(select  inst_id, dbid, con_id, name from gv$containers where open_mode = 'READ WRITE') c
                                ,(select  inst_id, DECODE(con_id, 0, 1, con_id) as container_id, name as parameter, value as cpu_count
                                  from  (select inst_id, con_id, name, value from gv$system_parameter where name = 'cpu_count')) p
                             where  p.container_id(+) = c.con_id
                               and  p.inst_id(+)  = c.inst_id) cc
-- query is driven from data returned by ash_base view, each
-- subsequent view is joined using the dimensions columns :
-- ash.sample_time
-- ash.inst_id
-- ash.con_id
-- ash.service_hash
                        where	a.sample_time = s.begin_time_min
                          and	a.sample_time = sm.begin_time_min
                          and	a.sample_time = rmgr.begin_time_min
                          and	a.inst_id = s.inst_id
                          and	a.inst_id = sm.inst_id
                          and	a.inst_id = rmgr.inst_id
                          and	a.inst_id = cc.inst_id
                          and	a.con_id = s.con_id
                          and	a.con_id = rmgr.con_id
                          and	a.con_id = sm.con_id
                          and	a.con_dbid = cc.con_dbid
                          and	a.service_hash = s.service_name_hash
                    )
                    RETURNING CLOB )
from v$database db
/


 
