Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_aqhc11R2.sql /main/4 2020/12/07 21:06:51 bvongray Exp $
Rem
Rem srdc_aqhc11R2.sql
Rem
Rem Copyright (c) 2019, 2020, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_aqhc11R2.sql
Rem
Rem    DESCRIPTION
Rem      None
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_aqhc11R2.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    11/06/20 - SRDC Script updates
Rem    xiaodowu    03/19/20 - Update script
Rem    xiaodowu    07/15/19 - Update script
Rem    xiaodowu    07/05/19 - Called by Advanced Queuing SRDCs
Rem    xiaodowu    07/05/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM
REM This healthcheck script version 7.0 is for use on the following Oracle databases only.
REM     Oracle 11gR2
REM
REM Do not use this script on Oracle 10g or Oracle 11gR1 configurations.
REM
REM This healthcheck script is for use on Oracle11gR2 databases only.
REM 
REM
REM Do not use this script on Oracle 10g or Oracle 11gR1 configurations.
REM
REM  It  is recommended to run with markup html ON (default is on) and generate an HTML file for web viewing.
REM  Please provide the output in HTML format when Oracle (support or development) requests healthcheck output.
REM  To convert output to a text file viewable with a text editor, 
REM    change the HTML ON to HTML OFF in the set markup command
REM
REM
REM Please note that this script also checks Messaging Gateway (MGW) installation if it is configured.
REM If MGW is not configured in your database you will observe errors ORA-942 on output generated. 
REM These errors are expected and can be safely ignored.
REM MGW is NOT required for correct behavior of Advanced Queueing (AQ)

-- connect / as sysdba

define hcversion = 'v7.0.10'
set markup HTML ON entmap off spool on
set truncate off
set numwidth 15
set heading off
set feedback off
set verify off
set lines 200
set pages 9999
set numf 9999999999999999
alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
alter session set nls_language=american;

REM
REM spool file name AUTOMATICALLY GENERATED
REM 

REM Collection name SRDC_ or MOS_
define COLLNAME='SRDC_'
define SRDCNAME='AQ_Healthcheck'
column SRDCSPOOLNAME new_val SRDCSPOOLNAME
select '&&COLLNAME'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS')||'.htm' SRDCSPOOLNAME from v$instance;
spool &SRDCSPOOLNAME

prompt
prompt
select 'Oracle Advanced Queuing Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;

set heading on timing off
set define off

DROP TABLE TEMPAQHC_DROPME;
CREATE GLOBAL TEMPORARY TABLE TEMPAQHC_DROPME (ERRORCODE VARCHAR2(12), OBJECT VARCHAR2(50),DESCRIPTION VARCHAR2(1000),ACTION VARCHAR2(1000))
ON COMMIT PRESERVE ROWS;

prompt <a name="Top">  </a>
prompt Configuration: <a href="#DBConfig">Database</a> <a href="#QTConfig">Queue Tables</a> <a href="#QConfig">Queues</a> <a href="#Subsconf">Subscribers</a> <a href="#Props">Propagations</a>  <a href="#Notif">Notifications</a> <a href="#Confother">Other</a>
prompt MGW: <a href="#MGWAgent">Agent</a> <a href="#MGWFQ">Foreign Queues</a> <a href="#MGWLink">Links</a> <a href="#MGWProps">Propagation</a> 
prompt Statistics : <a href="#QMONstats">QMON</a> <a href="#Qstats">Queues</a> <a href="#Pubstats">Publishers</a> <a href="#substats">Subscribers</a> <a href="#subprop">Propagation</a> <a href="#Notifstats">Notifications</a> 
prompt Analisys : <a href="#History">History</a> <a href="#Alerts">Alerts</a>


prompt <a name="DBConfig"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>DATABASE CONFIGURATION</b></a> ++    <a href="#Instance">Instance</a> <a href="#Registry">Registry</a> <a href="#NLS">NLS</a> <a href="#Parameters">Parameters</a> <a href="#AQParameters1">AQ Parameters</a> <a href="#InvalidQT">Invalid Queue Table Objects</a> <a href="#Top">Top</a>  ++
prompt
prompt
prompt <a name="Instance"> </a>
prompt ++ <a name="Instance">INSTANCE INFORMATION</a> ++ <a href="#DBConfig">DB</a> <a href="#Top">Top</a>
col host format a30 wrap 

select instance_number INSTANCE, instance_name NAME, HOST_NAME HOST, VERSION,
STARTUP_TIME, STATUS, PARALLEL, ARCHIVER,LOGINS, SHUTDOWN_PENDING, INSTANCE_ROLE, ACTIVE_STATE  from gv$instance;

prompt
prompt <a name="Registry"> </a>
prompt ++ REGISTRY INFORMATION ++ <a href="#DBConfig">DB</a> <a href="#Top">Top</a>
col comp_id format a10 wrap
col comp_name format a35 wrap
col version format a10 wrap
col schema format a10

select comp_id, comp_name,version,status,modified,schema from DBA_REGISTRY;

prompt
prompt <a name="NLS"> </a>
prompt ++ NLS DATABASE PARAMETERS ++ <a href="#DBConfig">DB</a> <a href="#Top">Top</a>
col parameter format a30 wrap
col value format a30 wrap

select * from NLS_DATABASE_PARAMETERS;

prompt
prompt <a name="Parameters"> </a>
prompt ++ KEY INITALIZATION PARAMETERS ++  <a href="#DBConfig">DB</a> <a href="#Top">Top</a>
col inst_id HEADING 'Instance' format 99
col name HEADING 'Parameter|Name' format a20
col value HEADING 'Parameter|Value' format a15
col description HEADING 'Description' format a60 word
col defaul HEADING  'Default?' format a8 

select inst_id, name, value, decode (isdefault,'TRUE','YES','NO') defaul, description from gv$parameter 
where name in ('aq_tm_processes', 'job_queue_processes','_job_queue_interval',
    'global_names', 'global_topic_enabled', 'compatible', 'shared_pool_size', 'memory_max_target', 'memory_target',
     'sga_max_size', 'sga_target','streams_pool_size')
order by 1,2;

prompt
prompt <a name="AQParameters1"> </a>
prompt ++ AQ KEY PARAMETERS ++ <a href="#DBConfig">DB</a> <a href="#Top">Top</a> ++
prompt

col NAME format a50 
col VALUE format a20 
col DESCRIPTION format a100 

SELECT x.ksppinm NAME, y.ksppstvl VALUE, ksppdesc DESCRIPTION FROM x$ksppi x, x$ksppcv y WHERE
x.inst_id = userenv('Instance')AND y.inst_id = userenv('Instance') AND x.indx = y.indx AND (
SUBSTR(x.ksppinm,1,19) = '_client_enable_auto' or SUBSTR(x.ksppinm,1,18) = '_emon_send_timeout') ORDER BY 1;  

prompt
prompt <a name="InvalidQT"> </a>
prompt ++ INVALID QUEUE TABLE OBJECTS ++ <a href="#DBConfig">DB</a> <a href="#Top">Top</a>  ++ 
prompt

select owner, object_name, object_type, status from dba_objects where ((object_name like 'AQ$\_%' escape '\' and object_type='TABLE')
OR (object_name like 'AQ$%' and object_type='VIEW') OR object_type in ('QUEUE','RULE SET','EVALUATION CONTEXT')) AND status != 'VALID' 
UNION
select owner, object_name, object_type, status from dba_objects where object_name in (select queue_table from dba_queue_tables) AND status != 'VALID' 
order by 1,2,3;

prompt   
prompt <a name="QTConfig"> </a>
prompt ============================================================================================
prompt                                                             
prompt ++ <b>QUEUE TABLES</b></a> ++ <a href="#QConfig">Queues</a> <a href="#Normalq">Normal Queues</a> <a href="#NPQ">Non Persistent</a> <a href="#Excpq">Exception Queues</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++

prompt

col owner HEADING 'Owner' format a15
col object_type HEADING 'Payload' format a35 wrap
col message_grouping HEADING 'Message|Grouping' format a13
col primary_instance HEADING 'Primary|Instance' format 999
col secondary_instance HEADING 'Secondary|Instance' format 999
col owner_instance HEADING 'Owner|Instance' format 999
col user_comment HEADING 'User|Comment' format a20 wrap
col objno heading 'Object|Number'

select owner, queue_table, recipients, sort_order, compatible, object_type,
       owner_instance, primary_instance, secondary_instance, type, secure, user_comment 
from dba_queue_tables
order by owner, queue_table;
prompt
prompt
prompt <a name="QConfig"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>QUEUES</b></a> ++ <a href="#QTConfig">Queue Tables</a> <a href="#Normalq">Normal Queues</a> <a href="#NPQ">Non Persistent</a> <a href="#Excpq">Exception Queues</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++
prompt

col owner HEADING 'Owner' format a10
col name HEADING 'Queue Name' format a30
col qid HEADING 'Id' format 999999999
col max_retries HEADING 'Max.|Retries' format 999999999
col retry_delay HEADING 'Retry|Delay' format 999999999
col dequeue_enabled HEADING 'Dequeue|Enabled' format a7
col enqueue_enabled HEADING 'Enqueue|Enabled' format a7
col retention HEADING 'Retention' format a10 wrap
col user_comment HEADING 'User|Comment' format a10 wrap
col network_name HEADING 'Network|Name' format a10 wrap
col buffered HEADING 'Buffered' format a8

prompt
prompt <a name="Normalq"> </a>
prompt ++ NORMAL QUEUES ++ <a href="#QTConfig">Queue Tables</a> <a href="#NPQ">Non Persistent</a> <a href="#Excpq">Exception Queues</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++
prompt

select q.owner, q.queue_table, q.name, q.qid, q.enqueue_enabled, q.dequeue_enabled, NVL2(b.queue_id,'YES','NO') buffered,
       q.max_retries, q.retry_delay, q.retention, q.user_comment, q.network_name
from dba_queues q, gv$buffered_queues b
where q.queue_type='NORMAL_QUEUE'
  and q.qid=b.queue_id(+)
order by q.owner, q.queue_table, q.name;

prompt
prompt <a name="NPQ"> </a>
prompt ++ NON PERSISTENT QUEUES ++ <a href="#QTConfig">Queue Tables</a> <a href="#QConfig">Queues</a> <a href="#Normalq">Normal Queues</a> <a href="#Excpq">Exception Queues</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++
prompt 

select owner, queue_table, name, qid, enqueue_enabled, dequeue_enabled,
       max_retries, retry_delay, retention, user_comment, network_name
from dba_queues
where queue_type='NON_PERSISTENT_QUEUE'
order by owner, queue_table, name;

prompt
prompt <a name="Excpq"> </a>
prompt ++ EXCEPTION QUEUES ++ <a href="#QTConfig">Queue Tables</a> <a href="#QConfig">Queues</a> <a href="#Normalq">Normal Queues</a> <a href="#NPQ">Non Persistent</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++
prompt 

select owner, queue_table, name, qid, enqueue_enabled, dequeue_enabled,
       max_retries, retry_delay, retention, user_comment, network_name
from dba_queues
where queue_type='EXCEPTION_QUEUE'
order by owner, queue_table, name;

prompt
prompt <a name="Nbq"> </a>
prompt ============================================================================================
prompt 
prompt ++ <b>NOTIFICATION BASED SYSTEM QUEUES</b></a> ++ <a href="#QConfig">Queues</a> <a href="#Normalq">Normal Queues</a> <a href="#NPQ">Non Persistent</a> <a href="#Excpq">Exception Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Notif">Notifications</a> <a href="#Top">Top</a> ++
prompt 
prompt 
prompt
prompt ++ SYS.AQ$SYS$SERVICE_METRICS_TAB message count ++
prompt 

select queue, msg_state, count(*), min(enq_time), max(enq_time) 
from SYS.AQ$SYS$SERVICE_METRICS_TAB group by queue, msg_state; 

prompt 
prompt ++ SYS.AQ$AQ_EVENT_TABLE message count ++
prompt 

select queue, msg_state, count(*), min(enq_time), max(enq_time) 
from SYS.AQ$AQ_EVENT_TABLE group by queue, msg_state; 

prompt 
prompt ++ SYS.AQ$SCHEDULER$_EVENT_QTAB message count ++
prompt 

select queue, msg_state, consumer_name, count(*), min(enq_time), max(enq_time) 
from SYS.AQ$SCHEDULER$_EVENT_QTAB group by queue, msg_state, consumer_name; 

prompt 
prompt ++ SYS.AQ$ALERT_QT message count ++
prompt 

select queue, msg_state, count(*), min(enq_time), max(enq_time) 
from SYS.AQ$ALERT_QT group by queue, msg_state; 

prompt 
prompt ++ SYS.AQ$AQ_SRVNTFN_TABLE_x message count ++ 
prompt
prompt  Note: The AQ_SRVNTFN_TABLE_x Queue Tables are created on each instance as needed automatically.
prompt
prompt   Notification Queue Table - Instance 1
prompt
select qt.queue, qt.msg_state, qt.user_data.queue_name, qt.user_data.consumer_name, qt.msg_state, 
count(*), min(enq_time), max(enq_time) from SYS.AQ$AQ_SRVNTFN_TABLE_1 qt 
group by qt.queue, qt.msg_state, qt.user_data.queue_name, qt.msg_state, qt.user_data.consumer_name; 
prompt
prompt   Notification Queue Table - Instance 2
prompt
select qt.queue, qt.msg_state, qt.user_data.queue_name, qt.user_data.consumer_name, qt.msg_state, 
count(*), min(enq_time), max(enq_time) from SYS.AQ$AQ_SRVNTFN_TABLE_2 qt 
group by qt.queue, qt.msg_state, qt.user_data.queue_name, qt.msg_state, qt.user_data.consumer_name; 
prompt
prompt   Notification Queue Table - Instance 3
prompt                                                                                                                                         
select qt.queue, qt.msg_state, qt.user_data.queue_name, qt.user_data.consumer_name, qt.msg_state, 
count(*), min(enq_time), max(enq_time) from SYS.AQ$AQ_SRVNTFN_TABLE_3 qt
group by qt.queue, qt.msg_state, qt.user_data.queue_name, qt.msg_state, qt.user_data.consumer_name;
prompt
prompt   Notification Queue Table - Instance 4
prompt
select qt.queue, qt.msg_state, qt.user_data.queue_name, qt.user_data.consumer_name, qt.msg_state, 
count(*), min(enq_time), max(enq_time) from SYS.AQ$AQ_SRVNTFN_TABLE_4 qt 
group by qt.queue, qt.msg_state, qt.user_data.queue_name, qt.msg_state, qt.user_data.consumer_name;

prompt
prompt <a name="Quepriv"> </a>
prompt ============================================================================================
prompt 
prompt ++ <b>QUEUE PRIVILEGES</b></a> ++ <a href="#QConfig">Queues</a> <a href="#Normalq">Normal Queues</a> <a href="#NPQ">Non Persistent</a> <a href="#Excpq">Exception Queues</a> <a href="#Nbq">Notification Based Queues</a> <a href="#Quepriv">Privileges</a> <a href="#Top">Top</a> ++
prompt

col owner HEADING 'Owner'
col name HEADING 'Name'
col grantee HEADING 'Grantee'
col grantor HEADING 'Grantor'
col enqueue_privilege HEADING 'Enqueue'
col dequeue_privilege HEADING 'Dequeue'
select owner, name, grantee, grantor, enqueue_privilege, dequeue_privilege from queue_privileges
order by 1,2,3;

prompt
prompt <a name="Subsconf"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>SUBSCRIBERS</b></a> ++ <a href="#SubsAll">All</a> <a href="#Transf">TRANSFORMATIONS</a> <a href="#IAgents">HTTP/SMTP AGENTS</a> <a href="#Top">Top</a> ++
prompt

prompt
prompt <a name="SubsAll"> </a>
prompt ++ ALL SUBSCRIBERS ++ <a href="#Subsconf">Subscribers</a> <a href="#Top">Top</a> ++
prompt
set markup HTML OFF entmap off
set serveroutput on

declare 
   cursor mult_qt is select owner, queue_table from dba_queue_tables where recipients='MULTIPLE' order by 1,2;
   statement varchar2(4000);
   TYPE qttype IS REF CURSOR;
   v_qttype qttype;
   qt_record SYS.AQ$_ALERT_QT_S%ROWTYPE;
   queuename varchar2(30);
   substype varchar2(82);
   type_no_match exception;
   pragma exception_init(type_no_match, -932);
begin

  dbms_output.put_line ('<table border=''1'' width=''90%'' align=''center'' summary=''Script output''>');
  dbms_output.put_line ('<tr>');
  dbms_output.put_line ('<th scope=""col"">Owner</th><th scope=""col"">Queue<br>Table</th><th scope=""col"">Queue<br>Name</th>');
  dbms_output.put_line ('<th scope=""col"">Subsriber<br>Name</th><th scope=""col"">Address</th><th scope=""col"">Id</th>');
  dbms_output.put_line ('<th scope=""col"">Subscriber_Type_Description</th><th scope=""col"">Ruleset<br>Name</th><th scope=""col"">Rule<br>Name</th>');
  dbms_output.put_line ('<th scope=""col"">Negative<br>Ruleset</th><th scope=""col"">Transformation</th>');
  dbms_output.put_line ('</tr>');
  dbms_output.put_line ('<tr>');

  for qt_name in mult_qt loop 
    statement :=  'select * from '||qt_name.owner||'.AQ$_'|| qt_name.queue_table || '_S order by queue_name, name, address';
    open v_qttype for statement;
    LOOP
      begin
      FETCH v_qttype INTO qt_record;
      EXIT WHEN v_qttype%NOTFOUND;
      
      substype := '';
      IF qt_record.subscriber_type is NULL THEN substype := 'DEFAULT'; END IF;
      IF BITAND(qt_record.subscriber_type,1) > 0 THEN substype := 'Subscriber'; END IF;
      IF BITAND(qt_record.subscriber_type,2) > 0 THEN substype := substype||' Removed'; END IF;
      IF BITAND(qt_record.subscriber_type,4) > 0 THEN substype := substype||' For address only'; END IF;
      IF BITAND(qt_record.subscriber_type,8) > 0 THEN substype := substype||' Proxy'; END IF;
      IF BITAND(qt_record.subscriber_type,64) > 0 THEN substype := substype||' for persistent msgs'; END IF;
      IF BITAND(qt_record.subscriber_type,128) > 0 THEN substype := substype||' for buffered msgs'; END IF;
      IF BITAND(qt_record.subscriber_type,1024) > 0 THEN substype := substype||' for deferred msgs'; END IF;
      IF substype = '' THEN substype := 'UNKNOWN'; END IF;
      substype := substype||' ('||qt_record.subscriber_type||')';
      select decode(qt_record.queue_name,'0','DEFAULT',qt_record.queue_name) into queuename from dual;
      
      
      dbms_output.put_line ('<td>');
      dbms_output.put_line (qt_name.owner);
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (qt_name.queue_table);
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (queuename);
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (NVL(qt_record.name,'&nbsp;'));
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (NVL(qt_record.address,'&nbsp;'));
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (qt_record.subscriber_id);
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (substype);
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('<td>');
      dbms_output.put_line (NVL(qt_record.ruleset_name,'&nbsp;'));
      dbms_output.put_line ('</td>');            
      dbms_output.put_line ('<td>');
      dbms_output.put_line (NVL(qt_record.rule_name,'&nbsp;'));
      dbms_output.put_line ('</td>');            
      dbms_output.put_line ('<td');
      dbms_output.put_line (NVL(qt_record.negative_ruleset_name,'&nbsp;'));
      dbms_output.put_line ('</td>');            
      dbms_output.put_line ('<td>');
      dbms_output.put_line (NVL(qt_record.trans_name,'&nbsp;'));
      dbms_output.put_line ('</td>');
      dbms_output.put_line ('</tr>');            
 
      exception 
        when type_no_match then
         insert into tempaqhc_dropme values ('Error',qt_name.owner||'.AQ$_'|| qt_name.queue_table || '_S',
            'Potential dictionary insconsistence on queue table '||qt_name.owner||'.'||qt_name.queue_table||'. Error ORA-932',
            'Verify if queues on queue table are working properly. If not contact Oracle Support.');
         commit;
         when others then null;
       end; 
    END LOOP;
    CLOSE v_qttype;     
  end loop;
   
  dbms_output.put_line ('</table>');
end;
/  
set serveroutput off
set markup HTML ON entmap off
prompt

prompt
prompt <a name="Transf"> </a>
prompt ++ TRANSFORMATIONS ++ <a href="#Confother">Other</a> <a href="#Top">Top</a> ++
prompt

select * from sys.dba_attribute_transformations 
order by owner, name, transformation_id, attribute;

prompt
prompt <a name="IAgents"> </a>
prompt ++ HTTP/SMTP AGENTS ++ <a href="#Confother">Other</a> <a href="#Top">Top</a> ++
prompt

select * from AQ$INTERNET_USERS;

prompt
prompt <a name="Props"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>PROPAGATIONS</b></a> ++ <a href="#Schedule">Scheduled</a> <a href="#Propjob">Jobs</a> <a href="#Top">Top</a> ++
prompt

col origin format a34
col destination format a34
col schedule_disabled HEADING 'Disabled?' format a9
col message_delivery_mode HEADING 'Delivery|Mode' format a10
col propagation_window HEADING 'Prop.|Window'
col start_date HEADING 'Start|Date'

prompt
prompt <a name="Schedule"> </a>
prompt ++ SCHEDULES FOR PROPAGATING MESSAGES ++ <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt 


select schema||'.'||qname origin, destination, schedule_disabled, propagation_window, latency, start_date, current_start_date, max_number, max_bytes
from dba_queue_schedules order by schema, qname, destination, message_delivery_mode;

prompt

select schema||'.'||qname origin, destination, message_delivery_mode, instance, process_name, session_id, last_run_date, next_run_date, next_time
from dba_queue_schedules order by schema, qname, destination, message_delivery_mode;

prompt

select schema||'.'||qname origin, destination, failures, last_error_date, last_error_msg
from dba_queue_schedules order by schema, qname, destination, message_delivery_mode;

prompt
prompt <a name="Propjob"> </a>
prompt ============================================================================================
prompt 
prompt ++ <b>PROPAGATION JOBS</b></a> ++ <a href="#Propjobsch">Scheduler Jobs</a> <a href="#Propjobschrun">Scheduler Jobs Running</a> <a href="#Propjobreg">Regular</a> <a href="#Propjoblrd">Last Run Details</a> <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt 

prompt
prompt <a name="Propjobsch"> </a>
prompt ++ SCHEDULER JOBS (AQ_JOB%) <a href="#Propjob">PropagationJobs</a>  <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt
col decinst heading 'Declared|Instance' format 99
col runins heading 'Running|Instance' format 99
col state heading 'Job|State'
col status heading 'Running|Status'

select enabled, state, count(*) 
from DBA_SCHEDULER_JOBS s where s.JOB_NAME LIKE 'AQ_JOB%' 
group by enabled, state; 

prompt
prompt <a name="Propjobschrun"> </a>
prompt ++ SCHEDULER JOBS RUNNING (AQ_JOB%) <a href="#Propjob">PropagationJobs</a>  <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt

select count(*) "Jobs Running (AQ_JOB)" from dba_scheduler_jobs sj, dba_scheduler_running_jobs rj, v$session s, v$process p where
sj.job_name = rj.job_name and
rj.session_id = s.sid and
s.paddr = p.addr and
lower(sj.job_name) like '%AQ_JOB%';
prompt
select s.job_name, enabled, state, detached, s.instance_id decinst, running_instance runins, session_id, slave_os_process_id, elapsed_time, cpu_used
from DBA_SCHEDULER_JOBS s LEFT OUTER JOIN DBA_SCHEDULER_RUNNING_JOBS r
    ON (s.job_name=r.job_name and s.owner=r.owner)
where s.JOB_NAME LIKE 'AQ_JOB%' and rownum < 100
order by s.instance_id, s.job_name;

prompt
prompt <a name="Propjobschrun"> </a>
prompt ++ SCHEDULER JOBS RUNNING (Job Action like %register_driver%) <a href="#Propjob">PropagationJobs</a>  <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt
prompt

select count(*) "Jobs Running (register_driver)" from dba_scheduler_jobs sj, dba_scheduler_running_jobs rj, v$session s, v$process p where
sj.job_name = rj.job_name and
rj.session_id = s.sid and
s.paddr = p.addr and
lower(sj.job_action) like '%register_driver%';

prompt

select p.spid, p.program, rj.job_name, sj.job_action
from dba_scheduler_jobs sj, dba_scheduler_running_jobs rj, v$session s, v$process p where
sj.job_name = rj.job_name and
rj.session_id = s.sid and
 s.paddr = p.addr and
 lower(sj.job_action) like '%register_driver%'
and rownum < 100;

prompt
prompt <a name="Propjobreg"> </a>
prompt ++ REGULAR JOBS (DBMS_JOB) <a href="#Propjob">PropagationJobs</a> <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt

select j.instance decinst, j.job, j.broken, r.instance runins, r.sid, r.spid, r.program, j.failures
from dba_jobs j,
  (select jr.job, jr.sid, p.spid, p.program, jr.instance
   from v$process p, dba_jobs_running jr, v$session s
   where s.sid=jr.sid and s.paddr=p.addr) r 
where r.job(+)=j.job and j.what like '%sys.dbms_aqadm.aq$_propaq(job)%'
order by j.instance, j.job;

prompt
prompt <a name="Propjoblrd"> </a>
prompt ++ SCHEDULER JOB LAST RUN DETAILS <a href="#Propjob">PropagationJobs</a> <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt

select r.job_name, r.status, r.instance_id, r.session_id, r.slave_pid, r.error#, r.run_duration
from DBA_SCHEDULER_JOB_RUN_DETAILS r,
   (select owner, job_name, max(log_id) max_id
   from DBA_SCHEDULER_JOB_RUN_DETAILS where job_name like '%AQ_JOB%'
   group by owner, job_name) f
where r.log_id = f.max_id;
prompt
prompt
prompt <a name="PropDic"> </a>
prompt ============================================================================================
prompt 
prompt ++ <b>PROPAGATION ( Dictionary )</b></a> ++ <a href="#Props">Propagations</a> <a href="#Top">Top</a> ++
prompt
prompt
col version heading 'Version'
col verified heading 'Verified'
col version format 99999999999

prompt ++ PROPAGATION SCHEDULES (AQ$_SCHEDULES) ++
prompt
SELECT JOBNO, JOB_NAME,JOBNO,FAILURES,LAST_ERROR_MSG,PROCESS_NAME, SID, SERIAL,INSTANCE, DESTINATION, START_TIME, DESTQ, S.OID 
FROM SYS.AQ$_SCHEDULES S ORDER BY DESTINATION;
prompt
prompt
prompt ++ PROPAGATION STATUS ++
prompt
SELECT * FROM SYS.AQ$_PROPAGATION_STATUS order by 
queue_id, destination;

prompt
SELECT queue_id, MIN(sequence), MAX(sequence) from SYS.AQ$_PROPAGATION_STATUS 
group by queue_id;
 
prompt
SELECT cq.name, pa.queue_id, pa.destination, pa.sequence, pa.status 
FROM SYS.AQ$_PROPAGATION_STATUS pa, dba_queues cq 
where cq.qid=pa.queue_id order by 
queue_id, destination;  
prompt
prompt
prompt ++ MESSAGE TYPES ++
prompt
SELECT * FROM SYS.AQ$_MESSAGE_TYPES order by
schema_name, queue_name, destination;
prompt
prompt
prompt ++ PENDING MESSAGES ++
prompt
select min(sequence), max(sequence), count(*) FROM SYS.AQ$_PENDING_MESSAGES;

prompt
prompt <a name="Notif"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>NOTIFICATIONS</b></a> ++ <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifPLD">Run Detail</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

col emon# heading 'EMON|Process'
col connection# heading 'Connection|Number'
col qosflags heading 'Service|Quality'
col job_name heading 'Job|Name'
col instance_id heading 'Scheduled|Instance'
col running_instance heading 'Running|Instance'
col session_id heading 'Session|Id'
col slave_os_process_id heading 'Slave OS|Process'
col elapsed_time heading 'Elapsed|Time'
col cpu_used heading 'Cpu|used'
col enabled heading 'Enabled'
col subscription_name heading 'Subscription|Name'
col location_name heading 'Location|Name'
col queryid heading 'Query|ID'
col querytexdt heading 'Query|Text'


prompt
prompt <a name="NotifReg"> </a>
prompt ++ REGISTERED SUBSCRIPTION ++  <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

select reg_id, subscription_name, r.location_name, emon#, connection#, qosflags, timeout, 
       reg_time, status, version, payload_callback, namespace, presentation, user_context, user#, 
       ntfn_grouping_class, ntfn_grouping_value, ntfn_grouping_type, ntfn_grouping_start_time, ntfn_grouping_repeat_count
from dba_subscr_registrations r, sys.loc$ l
where r.location_name = l.location_name (+)
order by reg_id;

prompt
prompt <a name="NotifPL"> </a>
prompt ++ PL/SQL NOTIFICATION JOBS ++  <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

select enabled, state, count(*) 
from DBA_SCHEDULER_JOBS s 
where s.JOB_NAME LIKE '%AQ$_PLSQL_NTFN%' 
group by enabled, state; 

prompt

select enabled, state, count(*) 
from DBA_SCHEDULER_JOBS s 
where UPPER(s.JOB_NAME) LIKE '%AQ$_PLSQL_NTFN%' 
group by enabled, state; 

prompt

select s.job_name, enabled, state, detached, s.instance_id, running_instance, session_id, slave_os_process_id, elapsed_time, cpu_used
from DBA_SCHEDULER_JOBS s LEFT OUTER JOIN DBA_SCHEDULER_RUNNING_JOBS r
    ON (s.job_name=r.job_name and s.owner=r.owner)
where s.JOB_NAME LIKE '%AQ$_PLSQL_NTFN%'
order by s.instance_id, s.job_name;

prompt
prompt <a name="NotifPLD"> </a>
prompt ++ PL/SQL NOTIFICATION JOB DETAILS ++ <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifPLD">Run Detail</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

select owner, status, error#, to_char(actual_start_date,'DD-Mon-YYYY') from dba_scheduler_job_run_details 
where job_name like 'AQ$_PLSQL_NTFN%' group by owner, status, error#, to_char(actual_start_date,'DD-Mon-YYYY'); 

prompt

select r.job_name, r.status, r.instance_id, r.session_id, r.slave_pid, r.error#, r.run_duration 
from DBA_SCHEDULER_JOB_RUN_DETAILS r, 
(select owner, job_name, max(log_id) max_id 
from DBA_SCHEDULER_JOB_RUN_DETAILS where UPPER(job_name) like 'AQ$_PLSQL_NTFN%' 
group by owner, job_name) f 
where r.log_id = f.max_id; 

prompt
prompt
prompt <a name="NotifEM"> </a>
prompt ++ EMAIL NOTIFICATION JOBS ++ <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifPLD">Run Detail</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

select owner, sender, recipient, event, count(*) 
from dba_scheduler_notifications 
group by owner, sender, recipient, event 
order by 1, 2, 3;

prompt 

select recipient, sender, owner||'.'||job_name job, job_subname, event, filter_condition, subject
from dba_scheduler_notifications
order by 1;

prompt
prompt ++ GROUPING ++
prompt

select REG_ID, SUBSCRIPTION_NAME, NTFN_GROUPING_CLASS, NTFN_GROUPING_VALUE, NTFN_GROUPING_TYPE, NTFN_GROUPING_START_TIME, NTFN_GROUPING_REPEAT_COUNT
from DBA_SUBSCR_REGISTRATIONS
order by REG_ID;

prompt
prompt
prompt <a name="NotifEM"> </a>
prompt ++ EMAIL NOTIFICATION JOBS ++ <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifPLD">Run Detail</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++
prompt

select owner, sender, recipient, event, count(*) 
from dba_scheduler_notifications 
group by owner, sender, recipient, event 
order by 1, 2, 3;

prompt 
select recipient, sender, owner||'.'||job_name job, job_subname, event, filter_condition, subject
from dba_scheduler_notifications
order by 1;

prompt
prompt <a name="DQChangeN"> </a>
prompt ============================================================================================
prompt
prompt ++ <b>DATABASE / QUERY CHANGE NOTIFICATION</b></a> ++ <a href="#Notif">Notifications</a> <a href="#NotifReg">Registered</a> <a href="#NotifPL">PL/SQL Jobs</a> <a href="#NotifPLD">Run Detail</a> <a href="#NotifEM">e-mail jobs</a> <a href="#DQChangeN">Database/Query Change Notification</a> <a href="#Top">Top</a> ++ 
prompt 
prompt 
prompt
prompt ++ CQN queries (DBA_CQ_NOTIFICATION_QUERIES) ++  
prompt 
select * from dba_cq_notification_queries order by username, regid; 
prompt
prompt
prompt ++ Registrations (DBA_CHANGE_NOTIFICATION_REGS) ++
prompt
select * from dba_change_notification_regs order by username, regid; 
prompt
prompt 
prompt ++ Total Count of Change registrations (CHNF) in REG$ ++
prompt
set feedback off
select count(*) "Total REG:CHNF Count" from sys.reg$ 
where subscription_name like 'CHNF%'; 
prompt
prompt
set feedback on
prompt ++ Oldest Change Notification Registrations (CHNF) in REG$ ++
prompt
select reg_id, subscription_name, location_name, status, timeout, state from reg$ 
where subscription_name like 'CHNF%' and reg_id = (select min(reg_id) from sys.reg$) 
order by 1; 
set feedback off
prompt
prompt
prompt ++  Count of Orphaned Change Notification Registrations (CHNF) in REG$ ++
prompt
select count(*) "Total CHNF Count" from sys.reg$ 
where subscription_name like 'CHNF%' and 
location_name not in (select location_name from sys.loc$);
prompt
prompt
set feedback on
prompt ++ Orphaned Change Notification Registrations (CHNF) in REG$ ++
prompt
select subscription_name, count(*) from sys.reg$ 
where subscription_name like 'CHNF%' and 
location_name not in (select location_name from sys.loc$) group by subscription_name; 
set feedback off
prompt
prompt <a name="Regloc"> </a>
prompt ============================================================================================
prompt
prompt ++ <b>REG$ and LOC$ Counts</b></a> ++
prompt
prompt
prompt
prompt ++ Total Counts for REG$ ++
prompt
select count(*) "Total REG" from reg$;
prompt
prompt
prompt ++ Total Counts for LOC$ ++
prompt
select count(*) "Total LOC" from loc$;
prompt
set feedback on 
prompt
prompt ++ Oldest Notification Registration ++
prompt 
select reg_id, subscription_name, location_name, status, reg_time, timeout, state from reg$ 
where reg_id = (select min(reg_id) from sys.reg$); 
prompt 
prompt
prompt ++ Orphan Registrations Count in REG$ ++
prompt
set feedback off
select count(*) "Total Orphaned REG Count" from sys.reg$ 
where location_name not in (select location_name from sys.loc$); 
prompt
set feedback on 
prompt
prompt ++ Orphan Registrations Group by Subscription Name in REG$ ++
prompt
select subscription_name, count(*) "Total Orphaned REG Count", min(reg_time) MIN_REG_TIME, max(reg_time) MAX_REG_TIME from sys.reg$ 
where location_name not in (select location_name from sys.loc$) group by subscription_name;  
prompt
prompt
prompt <a name="MGWHeading"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>MESSAGING GATEWAY (MGW)</b></a> ++ <a href="#MGWAsts">Status</a> <a href="#MGWAconn">Connection</a> <a href="#MGWAots">Options</a> <a href="#MGWAerr">Error</a> <a href="#Top">Top</a> ++
prompt
prompt
prompt <a name="MGWAgent"> </a>                                                                    
prompt ++ <b>MGW AGENT</b></a> ++ <a href="#MGWAsts">Status</a> <a href="#MGWAconn">Connection</a> <a href="#MGWAots">Options</a> <a href="#MGWAerr">Error</a> <a href="#Top">Top</a> ++
prompt

col agent_name heading 'Agent|Name'
col agent_status heading 'Status'
col agent_ping heading 'Ping'
col agent_job heading 'Job'
col max_memory heading 'Max.|Memory'
col max_threads heading 'Max.|Threads'
col initfile heading 'Init.|File'
col agent_start_time heading 'Start|Time'
col conntype heading 'Connection|Type'
col max_connections heading 'Max.|Connections'
col agent_user heading 'DB User|Connection'
col agent_database heading 'Connect|String'
col agent_instance heading 'Instance'

prompt <a name="MGWAsts"> </a>
prompt ++ STATUS ++ <a href="#MGWAgent">Agent</a> <a href="#Top">Top</a>
prompt

select agent_name, agent_status, agent_ping, agent_job, max_memory, max_threads, initfile, agent_start_time
from mgw_gateway order by agent_name;

prompt <a name="MGWAconn"> </a>
prompt ++ CONNECTION ++ <a href="#MGWAgent">Agent</a> <a href="#Top">Top</a>
prompt

select agent_name, conntype, max_connections, service, agent_user, agent_database, agent_instance
from mgw_gateway order by agent_name;

prompt <a name="MGWAots"> </a>
prompt ++ OPTIONS ++ <a href="#MGWAgent">Agent</a> <a href="#Top">Top</a>
prompt

select * from mgw_agent_options order by agent_name;

prompt <a name="MGWAerr"> </a>
prompt ++ ERRORS ++ <a href="#MGWAgent">Agent</a> <a href="#Top">Top</a>
prompt

select agent_name, agent_status, last_error_date, last_error_time, last_error_msg
from mgw_gateway order by agent_name;

prompt
prompt <a name="MGWFQ"> </a>                                                                    
prompt ++ <b>MGW FOREIGN QUEUES</b></a>  ++ <a href="#Top">Top</a> ++
prompt

select * from mgw_foreign_queues order by name;

prompt
prompt <a name="MGWLink"> </a>                                                                  
prompt ++ <b>MGW LINKS</b></a> ++ <a href="#MGWLG">Generic</a> <a href="#MGWLM">MQSeries</a> <a href="#MGWLT">TIB/Rendezvous</a> <a href="#Top">Top</a> ++
prompt

col link_name heading 'Link|Name'
col link_type heading 'Link|Type'
col link_comment heading 'Comment'
col queue_manager heading 'Queue|Manager'
col interface_type heading 'Interface|Type'
col max_connections heading 'Max.|Conn'
col inbound_log_queue heading 'Inbound|Queue'
col outbound_log_queue heading 'Outbound|Queue'

prompt <a name="MGWLG"> </a>
prompt ++ GENERIC ++ <a href="#MGWLink">Links</a> <a href="#Top">Top</a>
prompt

col link_name heading 'Link|Name'
col link_type heading 'Link|Type'
col link_comment heading 'Comment'

select * from mgw_links order by link_name;

prompt <a name="MGWLM"> </a>
prompt ++ Websphere MQ Series Links ++ <a href="#MGWLink">Links</a> <a href="#Top">Top</a>
prompt

col queue_manager heading 'Queue|Manager'
col interface_type heading 'Interface|Type'
col max_connections heading 'Max.|Conn,'
col inbound_log_queue heading 'Inbound|Queue'
col outbound_log_queue heading 'Outbound|Queue'

select * from mgw_mqseries_links order by link_name;

prompt <a name="MGWLT"> </a>
prompt ++ TIB/Rendezvous Links ++ <a href="#MGWLink">Links</a> <a href="#Top">Top</a>
prompt

select * from mgw_tibrv_links order by link_name;

prompt
prompt <a name="MGWProps"> </a>                                                                    
prompt ++ <b>MGW PROPAGATIONS</b></a> ++ <a href="#MGWSch">Scheduled</a>  <a href="#MGWJobs">Jobs</a> <a href="#Top">Top</a> ++
prompt

col schedule_id heading 'Schedule|Id'
col schedule_disabled heading 'Schedule|Disabled'
col propagation_type heading 'Propagation|Type'
col propagation_window heading 'Propagation|Window'
col job_name heading 'Job|Name'
col agent_name heading 'Agent|Name'
col prop_style heading 'Prop|style'
col link_name heading 'Link|Name'
col poll_interval heading 'Poll|Interval'
col propagated_msgs heading 'Prop.|Msgs'
col exceptionq_msgs heading 'Excpt.|Msgs'

prompt
prompt <a name="MGWSch"> </a>
prompt ++ SCHEDULED ++ <a href="#MGWProps">Progations</a> <a href="#Top">Top</a>
prompt

select schedule_id, source, destination, schedule_disabled, propagation_type, latency, start_date, propagation_window
from mgw_schedules order by 1;  

prompt <a name="MGWJobs"> </a>
prompt ++ JOBS ++ <a href="#MGWProps">Progations</a> <a href="#Top">Top</a>
prompt

select job_name, source, destination, enabled, agent_name, status, propagation_type, prop_style
from mgw_jobs order by 1,2,3;

prompt
select job_name, source, destination, link_name, poll_interval, propagated_msgs, exceptionq_msgs, rule, transformation, options
from mgw_jobs order by 1,2,3;

prompt
select job_name, source, destination, failures, last_error_date, last_error_msg, exception_queue
from mgw_jobs order by 1,2,3;

prompt
prompt <a name="MGWSUB"> </a>
prompt ++ SUBSCRIBERS ++ <a href="#MGWProps">Propagations</a> <a href="#Top">Top</a> ++
prompt

  select * from MGW_SUBSCRIBERS order by
  queue_name, destination;

prompt
prompt <a name="QMONstats"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>QMON STATISTICS</b></a> ++ <a href="#QMST">Tasks</a> <a href="#QMSTS">Tasks Statistics</a> <a href="#QMSM">Monitor</a> <a href="#QMSS">Slave</a> <a href="#QMSQ">Per Queue</a> <a href="#Top">Top</a>  ++
prompt

col queue_name HEADING 'Queue Name' format a40
col inst_id heading 'Inst' format 99
col task_name heading 'Name'
col task_number heading 'Number'
col task_type heading 'Type'
col task_submit_time heading 'Submit|Time'
col task_ready_time heading 'Ready|time'
col task_expiry_time heading 'Expiry|Time'
col task_start_time heading 'Start|Time'
col task_status heading 'Status'
col server_name heading 'Server|Name'
col num_runs heading 'Runs'
col num_failures heading 'Failures'
col last_created_tasknum heading 'Last|Created|Task'
col num_tasks heading 'Num|Tasks'
col total_task_run_time heading 'Total|Run Time'
col total_task_runs heading 'Total|Runs'
col total_task_failures heading 'Total|Failures'
col metric_type heading 'Metric|Type' format a40 wrap
col metric_value heading 'Metric'
col last_failure heading 'Last|Fail'
col last_failure_time heading 'Last|Fail|Time'
col last_failure_tasknum heading 'Last|Fail|TaskNum'
col remark heading 'Remark' format a40 wrap
col qmnc_pid heading 'PID'
col num_servers heading 'Num|Servers'
col last_server_start_time heading 'Last Server|Start Time'
col last_server_pid heading 'Last|Server'
col next_wakeup_time heading 'Next|Wakeup'
col next_ready_time heading 'Next|Ready'
col next_expiry_time heading 'Next|Expiry'
col last_wait_time heading 'Last Wait|time'
col last_failure heading 'Last|Failure'
col last_failure_time heading 'Time Last|Failure'
col max_task_latency heading 'Max|Latency'
col min_task_latency heading 'Min|Latency'
col total_task_latency heading 'Total|Latency'
col total_tasks_executed heading 'Total Tasks|Executed'
col max_servers heading 'Max|Severs'
col server_pid heading 'PID'
col server_name heading 'Server|Name'
col server_start_time heading 'Start|time'
col task_start_time heading 'Task Start|Time'
col max_latency heading 'Max|Latency'
col min_latency heading 'Min|Latency'
col total_latency heading ''
col num_tasks heading 'Num|Tasks'
col last_failure_task heading 'Last Fail|Task'
col type HEADING 'Type'
col status HEADING 'Status'
col next_service_time heading 'Next|Service'
col window_end_time heading 'Window|Ends'
col total_runs heading 'Runs'
col total_latency heading 'Latency'
col total_elapsed_time heading 'Elapsed|Time'
col total_cpu_time heading 'CPU|Time'
col tmgr_rows_processed heading 'Mgr|Rows|Processed'
col tmgr_elapsed_time heading  'Mgr|Elapsed|Time'
col tmgr_cpu_time heading 'Mgr|CPU|Time'
col last_tmgr_processing_time heading 'Last Mgr|Processing' 
col deqlog_rows_processed heading 'Deqlog|Rows|Processed'
col deqlog_processing_elapsed_time heading 'DeqLog|Elapsed|Time'
col deqlog_processing_cpu_time heading  'DeqLog|CPU|Time'
col last_deqlog_processing_time heading 'Last DeqLog|Processing'
col dequeue_index_blocks_freed heading 'Dequeue Index|blocks freed'
col history_index_blocks_freed heading 'History Index|blocks freed'
col time_index_blocks_freed heading 'Time Index|blocks freed'
col index_cleanup_count heading 'Index cleanup|Count'
col index_cleanup_elapsed_time heading 'Index cleanup|Elapsed Time'
col index_cleanup_cpu_time heading 'Index cleanup|CPU time'
col last_index_cleanup_time heading 'Index cleanup|Time'

prompt
prompt <a name="QMST"> </a>
prompt ++ TASKS ++ <a href="#QMONstats">QMON Stats</a> <a href="#Top">Top</a>  ++
prompt 

select * from gv$qmon_tasks order by  inst_id, task_type, task_name, task_number;

prompt
prompt <a name="QMSTS"> </a>
prompt ++ TASKS STATISTICS ++ <a href="#QMONstats">QMON Stats</a> <a href="#Top">Top</a>  ++
prompt 

select * from gv$qmon_task_stats order by inst_id, task_type, task_name; 

prompt
prompt <a name="QMSM"> </a>
prompt ++ QUEUE MONITOR STATISTICS ++ <a href="#QMONstats">QMON Stats</a> <a href="#Top">Top</a>  ++
prompt 
col instance heading 'Instance'
col qmnc_pid heading 'QMNC PID'
col server_pid heading 'SERVER PID'
select * from gv$qmon_coordinator_stats order by inst_id;

prompt
prompt <a name="QMSS"> </a>
prompt ++ QUEUE SERVER STATISTICS ++ <a href="#QMONstats">QMON Stats</a> <a href="#Top">Top</a>  ++
prompt 

select * from gv$qmon_server_stats order by inst_id, qmnc_pid, server_name;

prompt
prompt <a name="QMSQ"> </a>
prompt ++ PER QUEUE STATISTICS ++ <a href="#QMONstats">QMON Stats</a> <a href="#Top">Top</a>  ++
prompt 

select qt.schema||'.'||qt.name queue_name, inst_id, type, status,  
       total_runs, total_latency, total_elapsed_time, total_cpu_time,
       tmgr_rows_processed, tmgr_elapsed_time, tmgr_cpu_time, last_tmgr_processing_time, 
       deqlog_rows_processed, deqlog_processing_elapsed_time, deqlog_processing_cpu_time, last_deqlog_processing_time,
       dequeue_index_blocks_freed, history_index_blocks_freed, time_index_blocks_freed, 
       index_cleanup_count, index_cleanup_elapsed_time, index_cleanup_cpu_time, last_index_cleanup_time,
       next_service_time, window_end_time
from gv$persistent_qmn_cache, system.aq$_queue_tables qt
where queue_table_id = qt.objno
order by queue_name, inst_id;

prompt
prompt <a name="Notifstats"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>NOTIFICATION STATISTICS</b></a> ++ <a href="#NoOCIstats">Normal</a> <a href="#BGEMON">EMON</a> <a href="#Top">Top</a>  ++
prompt

col all_emon_servers heading 'EMON slaves|that server|registration'
col num_ntfns heading 'Number of|notifications'
col num_grouping_ntfns heading 'Number of|Grouping|notifications'
col total_payload_bytes_sent heading 'Total|Payload|Bytes Sent'
col total_plsql_exec_time heading 'PL/SQL|Callback|Exec Time'
col last_ntfn_start_time heading 'Last|Notification|Start'
col last_ntfn_sent_time heading 'Last|Notification|Sent'
col total_emon_latency heading 'Time to|process|notifications'
col last_err heading 'Last|Error'
col last_err_time heading 'Last|Error|Time'
col last_update_time heading 'Last|Update|Time'
col total_exec_time heading 'Total|Exec|Time'
col client_id heading 'Client|ID'
col emon_id heading 'EMON|ID'
col notification_state heading 'State'
col num_message_sent heading 'Messages|Sent'
col num_bytes_sent heading 'Bytes|Sent'
col num_message_received heading 'Messages|Received'
col last_send_time heading 'Last Sent|Time'
col last_receive_time heading 'Last Received|Time'
col connect_time heading 'Connect|Time'
col disconnect_time heading 'Disconnect|Time'
col last_error heading 'Last|Error'

prompt
prompt <a name="NoOCIstats"> </a>
prompt ++ NORMAL NOTIFICATIONS ++ <a href="#Notifstats">Notification Stats</a> <a href="#Top">Top</a>  ++
prompt 

select s.inst_id, s.reg_id, r.subscription_name, s.emon#, num_ntfns, num_grouping_ntfns, total_payload_bytes_sent,
       last_ntfn_start_time, last_ntfn_sent_time, total_emon_latency, last_err, last_err_time, all_emon_servers, last_update_time
from gv$subscr_registration_stats s, dba_subscr_registrations r
where s.reg_id=r.reg_id (+)
order by s.inst_id, s.reg_id;

prompt
prompt <a name="BGEMON"> </a>
prompt ++ <b>EMON STATISTICS</b></a> ++ <a href="#BCKstats">Background Processes</a> <a href="#Top">Top</a>  ++
prompt

select * from gv$emon; 

prompt
prompt
prompt <a name="Qstats"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>QUEUE STATISTICS</b></a> ++ <a href="#Perq">Persistent</a>  <a href="#Buffq">Buffered</a> <a href="#Top">Top</a>  ++
prompt

col queue_schema HEADING 'Owner' format a10
col queue_id HEADING 'Id' format 999999999
col queue_state HEADING 'State' format a10 wrap
col startup_time HEADING 'Startup'
col num_msgs    HEADING 'Current|Number of Msgs|in Queue'
col cnum_msgs   HEADING 'Cumulative|Total Msgs|for Queue'
col spill_msgs  HEADING 'Current|Spilled Msgs|in Queue'
col cspill_msgs HEADING 'Cumulative|Total Spilled|for Queue'
col dbid HEADING 'Database|Identifier'
col total_spilled_msg HEADING 'Cumulative|Total Spilled|Messages'
col enqueued_msgs heading 'Total msgs|enqueued'
col dequeued_msgs heading 'Total msgs|dequeued'
col browsed_msgs heading 'Total msgs|browsed'
col waiting heading 'Current Msgs| in WAIT Status'
col ready heading 'Current Msgs| in READY Status'
col expired heading 'Current Msgs| in EXPIRED Status'
col enqueued_expiry_msgs heading 'Total msgs|enqueued with|expiry'
col enqueued_delay_msgs heading 'Total msgs|enqueued with|delay'
col msgs_made_expired heading 'Total msgs|made expired'
col msgs_made_ready heading 'Total msgs|made ready'
col first_activity_time heading 'First|Activity|Time'
col last_enqueue_time heading 'Last|Enqueue|Time'
col last_dequeue_time heading 'Last|Enqueue|Time'
col last_tm_ready_time heading 'Last time|Msg ready|by TM'
col last_tm_expiry_time heading 'Last time|Msg expired|by TM'
col total_wait heading 'Total Time|all READY|messages'
col average_wait heading 'Avg Time|all READY|messages'
col elapsed_enqueue_time heading 'Elapsed|Enqueue|time'
col elapsed_dequeue_time heading 'Elapsed|Dequeue|time'
col elapsed_transformation_time heading 'Elapsed|Transformation|time'
col elapsed_rule_evaluation_time heading 'Elapsed|Rule eval.|time'
col queue_recovered heading 'Recovered'
col large_txn_disk_deletes heading 'Large Txn|Disk Deletes'
col small_txn_disk_deletes heading 'Small Txn|Disk Deletes'
col small_txn_disk_locks heading 'Small Txn|Disk Locks'
col current_disk_del_txn_count heading 'Current|Disk deletes|Txn count'
col current_deq_txn_count heading 'Current|Dequeue txn|Count'
col large_txn_size heading 'Large|Txn size'
col deqlog_array_size heading 'Size|Dequeue Log'

prompt
prompt <a name="Perq"> </a>
prompt ++ PERSISTENT QUEUES ++ <a href="#Qstats">Queue Statistics</a> <a href="#Top">Top</a>  ++
prompt 

select inst_id, queue_schema||'.'||queue_name Queue, queue_id, enqueued_msgs, dequeued_msgs, browsed_msgs,
     waiting, ready, expired, enqueued_expiry_msgs, enqueued_delay_msgs, msgs_made_ready, msgs_made_expired,
     first_activity_time, last_enqueue_time, last_dequeue_time, last_tm_ready_time, last_tm_expiry_time, 
     total_wait, average_wait, elapsed_enqueue_time, elapsed_dequeue_time, elapsed_transformation_time, 
     elapsed_rule_evaluation_time
from gv$persistent_queues pq, gv$aq
where queue_id=qid
order by 1,2;

prompt

select pq.inst_id, queue_schema||'.'||queue_name Queue, pq.queue_id, queue_recovered, 
     large_txn_disk_deletes, small_txn_disk_deletes, small_txn_disk_locks, 
     current_disk_del_txn_count, current_deq_txn_count, large_txn_size, deqlog_array_size
from gv$persistent_queues pq, x$kwqdlstat dq
where pq.inst_id=dq.inst_id and pq.queue_id=dq.queue_id
order by 1,2;

prompt 
prompt ++ PERSISTENT QUEUES ( Ready and Expired > 1, Enqueued > 100 ) ++
prompt

select inst_id, queue_schema, queue_name, queue_id, enqueued_msgs, dequeued_msgs, browsed_msgs,
     waiting, ready, expired, enqueued_expiry_msgs, enqueued_delay_msgs, msgs_made_ready, msgs_made_expired 
from gv$persistent_queues, gv$aq
where queue_id=qid and ( ready > 1 or expired > 1 or enqueued_msgs > 100 )
order by 1,2,3;

prompt
prompt <a name="Buffq"> </a>
prompt ++ BUFFERED QUEUES ++ <a href="#Qstats">Queue Statistics</a> <a href="#Top">Top</a>  ++
prompt 

select inst_id, queue_schema||'.'||queue_name Queue, queue_id, queue_state, startup_time, 
       num_msgs, spill_msgs, waiting, ready, expired, cnum_msgs, cspill_msgs, expired_msgs,
       total_wait, average_wait
from gv$buffered_queues bq, gv$aq
where queue_id=qid
order by 1,2;

prompt

select bq.inst_id, queue_schema||'.'||queue_name Queue, bq.queue_id, queue_recovered, 
     large_txn_disk_deletes, small_txn_disk_deletes, small_txn_disk_locks, 
     current_disk_del_txn_count, current_deq_txn_count, large_txn_size, deqlog_array_size
from gv$buffered_queues bq, x$kwqdlstat dq
where bq.inst_id=dq.inst_id and bq.queue_id=dq.queue_id
order by 1,2,3;

prompt
prompt <a name="Pubstats"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>PUBLISHERS STATISTICS</b></a> ++ <a href="#Perpub">Persistent</a>  <a href="#Buffpub">Buffered</a> <a href="#Top">Top</a>  ++
prompt

col queue_schema HEADING 'Owner' format a10
col queue_name HEADING 'Queue Name' format a30
col startup_time HEADING 'Startup'
col num_msgs    HEADING 'Current|Number of Msgs|for Publisher'
col cnum_msgs   HEADING 'Cumulative|Total Msgs|for Publisher'
col sender_name HEADING 'Name'
col sender_address HEADING 'Address' format a40 wrap
col publisher_state HEADING 'State' format a20
col last_enqueued_msg HEADING 'Last enqueued|Msgs Id'
col unbrowsed_msgs HEADING 'Unbrowsed|Msgs'
col overspilled_msgs HEADING 'Overspilled|Mesgs'
col memused HEADING 'Memory|Used(Kb)'
col publisher_name heading 'Name'
col publisher_address heading 'Address'

prompt
prompt <a name="Perpub"> </a>
prompt ++ PERSISTENT PUBLISHERS ++ <a href="#Pubstats">Publishers</a> <a href="#Top">Top</a>  ++
prompt 

select * from gv$persistent_publishers 
order by inst_id, queue_schema, queue_name, publisher_name, publisher_address;

prompt
prompt <a name="Buffpub"> </a>
prompt ++ BUFFERED PUBLISHERS ++ <a href="#Pubstats">Publishers</a> <a href="#Top">Top</a>  ++
prompt
prompt   Note: For Streams Buffered publishers not populated when CCA optimization is in effect
prompt

select inst_id, queue_schema, queue_name, sender_name, sender_address, publisher_state,
       num_msgs, cnum_msgs, last_enqueued_msg, unbrowsed_msgs, overspilled_msgs, memory_usage/1024 memused
from gv$buffered_publishers
order by 1,2,3,4,5;

prompt
prompt <a name="substats"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>SUBSCRIBERS STATISTICS</b></a> ++ <a href="#Persubs">Persistent</a>  <a href="#Buffsubs">Buffered</a> <a href="#Top">Top</a>  ++
prompt

col queue_schema HEADING 'Owner' format a10
col queue_name HEADING 'Queue Name' format a30
col startup_time HEADING 'Startup'
col num_msgs    HEADING 'Current|Number of Msgs|for Subscriber'
col cnum_msgs   HEADING 'Cumulative|Total Msgs|for Subscriber'
col subscriber_name HEADING 'Name'
col subscriber_address HEADING 'Address' format a40 wrap
col subscriber_type HEADING 'Type' format a20
col message_lag HEADING 'Subscriber|Delay'
col total_dequeued_msg HEADING 'Total Msgs|Dequeued'
col total_spilled_msg HEADING 'Total Msgs|Spilled'
col last_browsed_num HEADING 'SCN last|browsed Msgs'
col last_dequeued_num HEADING 'SCN last|dequeued Msgs'
col current_enq_seq HEADING 'SCN current|enqueued Msg'
col expired_msgs heading 'Total msgs|expired'

prompt <a name="Buffsubs"> </a>
prompt ++ PERSISTENT SUBSCRIBERS ++ <a href="#substats">Subscribers</a> <a href="#Top">Top</a>
prompt

select inst_id, queue_id, queue_schema, queue_name, subscriber_name, subscriber_address, first_activity_time,
   enqueued_msgs, dequeued_msgs, browsed_msgs, expired_msgs, dequeued_msg_latency, last_enqueue_time, last_dequeue_time   
from gv$persistent_subscribers
order by inst_id, queue_schema, queue_name, subscriber_name, subscriber_address;

prompt <a name="Buffsubs"> </a>
prompt ++ BUFFERED SUBSCRIBERS ++ <a href="#substats">Subscribers</a> <a href="#Top">Top</a>
prompt
prompt   Note: For Streams Buffered Subscribers statistics are zero when CCA optimization is in effect
prompt

select inst_id, queue_schema, queue_name, subscriber_name, subscriber_address, subscriber_type,
       message_lag, num_msgs, cnum_msgs, total_dequeued_msg, total_spilled_msg, expired_msgs
       startup_time, last_browsed_num, last_dequeued_num, current_enq_seq
from gv$buffered_subscribers
order by 1,2,3,4,5;

prompt
prompt <a name="subprop"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>PROPAGATION STATISTICS</b></a> ++ <a href="#schstat">Scheduled</a> <a href="#Buffsend">Buffered Sender</a> <a href="#Buffrec">Buffered Receiver</a> <a href="#Top">Top</a>  ++
prompt

col dblink Heading 'Destination|Database|Link'
col total_msgs HEADING 'Total|Messages'
col total_bytes HEADING 'Total|Bytes'
col elapsed_dequeue_time HEADING 'Elapsed|Dequeue Time|(CentiSecs)'
col elapsed_pickle_time HEADING 'Total Time|(CentiSecs)'
col elapsed_propagation_time heading 'Elapsed|Propagation Time|(CentiSecs)'
col last_msg_latency heading 'Last Msg|Latency'
col last_msg_enqueue_time heading 'Last Msg|Enqueue Time'
col last_msg_propagation_time  heading 'Last Msg|Propagation Time'
col src_dbname heading 'Source|DB Name'
col last_received_msg heading 'Last|Received|Msg'
col elapsed_enqueue_time heading 'Elapsed|Enqueue Time|(CSecs)'
col elapsed_unpickle_time heading 'Elapsed|Unpickle|Time(CSecs)'
col elapsed_pickle_time heading 'Elapsed|Pickle|Time(CSecs)'
col elapsed_rule_time heading 'Elapsed|Rule|Time(CSecs)'
col total_time heading 'Total Time|Executing (Secs)'
col total_number heading 'Total Msgs|Propagated'
col total_bytes heading 'Total Bytes|Propagated'
col avg_size heading 'Avg. message|size(bytes)'
col avg_size heading 'Avg. seconds|to propagate|1 Message'

prompt
prompt <a name="schstat"> </a>
prompt ++ SCHEDULES STATISTICS ++ <a href="#subprop">Propagation</a> <a href="#Top">Top</a>  ++
prompt

select schema||'.'||qname origin, destination, message_delivery_mode, total_time, total_number, total_bytes, 
 avg_size, avg_time, elapsed_dequeue_time, elapsed_pickle_time
from dba_queue_schedules order by origin, destination, message_delivery_mode;

prompt 
prompt <a name="Buffsend"> </a>
prompt ++ BUFFERED SENDER ++ <a href="#subprop">Propagation</a> <a href="#Top">Top</a>  ++
prompt

select inst_id, queue_schema||'.'||queue_name origin, dst_queue_schema||'.'||dst_queue_name destination, dblink, 
   total_msgs, total_bytes,  elapsed_dequeue_time, elapsed_pickle_time,  elapsed_propagation_time,
   last_msg_latency, last_msg_enqueue_time, last_msg_propagation_time
from gv$propagation_sender order by 1,2,3;   

prompt
prompt <a name="Buffrec"> </a>
prompt ++ BUFFERED RECEIVER ++ <a href="#subprop">Propagation</a> <a href="#Top">Top</a>  ++
prompt

select inst_id, src_queue_schema||'.'||src_queue_name origin, dst_queue_schema||'.'||dst_queue_name destination, src_dbname
   last_received_msg, total_msgs, elapsed_enqueue_time, elapsed_unpickle_time,  elapsed_rule_time
from gv$propagation_receiver order by inst_id, src_queue_schema, src_queue_name;  

prompt
prompt <a name="Waits"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>SESSION WAITS and EVENTS</b></a> ++ <a href="#WaitsSW">Session Wait</a> <a href="#WaitEv">Events</a> <a href="#CPU">CPU</a> <a href="#Top">Top</a>  ++
prompt
prompt
prompt <a name="WaitsSW"> </a>                                                                    
prompt ++ <b>SESSION WAIT</b></a> ++ <a href="#Waits">Waits</a> <a href="#Top">Top</a>  ++
prompt
prompt
prompt ++ Session Wait - Qmon Coordinator ++
prompt
select s.inst_id, SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME, p.spid,
s.sid,s.event,s.p1, s.p1text,s.p2, s.p2text,s.p3, s.p3text, s.wait_time, s.seconds_in_wait, s.state 
from gv$process p, gv$session s
where s.inst_id=p.inst_id and
s.paddr=p.addr
and s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like '%QM%')
order by s.inst_id,process_name;
prompt
prompt
prompt ++ Session Wait - Qmon Slaves ++
prompt
select s.inst_id, SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME, p.spid,
s.sid,s.event,s.p1, s.p1text,s.p2, s.p2text,s.p3, s.p3text, s.wait_time, s.seconds_in_wait, s.state 
from gv$process p, gv$session s
where s.inst_id=p.inst_id and
s.paddr=p.addr
and s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like 'Q0%')
order by s.inst_id,process_name;
prompt
prompt
prompt ++ Session Wait  - EMON ++
prompt
select em.inst_id, em.emon#, em.status, em.server_type, 
s.sid,s.event,s.p1, s.p1text,s.p2, s.p2text,s.p3, s.p3text, s.wait_time, s.seconds_in_wait, s.state
from gv$session s,gv$emon em
where s.inst_id=em.inst_id and
s.sid=em.sid
order by s.inst_id, em.emon#;
prompt
prompt
prompt <a name="WaitEv"> </a>                                                                    
prompt ++ <b>SESSION EVENTS</b></a> ++ <a href="#Waits">Waits</a> <a href="#Top">Top</a>  ++
prompt
prompt
prompt ++ Wait Events - Qmon Coordinator ++
prompt
select s.inst_id, SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME, e.event, e.total_waits,
 e.total_timeouts, e.time_waited, e.average_wait, e.max_wait 
from gv$session_event e, gv$process p, gv$session s
where e.inst_id=s.inst_id and
e.sid=s.sid and
s.paddr=p.addr
and s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like '%QM%')
order by s.inst_id,process_name,e.time_waited desc;
prompt
prompt
prompt ++ Wait Events - Qmon Slaves ++
prompt
select s.inst_id, SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME, e.event, e.total_waits,
 e.total_timeouts, e.time_waited, e.average_wait, e.max_wait 
from gv$session_event e, gv$process p, gv$session s
where e.inst_id=s.inst_id and
e.sid=s.sid and
s.paddr=p.addr
and s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like '%Q0%')
order by s.inst_id,process_name,e.time_waited desc;
prompt
prompt
prompt ++ Wait Events - EMON ++
prompt

select em.inst_id, em.emon#, em.status, em.server_type, e.event, e.total_waits,
 e.total_timeouts, e.time_waited, e.average_wait, e.max_wait 
from gv$session_event e,gv$emon em
where e.inst_id=em.inst_id and
e.sid=em.sid
order by em.inst_id, em.emon#,e.time_waited desc;

prompt
prompt <a name="CPU"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>QMON SESSION CPU</b></a> ++ <a href="#CPUS1">CPU 1</a> <a href="#CPUS2">CPU 2</a>  <a href="#Top">Top</a>  ++
prompt
prompt
prompt <a name="CPUS1"> </a>                                                                    
prompt ++ <b>QMON CPU 1</b></a> ++ <a href="#Top">Top</a>  ++
col value HEADING 'Value' format 999999999999999
   select
      s.sid,s.inst_id,sn.serial#,n.name,
      SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) PROCESS_NAME,value, sysdate
   from
      gv$statname n,gv$sesstat s,gV$SESSION sn
   where
      s.sid=sn.sid and
      n.STATISTIC# = s.STATISTIC# and
      s.inst_id=sn.inst_id and
      name like '%CPU%' and
      s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like '%QM%' 
          or SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like 'Q0%'
          or SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like 'AQ%') and value > 0
   order by 2,5,4 asc;

prompt
prompt ++ Total CPU For All Sessions - Run1 ++
prompt

   Select s.inst_id, name, sum(value) "Total CPU"
   from
      gv$statname n,gv$sesstat s
   where
      n.STATISTIC# = s.STATISTIC# and
      name like '%CPU%'
   group by s.inst_id, name
   order by s.inst_id, name;

exec dbms_lock.sleep(30);

prompt
prompt <a name="CPUS2"> </a>                                                                    
prompt ++ <b>QMON CPU 2 (30 Second Delay) </b></a> ++ <a href="#Top">Top</a>  ++
prompt

   select
      s.sid,s.inst_id,sn.serial#,n.name,
      SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) PROCESS_NAME,value, sysdate
   from
      gv$statname n,gv$sesstat s,gV$SESSION sn
   where
      s.sid=sn.sid and
      n.STATISTIC# = s.STATISTIC# and
      s.inst_id=sn.inst_id and
      name like '%CPU%' and
      s.sid in (select SID from gV$SESSION sn where 
             SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like '%QM%' 
          or SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like 'Q0%'
          or SUBSTR(sn.PROGRAM,INSTR(Sn.PROGRAM,'(')+1,4) like 'AQ%') and value > 0
   order by 2,5,4 asc;

prompt
prompt ++ Total CPU For All Sessions - Run2 (30 Second Delay) ++
prompt


   Select s.inst_id, name, sum(value) "Total CPU"
   from
      gv$statname n,gv$sesstat s
   where
      n.STATISTIC# = s.STATISTIC# and
      name like '%CPU%'
   group by s.inst_id, name
   order by s.inst_id, name;

prompt
prompt <a name="History"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>HISTORY</b></a> ++ <a href="#hprpmin">Propagation waits Last 30 min</a> <a href="#hprpday">Propagation waits Last day</a> <a href="#hbufq">Buffered Queues</a> <a href="#hbufsubs">Buffered Subscribers</a>  <a href="#Top">Top</a>  ++
prompt

col busy format a4
col percentage format 999d9
col event wrapped
col snap_id format 999999 HEADING 'Snap ID'
col BEGIN_INTERVAL_TIME format a28 HEADING 'Interval|Begin|Time'
col END_INTERVAL_TIME format a28 HEADING 'Interval|End|Time'
col INSTANCE_NUMBER HEADING 'Instance|Number'
col Queue format a28 wrap Heading 'Queue|Name'
col num_msgs    HEADING 'Current|Number of Msgs|in Queue'
col cnum_msgs   HEADING 'Cumulative|Total Msgs|for Queue'
col spill_msgs  HEADING 'Current|Spilled Msgs|in Queue'
col cspill_msgs HEADING 'Cumulative|Total Spilled|for Queue'
col dbid        HEADING 'Database|Identifier'
col total_spilled_msg HEADING 'Cumulative|Total Spilled|Messages'


prompt <a name="hprpmin"> </a>
prompt ++ PROPAGATION WAITS FOR LAST 30 MINUTES ++ <a href="#History">History</a> <a href="#Top">Top</a>
prompt

BREAK ON process_name;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON process_name;

SELECT props.process_name,
       ash_cp.event_count, ash_tot.total_count, 
       ash_cp.event_count*100/ash_tot.total_count percentage, 
       'YES' busy,
       ash_cp.event
FROM
(select inst_id, session_id, session_serial#, event,
             count(sample_time) as event_count
 from  gv$active_session_history
 where sample_time > sysdate - 30/24/60
 group by inst_id, session_id, session_serial#, event) ash_cp,       
(select inst_id, count(distinct sample_time) as total_count
 from  gv$active_session_history
 where sample_time > sysdate - 30/24/60
 group by inst_id) ash_tot,
(select schema, qname, destination, process_name, instance, session_id, count(*) counting
 from dba_queue_schedules
 group by instance, session_id, schema, qname, destination, process_name) props     
WHERE ash_tot.inst_id=ash_cp.inst_id
  AND props.instance=ash_cp.inst_id
  AND substr(props.session_id,1,instr(props.session_id,',')-1) = ash_cp.session_id 
ORDER BY props.process_name;

prompt <a name="hprpday"> </a>
prompt ++ PROPAGATION WAITS FOR LAST DAY ++ <a href="#History">History</a> <a href="#Top">Top</a>
prompt

SELECT props.process_name,
       ash_cp.event_count, ash_tot.total_count, 
       ash_cp.event_count*100/ash_tot.total_count percentage, 
       'YES' busy,
       ash_cp.event
FROM
(select inst_id, session_id, session_serial#, event,
             count(sample_time) as event_count
 from  gv$active_session_history
 where sample_time > sysdate - 1
 group by inst_id, session_id, session_serial#, event) ash_cp,       
(select inst_id, count(distinct sample_time) as total_count
 from  gv$active_session_history
 where sample_time > sysdate - 1
 group by inst_id) ash_tot,
(select schema, qname, destination, process_name, instance, session_id, count(*) counting
 from dba_queue_schedules
 group by instance, session_id, schema, qname, destination, process_name) props     
WHERE ash_tot.inst_id=ash_cp.inst_id
  AND props.instance=ash_cp.inst_id
  AND substr(props.session_id,1,instr(props.session_id,',')-1) = ash_cp.session_id 
ORDER BY props.process_name;

prompt <a name="hbufq"> </a>
prompt ++ BUFFERED QUEUE HISTORY FOR LAST DAY ++ <a href="#History">History</a> <a href="#Top">Top</a>
prompt

select s.begin_interval_time,s.end_interval_time , 
   bq.snap_id, 
   bq.num_msgs, bq.spill_msgs, bq.cnum_msgs, bq.cspill_msgs,
   bq.queue_schema||'.'||bq.queue_name Queue,
   bq.queue_id, bq.startup_time,bq.instance_number,bq.dbid
from   dba_hist_buffered_queues bq, dba_hist_snapshot s 
where  bq.snap_id=s.snap_id   and s.end_interval_time >= systimestamp-1 
order by bq.queue_schema,bq.queue_name,s.end_interval_time;

prompt <a name="hbufsubs"> </a>
prompt ++ BUFFERED SUBSCRIBER HISTORY FOR LAST DAY ++ <a href="#History">History</a> <a href="#Top">Top</a>
prompt

select s.begin_interval_time,s.end_interval_time , 
   bs.snap_id,bs.subscriber_id, 
   bs.num_msgs, bs.cnum_msgs, bs.total_spilled_msg,
   bs.subscriber_name,subscriber_address,
   bs.queue_schema||'.'||bs.queue_name Queue,
   bs.startup_time,bs.instance_number,bs.dbid
from   dba_hist_buffered_subscribers bs, dba_hist_snapshot s 
where    bs.snap_id=s.snap_id and s.end_interval_time >= systimestamp-1 
order by    bs.queue_schema,bs.queue_name,bs.subscriber_id,s.end_interval_time;

prompt
prompt
prompt <a name="Confother"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>OTHER</b></a> ++ <a href="#Strminf">Streams Pool</a> <a href="Addaqparam">Additional AQ Parameters</a> <a href="#DBSGA"> SGA Components</a> <a href="#Top">Top</a> ++
prompt

col total_memory_allocated Head 'Total Memory|Allocated'
col current_size  Head 'Streams Pool|Size'
col SGA_TARGET_VALUE Head 'SGA_TARGET|Value'
col used Head 'Total Memory|Allocated (MB)'
col max  Head 'Streams Pool|Size(MB)'
col pct Head 'Percent Memory|Used'
col shrink_phase Head 'Shrink|Phase'
col Advice_disabled Head 'Advice|Disabled'
col name heading 'NAME'
col value heading 'VALUE'
 
prompt
prompt <a name="Strminf"> </a>
prompt ++ Streams Pool Information ++ <a href="#Confother">Other</a> <a href="#Top">Top</a> ++
prompt

select inst_id, total_memory_allocated/(1024*1024) as used_MB,  current_size/(1024*1024) as  max_MB, (total_memory_allocated/current_size)*100 as pct_streams_pool, sga_target_value, shrink_phase, advice_disabled
from gv$streams_pool_statistics;

prompt 

select * from x$knlasg;

prompt
prompt <a name="Addaqparam"> </a>
prompt ++ ADDITIONAL AQ PARAMETERS ++ <a href="#DBConfig">DB</a> <a href="#Parameters">Parameters</a> <a href="#Top">Top</a> ++  

prompt  

col NAME format a50 
col VALUE format a20 
col DESCRIPTION format a100 

SELECT x.ksppinm NAME, y.ksppstvl VALUE, ksppdesc DESCRIPTION FROM x$ksppi x, x$ksppcv y WHERE 
x.inst_id = userenv('Instance')AND y.inst_id = userenv('Instance') AND x.indx = y.indx AND 
SUBSTR(x.ksppinm,1,1) = '_' AND (x.ksppinm like '_client_\%' escape '\' or 
 x.ksppinm like '%emon%' or x.ksppinm like '%ntfn%' or x.ksppinm like '%prop_old_enabled%' ) 
ORDER BY 1; 

prompt
prompt <a name="DBSGA"> </a>
prompt ++ SGA DYNAMIC COMPONENTS ++ <a href="#Confother">Other</a> <a href="#Top">Top</a> ++
prompt
col component format a25
col min_size  Head 'Min Size' format 999,999,999,999
col max_size  Head 'Max Size' format 999,999,999,999
col current_size  Head 'Current Size' format 999,999,999,999
col LAST_OPER_TIME format a20
col USER_SPECIFIED_SIZE Heading 'User Specified|Size' format 999,999,999,999
select component, current_size, min_size, max_size, user_specified_size,oper_count,
last_oper_type, last_oper_time
from v$sga_DYNAMIC_COMPONENTS order by current_size, component;
prompt

prompt
prompt <a name="Alerts"> </a>
prompt ============================================================================================
prompt                                                                     
prompt ++ <b>ALERTS</b></a> ++ <a href="#Top">Top</a>  ++
prompt
prompt

declare 
   cursor c_registry is select comp_name, status from dba_registry where status != 'VALID';
   cursor c_aq_tm is select inst_id, value from gv$parameter 
      where isdefault != 'TRUE' and name = 'aq_tm_processes';
begin
  for r_registry in c_registry loop 
      insert into tempaqhc_dropme values ('Warning',r_registry.comp_name,'Component '||r_registry.comp_name||' is on status '||r_registry.status,
            'If you have upgraded recently verify that you have followed all post-upgrade steps. Check My Oracle Support for further help. Action will dependent on component.');
         commit;
  end loop;
  
  for r_aq_tm in c_aq_tm loop 
    IF ((to_number(r_aq_tm.value) = 0) OR (to_number(r_aq_tm.value) = 10)) THEN
       insert into tempaqhc_dropme values ('Alert','Wrong value for aq_tm_processes parameter','Current setting of parameter aq_tm_processes on instance '||r_aq_tm.inst_id||' may produce a inadequate AQ management',
         'Please change the value of this parameter to its default setting. Use : alter system reset aq_tm_processes statement.');
       commit;
    ELSIF (to_number(r_aq_tm.value) > 5) THEN
       insert into tempaqhc_dropme values ('Information','High value for aq_tm_processes parameter','Current setting of parameter aq_tm_processes on instance '||r_aq_tm.inst_id||' could be considered high',
         'Please consider changing value for aq_tm_processes parameter to its default setting. Use : alter system reset aq_tm_processes statement.');
       commit;
    END IF;   
  end loop; 
  
  insert into tempaqhc_dropme values ('Information','Consider coalesce','If you have observed QMON performance problems, please consider coalecing AQ OITs',
     'Please check details on My Oracle Support Doc Id 271855.1');   
  
end;
/

col errorcode heading 'Type of alert' format a15
col description format a50 wrap
col action format a50 wrap

select * from tempaqhc_dropme;

set timing off
set markup html off
clear col
clear break
spool
prompt   Turning Spool OFF!!!
spool off

DROP TABLE TEMPAQHC_DROPME;

@?/rdbms/admin/sqlsessend.sql
