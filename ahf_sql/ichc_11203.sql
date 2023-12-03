Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/ichc_11203.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem ichc_11203.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      ichc_11203.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/ichc_11203.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/25/18 - Modified original script to 1) remove "connect /
Rem                           as sysdba" and 2) rename create/replace objects
Rem                           with oracle_tfa prefix
Rem    xiaodowu    01/25/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM
REM This healthcheck script is for OGG v11.2.1 Extract use on Oracle11gR2 databases.  ( 11.2.0.3) 
REM 
REM This script should be run by  SYS on the instance running the integrated extract, 
REM or the goldengate administrator with full privileges, or a user with DBA role
REM When run as SYS, queries on internal dictionary tables will produce output and summary overview
REM information will be available 
REM  
REM
REM  It  is recommended to run with markup html ON (default is on) and generate an HTML file for web viewing.
REM  Please provide the output in HTML format when Oracle (support or development) requests healthcheck output.
REM  To convert output to a text file viewable with a text editor,
REM    change the HTML ON to HTML OFF in the set markup command
REM  Remember to set up a spool file to capture the output
REM

define hcversion = 'v1.1.34';
define SRDCNAME='GoldenGate_HealthCheck'
set feedback off
set truncate off
set numwidth 15
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup HTML ON entmap off spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
alter session set nls_language=american;
set heading off

select 'OGG Integrated Capture Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on timing off


prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 




prompt
prompt ====================================================
prompt =====================<a name="Summary">Summary</a> ==============================
prompt ====================================================
prompt
prompt ++ Summary Overview ++
prompt
COL NAME HEADING 'Name'
col platform_name format a30 wrap
col current_scn format 99999999999999999
col host Heading 'Host'
col version heading 'Version'
col startup_time heading 'Startup|Time'
col database_role Heading 'Database|Role'
col DB_Edition heading 'Database|Edition' format a10

SELECT db.DBid,db.name, db.platform_name  ,i.HOST_NAME HOST, i.VERSION,
      DECODE(regexp_substr(v.banner, '[^ ]+', 1, 4),'Edition','Standard',regexp_substr(v.banner, '[^ ]+', 1, 4)) DB_Edition,  
      i.instance_number instance,db.database_role,db.current_scn, db.min_required_capture_change#  
   from v$database db,v$instance i, v$version v
   where banner like 'Oracle%';
prompt

prompt Summary of GoldenGate Integrated Extracts configured in database (<a href="#Capture Processes">ConfigDetails</a>  <a href="#Capture Statistics">StatsDetails</a>)
prompt
set lines 180
col extract_name format a8 heading 'Extract|Name'
col capture_name format a20 heading 'Capture|Name'
col capture_type format a10 heading 'Capture|Type'
col real_time_mine format a8 heading 'RealTime|Mine?'
col protocol format a8 heading 'OGG|Capture|Protocol'
col status Heading 'Status'
col state Heading 'Current|Capture|State'
col capture_user format a12 Heading 'Capture|User'
col inst_id Heading 'Instance'
col version format a12 Heading 'Capture|Version'
col required_checkpoint_scn format 999999999999999999 heading 'Required|Checkpoint|SCN'
col startup_time heading 'Process|Startup|Time'
col mined_MB Heading 'Redo|Mined|MB' format 99999999.999
col sent_MB Heading 'Sent to|Extract|Mb' format 99999999.999
col STATE_CHANGED_TIME  Heading 'Last |State Changed|Time'
col Current_time Heading 'Current|Time'
col capture_lag Heading 'Capture|Lag|seconds'
col registered Heading 'Registered'
col last_ddl_time Heading 'Last DDL|Time'


select  SYSDATE Current_time, substr(c.capture_name,9,8)  extract_name,c.capture_name, 
   c.capture_user,
   c.capture_type, 
   decode(cp.value,'N','NO', 'YES') Real_time_mine,
   c.version,
   c.required_checkpoint_scn,
   DECODE(g.state,'WAITING FOR INACTIVE DEQUEUERS','<b>V1</b>','V2') protocol,
   c.logminer_id,
   o.created registered,
   o.last_ddl_time,
   c.status,
   DECODE (g.STATE,'WAITING FOR CLIENT REQUESTS','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                'WAITING FOR INACTIVE DEQUEUERS','<b><a href="#Notification">'||g.state||'</a></b>',
                'WAITING FOR TRANSACTION;WAITING FOR CLIENT','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                g.state) State,
   (SYSDATE- g.capture_message_create_time)*86400 capture_lag,
   g.bytes_of_redo_mined/1024/1024 mined_MB,
   g.startup_time,
   g.inst_id
from dba_capture c, dba_objects o,
     gv$goldengate_capture g,
     dba_xstream_outbound ob,
     dba_capture_parameters cp
where
  c.capture_name=g.capture_name and c.capture_name = ob.capture_name
  and ob.server_name not  in (select server_name from gv$xstream_outbound_server) 
  and c.capture_name=cp.capture_name and cp.parameter='DOWNSTREAM_REAL_TIME_MINE'
  and c.status='ENABLED' 
  and c.capture_name = o.object_name
union all
select  SYSDATE Current_time, substr(c.capture_name,9,8)  extract_name,c.capture_name, 
   c.capture_user,
   c.capture_type, 
   decode(cp.value,'N','NO', 'YES') Real_time_mine,
   c.version,
   c.required_checkpoint_scn,
   '<b>V1</b>' protocol,
   c.logminer_id,
   o.created registered,
   o.last_ddl_time,
   c.status,
   DECODE (g.STATE,'WAITING FOR CLIENT REQUESTS','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                'WAITING FOR INACTIVE DEQUEUERS','<b><a href="#Notification">'||g.state||'</a></b>',
                'WAITING FOR TRANSACTION;WAITING FOR CLIENT','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                g.state) State,
   (SYSDATE- g.capture_message_create_time)*86400 capture_lag,
   g.bytes_of_redo_mined/1024/1024 mined_MB,
   g.startup_time,
   g.inst_id
from dba_capture c, dba_objects o,
     gv$goldengate_capture g,
     gv$xstream_outbound_server gob,
     dba_xstream_outbound ob,
     dba_capture_parameters cp
where
  c.capture_name=g.capture_name and c.capture_name = ob.capture_name
  and ob.server_name   in (select server_name from gv$xstream_outbound_server) 
  and c.capture_name=cp.capture_name and cp.parameter='DOWNSTREAM_REAL_TIME_MINE'
  and c.status='ENABLED' 
  and c.capture_name = o.object_name
union all
select  SYSDATE Current_time,  substr(c.capture_name,9,8)  extract_name,c.capture_name,
   c.capture_user,  
   c.capture_type, 
   decode(cp.value, 'N','NO', 'YES') Real_time_mine,
   c.version,
   c.required_checkpoint_scn,
   'Unavailable',
   c.logminer_id,
   o.created registered,
   o.last_ddl_time,
   c.status,
   'Unavailable',
   NULL,
   NULL,
   NULL,
   NULL
from dba_capture c, dba_objects o,
     dba_capture_parameters cp
where
  c.status in ('DISABLED','ABORTED') and c.purpose='GoldenGate Capture'
  and c.capture_name=cp.capture_name and cp.parameter='DOWNSTREAM_REAL_TIME_MINE'
  and c.capture_name = o.object_name
order by extract_name;
prompt

prompt
prompt
prompt Integrated Extract key parameters  (<a href="#CapParameters">Details</a>)
prompt

col parallelism format a20
col max_sga_size format a12
col excludetag format a20
col excludeuser format a20
col getapplops format a10
col getreplicates format a13
col checkpoint_frequency format a20
select cp.capture_name,substr(cp.capture_name,9,8) extract_name,
                  max(case when parameter='PARALLELISM' then value end) parallelism
                 ,max(case when parameter='MAX_SGA_SIZE' then value end) max_sga_size
                 ,max(case when parameter='EXCLUDETAG' then value end) excludetag
                 ,max(case when parameter='EXCLUDEUSER' then value end) excludeuser
                 ,max(case when parameter='GETAPPLOPS' then value end) getapplops
                 ,max(case when parameter='GETREPLICATES' then value end) getreplicates 
                 ,max(case when parameter='_CHECKPOINT_FREQUENCY' then value end) checkpoint_frequency                
                 from dba_capture_parameters cp, dba_capture c where c.capture_name=cp.capture_name
                  and c.purpose='GoldenGate Capture'
                 group by cp.capture_name;

prompt
prompt Integrated Extract/Logminer session info  (<a href="#LogmnrDetails">Details</a>)
prompt
col session_name Heading 'Capture|Name'
col available_txn Heading 'Available|Chunks'
col delivered_txn Heading 'Delivered|Chunks'
col difference Heading 'Ready to Send|Chunks'
col builder_work_size Heading 'Builder|WorkSize'
col prepared_work_size Heading 'Prepared|WorkSize'
col used_memory_size  Heading 'Used|Memory'
col max_memory_size   Heading 'Max|Memory'
col used_mem_pct Heading 'Used|Memory|Percent'

select session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as difference,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size,
             (used_memory_size/max_memory_size)*100 as used_mem_pct
      FROM gv$logmnr_session order by session_name; 

prompt
prompt  ++ <a name="Bundle">Replication Bundled Patch Information</a> 
prompt
select  value$ from sys.props$ where name = 'REPLICATION_BUNDLE';

prompt
col name format A30
col value$ format A30 HEADing 'Bundled Patch version'
set serveroutput on

DECLARE

bpvalue      varchar2(128);
RepBP varchar2(128);


BEGIN

   bpvalue := 'BP0 - cannot determine if a bundled patch is installed';
   select  'PROPS$ version:  ' || value$ into RepBP from sys.props$ where name = 'REPLICATION_BUNDLE';
   dbms_output.put_line(RepBP );
   
   
   select  replace(h.version,'.','_')||'_BP17' into bpvalue from  dba_registry_history h where h.comments like 'BP%'
      and h.namespace = 'SERVER' and h.ACTION = 'APPLY' and h.id > 17 
      and rownum < 2
      order by action_time desc;
   dbms_output.put_line('Derived bundled patch: ' || bpvalue );
   EXCEPTION 
    When NO_DATA_FOUND THEN
          dbms_output.put_line('+ <b>INFO</b>: Cannot derive Bundled Patch');
            dbms_output.put_line('');

END;
/

prompt
prompt  +++ Outstanding alerts      (<a href="#Alerts">Details</a>)
prompt
set feedback on

select message_type,creation_time,reason, suggested_action,
     module_id,object_type,
     instance_name||' (' ||instance_number||' )' Instance,
     time_suggested
from dba_outstanding_alerts 
   where creation_time >= sysdate -10 and rownum < 11
   order by creation_time desc;
prompt
prompt  Count of Capture and Apply processes configured in database by purpose

set feedback on

col nmbr heading 'Count'
col type heading 'Process|Type'
select purpose,count(*) nmbr, 'CAPTURE' type from dba_capture group by purpose
union all
select purpose, count(*) nmbr, 'APPLY' type from dba_apply group by purpose 
order by purpose;

set feedback off
-- note:  this function is vulnerable to SQL injection, please do not copy it
create or replace function oracle_tfa_get_parameter(
  param_name        IN varchar2,
  param_value       IN OUT varchar2,
  table_name        IN varchar2,
  table_param_name  IN varchar2,
  table_value       IN varchar2
) return boolean is
  statement varchar2(4000);
begin
  -- construct query 
  statement :=  'select ' || table_value || ' from ' || table_name || ' where ' 
                || table_param_name || '=''' || param_name || '''';

  begin
    execute immediate statement into param_value;
  exception when no_data_found then
    -- data is not found, so return FALSE
    return FALSE;
  end;
  -- data found, so return TRUE
  return TRUE;
end oracle_tfa_get_parameter;
/

--   Compilations
set feedback off
create or replace procedure oracle_tfa_verify_init_parameter( 
  param_name         IN varchar2, 
  expected_value     IN varchar2,
  verbose            IN boolean,
  more_info          IN varchar2 := NULL,
  more_info2         IN varchar2 := NULL,
  at_least           IN boolean := FALSE,
  is_error           IN boolean := FALSE,
  use_like           IN boolean := FALSE,
  -- may not be necessary
  alert_if_not_found IN boolean := TRUE
) 
is
  current_val_num  NUMBER;
  expected_val_num NUMBER;
  current_value    varchar2(512);
  prefix           varchar2(25);
  matches          boolean := FALSE;
  comparison_str   varchar2(20);
begin
  -- Set prefix as warning or error
  if is_error then
    prefix := '+  <b>ERROR:</b>  ';
  else
    prefix := '+  <b>WARNING:</b>   ';
  end if;

  -- Set comparison string
  if at_least then
    comparison_str := ' at least ';
  elsif use_like then
    comparison_str := ' like ';
  else
    comparison_str := ' set to ';
  end if;

  -- Get value
  if oracle_tfa_get_parameter(param_name, current_value, 'v$parameter', 'name', 'value') = FALSE 
     and alert_if_not_found then
    -- Value isn't set, so output alert
    dbms_output.put_line(prefix || 'The parameter ''' || param_name || ''' should be'
                         || comparison_str || '''' || expected_value 
                         || ''', instead it has been left to its default value.'); 
    if verbose and more_info is not null then
      dbms_output.put_line(more_info);
      if more_info2 is not null then
        dbms_output.put_line(more_info2);
      end if;
    end if;
    dbms_output.put_line('+');
    return;
  end if;

  -- See if the expected value is what is actually set
  if use_like then
    -- Compare with 'like'
    if current_value like '%'||expected_value||'%' then
      matches := TRUE;
    end if;
  elsif at_least then
    -- Do at least
    current_val_num := to_number(current_value);
    expected_val_num := to_number(expected_value);
    if current_val_num >= expected_val_num then
      matches := TRUE;
    end if;
  else
    -- Do normal comparison
    if current_value = expected_value then
      matches := TRUE;
    end if;
  end if;
  
  if matches = FALSE then
    -- The values don't match, so alert
    dbms_output.put_line(prefix || 'The parameter ''' || param_name || ''' should be'
                         || comparison_str || '''' || expected_value 
                         || ''', instead it has the value ''' || current_value || '''.'); 
    if verbose and more_info is not null then
      dbms_output.put_line(more_info);
      if more_info2 is not null then
        dbms_output.put_line(more_info2);
      end if;
    end if;
    dbms_output.put_line('+');
  end if;

end oracle_tfa_verify_init_parameter;
/

prompt
prompt  ++
prompt  ++ <a name="Notification">Notifications</a> ++
prompt  ++
prompt

set serveroutput on size unlimited
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
  -- By default any errors in dba_apply_error will result in output
  apply_error_threshold        number := 0;          
  -- By default a streams pool usage above 95% will result in output
  streams_pool_usage_threshold number := 95;  
  -- The total number of registered archive logs to have before reporting an error
  registered_logs_threshold    number := 1000;
  -- The total number of days old the oldest archived log should be before reporting an error
  registered_age_threshold     number := 60;  -- days


  row_count number;
  days_old number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);

 cursor aborted_capture is 
    select capture_name, error_number, error_message from dba_capture where status='ABORTED' and purpose = 'GoldenGate Capture';
 
  cursor aborted_apply is 
    select apply_name, error_number, error_message from dba_apply where status='ABORTED'  and purpose = 'GoldenGate Capture';

  cursor disabled_apply is select apply_name from dba_apply where status='DISABLED';
  cursor disabled_capture is select capture_name from dba_capture where status='DISABLED' and purpose = 'GoldenGate Capture';

  cursor  unattached_extract is select capture_name, substr(capture_name,9,8) extract_name from gv$goldengate_capture where state='WAITING FOR INACTIVE DEQUEUERS';
  cursor classic_capture is select capture_name from dba_capture where capture_name like 'OGG%$%' and purpose='Streams';

--  check if state_changed_time is older than 3 minutes  (approx .00211 * 86400)
  cursor  old_state_time is select capture_name,state,state_changed_time,to_char( (SYSDATE- state_changed_time)*1440,'99990.99') mins from gv$goldengate_capture where (SYSDATE - state_changed_time ) >.00211;

  cursor ckpt_retention_time is select capture_name,substr(capture_name,9,8) extract_name,
                                DECODE(checkpoint_retention_time,60,'<b>WARNING</b>: Checkpoint Retention time is set too high (60 days) for extract ',
                                                                  7,'<b>INFO</b>: Checkpoint Retention time set to OGG default of 7 days for extract ',
                                                                    '<b>INFO</b>: Checkpoint Retention time set to '||checkpoint_retention_time||' days by extract ') msg
              from dba_capture  where purpose='GoldenGate Capture';

  cursor cap_param_maxsga is select cp.capture_name, substr(cp.capture_name,9,8) extract_name, value       
                            from dba_capture_parameters cp, dba_capture c where c.capture_name=cp.capture_name and purpose = 'GoldenGate Capture' and cp.parameter = 'MAX_SGA_SIZE';

  

begin

  -- Check for aborted capture processes
  for rec in aborted_capture loop
    dbms_output.put_line('+  <b>ERROR</b>:  OGG Capture ''' || rec.capture_name || ''' has aborted with message ' || 
                         rec.error_message);
  end loop;

  dbms_output.put_line('+');

  -- Check that post_install steps have been done
  select  count(*) into row_count from dba_objects where object_type = 'PACKAGE BODY' and owner = 'SYS' and created <> last_ddl_time
                                 and
                                (object_name like 'DBMS_XSTREAM%' or
                                 object_name like 'DBMS_APPLY%' or
                                 object_name like 'DBMS_CAPTURE%' or
                                 object_name like 'DBMS_GOLDENGATE_A%');
   if row_count = 0 then
    dbms_output.put_line('+  <b>WARNING</b>:  Make sure that post_install steps for the required OGG/RDBMS bundled patch have been performed. See MOS note 1411356.1');
   end if;
      

 
  -- Check for disabled capture processes
  for rec in disabled_capture loop
    dbms_output.put_line('+  <b>WARNING</b>:  Capture ''' || rec.capture_name || ''' is disabled');
  end loop;

  dbms_output.put_line('+');

  -- Check for disabled apply processes
  for rec in disabled_apply loop
    dbms_output.put_line('+  <b>WARNING</b>:  Apply ''' || rec.apply_name || ''' is disabled');
  end loop;

  dbms_output.put_line('+');

  -- Check for classic capture processes
  for rec in classic_capture loop
    dbms_output.put_line('+  <b>INFO</b>:  Capture ''' || rec.capture_name || ''' is Oracle GoldenGate classic capture with LOGRETENTION enabled');
  end loop;
 dbms_output.put_line('+');

 --- capture is started but extract is not attached
   for rec in unattached_extract loop
       dbms_output.put_line('+  <b>ERROR</b>:  Extract '''||rec.extract_name||''' is not attached to capture '''||rec.capture_name||'''. State is WAITING FOR INACTIVE DEQUEUERS');
       dbms_output.put_line('+  In GGSCI, use this command to start the extract process: START extract '||rec.extract_name);
      dbms_output.put_line('+');
   end loop;
 dbms_output.put_line('+');

 --- capture state has not changed for at least 3 minutes 
   for rec in old_state_time loop
       dbms_output.put_line('+  <b>WARNING</b>:    Capture State for  '||rec.capture_name||' has not changed for over '|| rec.mins||' minutes.');
       dbms_output.put_line('+    Last Capture state change timestamp is '||rec.state_changed_time||' State is '||rec.state);
   end loop;

  dbms_output.put_line('+');
 
--- Jobs scheduled to run every second
     select count(*) into row_count from dba_scheduler_jobs where repeat_interval ='FREQ=SECONDLY' and enabled='TRUE';
     if row_count>0  then
        dbms_output.put_line('+  <b>INFO</b>:  There are '||row_count ||' <a href="#SECONDS">jobs scheduled to run every second</a>.  Click the link to identify the jobs');
       
	dbms_output.put_line('+  <b>INFO</b>:  Jobs scheduled to run every second on an otherwise idle database can cause unexplained extract lag. ');
        dbms_output.put_line('+                To workaround the issue, decrease the the scheduled job frequency. Database patch for bug 16796277 resolves the issue.');
        dbms_output.put_line('+');
     end if;


   for rec in ckpt_retention_time loop
       dbms_output.put_line('+ '||rec.msg||rec.extract_name);
   end loop;
       if verbose then
       dbms_output.put_line('+  You can set this parameter to a lower value by including or modifying the following line in the extract parameter file ');
       dbms_output.put_line('    TRANLOGOPTIONS CHECKPOINTRETENTIONTIME number_of_days  ');
       dbms_output.put_line('+    where number_of_days is the number of days the extract logmining server will retain checkpoints. The default is 7 days');
       end if;
   dbms_output.put_line('+ ');
   
   for rec in cap_param_maxsga loop
        if rec.value = 'INFINITE' then
          dbms_output.put_line('+ <b>WARNING</b>:  Extract '||rec.extract_name||' has not set the memory size parameter for capture '||rec.capture_name);
          dbms_output.put_line('+  Include the following line in the extract parameter file:');
          dbms_output.put_line('TRANLOGOPTIONS INTEGRATEDPARAMS( MAX_SGA_SIZE 1000)');
          dbms_output.put_line('+ ');
        else 
          dbms_output.put_line('+ <b>INFO</b>:  Extract '||rec.extract_name||' memory size  for capture '||rec.capture_name||' is configured as '||rec.value||' Megabytes');
          dbms_output.put_line('+ ');
        end if;
   end loop;



 -- Check for too many registered archive logs

    failed := FALSE;
    select count(*) into row_count from dba_registered_archived_log where purgeable = 'NO';
    select (sysdate - min(modified_time)) into days_old from dba_registered_archived_log where purgeable = 'NO';
    if row_count > registered_logs_threshold then 
      failed := TRUE;
      dbms_output.put_line('+  <b>WARNING</b>:  ' || row_count || ' archived logs registered  for extracts/captures..');
    end if;
 
    if days_old > registered_age_threshold then
      failed := TRUE;
      dbms_output.put_line('+  <b>WARNING</b>:  The oldest archived log is ' || round(days_old) || ' days old!');
    end if;
    select count(*) into row_count from dba_registered_archived_log where purgeable = 'YES';
    if row_count > registered_logs_threshold/2 then
      dbms_output.put_line('+  <b>WARNING</b>:  There are '|| row_count ||' archived logs ready to be purged from disk.');
      dbms_output.put_line('+          Use the following select to identify unneeded logfiles:');
      dbms_output.put_line('+          select name from dba_registered_archived_log where purgeable = "YES"  ');
    end if;
    
      dbms_output.put_line('+ ');
    if failed then
      dbms_output.put_line('+    A restarting Capture process must mine through each registered archive log.');
      dbms_output.put_line('+    To speedup Capture restart, reduce the amount of disk space taken by the archived');
      dbms_output.put_line('+    logs, and reduce Capture metadata, consider moving the first_scn automatically by  ');
      dbms_output.put_line('+    altering the checkpoint_retention_time capture parameter to a lower value by including in the extract parameter file ');
      dbms_output.put_line('+    TRANLOGOPTIONS CHECKPOINTRETENTIONTIME number_of_days  ');
      dbms_output.put_line('+    where number_of_days is the number of days the extract logmining server will retain checkpoints.');

      dbms_output.put_line('+ ');
      dbms_output.put_line('+   For more information, see the Oracle GoldenGate for Windows and UNIX Reference Guide ');
      dbms_output.put_line('+    Note that once the first scn is increased, Capture will no longer be able to mine before');
      dbms_output.put_line('+    this new scn value.');
      dbms_output.put_line('+    Successive moves of the first_scn will remove unneeded registered archive');
      dbms_output.put_line('+    logs only if the files have been removed from disk');
    end if;
end;
/
prompt
prompt  ++
prompt  ++  <a name="SYSCheck">SYS Checks</a>
prompt  ++
prompt
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
    -- By default a streams pool usage above 85% will result in output
  streams_pool_usage_threshold number := 85;  
  
  row_count number;
  days_old number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);
  bundle number;
  v1_exists boolean := FALSE;

     cursor v1_capture is select capname_knstcap, substr(capname_knstcap,9,8) extract_name from x$knstcap x , dba_capture c where bitand(x.flags_knstcap,64) <> 64 and  x.capname_knstcap=c.capture_name and c.purpose = 'GoldenGate Capture' ;


begin
--   report v1 capture
  
  select substr(value$,12,2) into bundle from sys.props$ where name ='REPLICATION_BUNDLE';
 
  for rec in v1_capture loop
     dbms_output.put_line('+ <b>WARNING</b>:  Extract '''||rec.extract_name||''' is using V1 protocol');
 if   bundle > 13 then 
       dbms_output.put_line('+           Verify that you are using Oracle GoldenGate release above 11.2.1.0.4.');
       dbms_output.put_line('+         To convert to V2 protocol (the default for newly created extract) do the following:');
       dbms_output.put_line('+         1.  Make sure that all outstanding bounded recovery  (BR) transactions have been applied');
       dbms_output.put_line('+         2.  In GGSCI issue the following command:  Stop extract '||rec.extract_name);
       dbms_output.put_line('+         3.  Add the following line to the parameter file for '||rec.extract_name);
       dbms_output.put_line('             TRANLOGOPTIONS _LCRCAPTUREPROTOCOL V2');
       dbms_output.put_line('+         For further information, refer to My Oracle Support article  1592164.1 ');
       dbms_output.put_line('+         4.  In GGSCI issue the following command:  Start extract '||rec.extract_name);
       dbms_output.put_line('+');
 
  end if;
  end loop;
  


   
 -- Check high streams pool usage
 
    select FRUSED_KWQBPMT into streams_pool_usage from x$kwqbpmt;
    select value into streams_pool_size from v$parameter where name = 'streams_pool_size';
    if streams_pool_usage > streams_pool_usage_threshold then
      dbms_output.put_line('+  <b>WARNING</b>:  Streams pool usage for this instance is ' || streams_pool_usage ||
                           '% of ' || streams_pool_size || ' bytes!');
      dbms_output.put_line('+    If this system is processing a typical workload, and no ' ||
                           'other errors exist, consider increasing the streams pool size.');
      dbms_output.put_line('+');
    end if;
  exception when others then null;
  end;
/



prompt
prompt  ++
prompt  ++ init.ora checks ++
prompt  ++
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose            boolean := TRUE;
  row_count          number;
  dbvers             number;
  num_downstream_cap number;
  capture_procs      number;
  apply_procs        number;
  newline            varchar2(1) := '
';
begin
   -- Error checks first
 

 -- Then warnings

  -- Do downstream capture checks
--  select count(*) into num_downstream_cap from dba_capture where capture_type = 'DOWNSTREAM';
--  if num_downstream_cap > 0 then
    -- We have a downstream capture, so do specific checks
--    oracle_tfa_verify_init_parameter('remote_archive_enable', 'TRUE', verbose, is_error=>TRUE);
--  end if;

 

  oracle_tfa_verify_init_parameter('compatible', '11.2.0.3', verbose, 
                        '+    To use full features of Oracle GoldenGate 11.2.1 Integrated Capture, '||  
                        'this parameter should be set to at least 11.2.0.3  ',
                        use_like => TRUE);




  oracle_tfa_verify_init_parameter('streams_pool_size', '0', TRUE, 
                        '+    If this parameter is 0 and sga_target is non-zero, then autotuning of the streams pool is implied.'||newline||
                        '+    It is recommended that streams_pool_size be set to a non-zero value (minimum 1G) rather than to use autotuning'||
                        '+    If the sga_target parameter is set to 0 and streams_pool_size is 0,'|| newline||
                        '+    10% of the shared pool will be used for OGG.' || newline ||
                        '+    The minimum recommendation for streams_pool_size is 1G.'|| newline||
                        '+      Note you must bounce the database if changing the ',
                        '+    value from zero to a nonzero value.  But if simply increasing this' || newline ||
                        '+    value from an already nonzero value, the database need not be bounced.',
                        at_least=> TRUE);
end;
/

prompt
prompt  ++
prompt  ++  <a name="Configuration checks">Configuration checks</a> ++
prompt  ++
declare
  current_value varchar2(4000);

 
  cursor multiqueues is
   select c.capture_name capture_name, a.apply_name apply_name, 
          c.queue_owner queue_owner, c.queue_name queue_name
     from dba_capture c, dba_apply a
    where c.queue_name = a.queue_name and c.queue_owner = a.queue_owner
      and c.capture_type != 'DOWNSTREAM' and a.purpose ='STREAMS APPLY' and c.capture_name not like 'CDC$%';

  cursor nonlogged_tables is 
    select table_owner owner,table_name name from dba_capture_prepared_tables t
     where table_owner in
        (select distinct(table_owner) from dba_capture_prepared_tables where 
           supplemental_log_data_pk='NO' and supplemental_log_data_fk='NO' and 
           supplemental_log_data_ui='NO' and
           supplemental_log_data_all='NO'
        minus
          select schema_name from dba_capture_prepared_schemas)
     and not exists
       (select 'X' from dba_log_groups l where t.table_owner = l.owner and t.table_name = l.table_name
       UNION
       select 'x' from dba_capture_prepared_database);


  cursor overlapping_rules is
   select a.streams_name sname, a.streams_type stype, 
          a.rule_set_owner rule_set_owner, a.rule_set_name rule_set_name, 
          a.rule_owner owner1, a.rule_name name1, a.streams_rule_type type1, 
          b.rule_owner owner2, b.rule_name name2, b.streams_rule_type type2
     from dba_streams_rules a, dba_streams_rules b
    where a.rule_set_owner = b.rule_set_owner 
      and a.rule_set_name = b.rule_set_name
      and a.streams_name = b.streams_name and a.streams_type = b.streams_type
      and a.rule_type = b.rule_type
      and (a.subsetting_operation is null or b.subsetting_operation is null)
      and (a.rule_owner != b.rule_owner or a.rule_name != b.rule_name)
      and ((a.streams_rule_type = 'GLOBAL' and b.streams_rule_type 
            in ('SCHEMA', 'TABLE') and a.schema_name = b.schema_name)
       or (a.streams_rule_type = 'SCHEMA' and b.streams_rule_type = 'TABLE' 
           and a.schema_name = b.schema_name)
       or (a.streams_rule_type = 'TABLE' and b.streams_rule_type = 'TABLE' 
           and a.schema_name = b.schema_name and a.object_name = b.object_name
           and a.rule_name < b.rule_name)
       or (a.streams_rule_type = 'SCHEMA' and b.streams_rule_type = 'SCHEMA' 
           and a.schema_name = b.schema_name and a.rule_name < b.rule_name)
       or (a.streams_rule_type = 'GLOBAL' and b.streams_rule_type = 'GLOBAL' 
           and a.rule_name < b.rule_name))
       order by a.rule_name;


  cursor bad_source_db is
   select rule_owner||'.'||rule_name Rule_name, source_database from dba_streams_rules where source_database not in 
             (select global_name from system.logmnrc_dbname_uid_map);


  cursor qtab_too_long is
     select queue_table name, length(queue_table) len from dba_queues q , dba_apply a where 
        length(queue_table)>24 and q.owner=a.queue_owner and q.name=a.queue_name;

  cursor reginfo_invalid is
     select comp_id,status from dba_registry where comp_id in ('CATALOG','CATPROC') and status not in ( 'VALID','UPDATED');

  cursor version_diff is
     select i.version inst_version,r.version reg_version from v$instance i, dba_registry r where 
        r.comp_id  in ('CATALOG','CATPROC') and i.version <> r.version;

  cursor ogg_out_rule_sets is
      select apply_name from dba_apply where purpose = 'GoldenGate Capture' and ((rule_set_owner is not null 
       and rule_set_name is not null) or (negative_rule_set_owner is not null and        negative_rule_set_name is not null));

  cursor ogg_out_cp_rule_sets is
      select capture_name from dba_capture where purpose = 'GoldenGate Capture' and ((rule_set_owner is  null 
       and rule_set_name is  null) or (negative_rule_set_owner is  null and        negative_rule_set_name is  null));

  cursor cparallel is
     select p.capture_name, substr(c.capture_name,9,8) client_name  from dba_capture_parameters p, dba_capture c where c.capture_name=p.capture_name and c.purpose = 'GoldenGate Capture' and p.parameter='PARALLELISM' and to_number(p.value)= 0;
  
  cursor ogg_cap_privs is select distinct capture_user username from dba_capture where purpose = 'GoldenGate Capture'
				minus
			select distinct username from dba_goldengate_privileges where privilege_type in ('*','CAPTURE');

  
  row_count     number :=0;
  min_count     number;
  max_count     number;
  capture_count number;
  local_capture_count number := 0;
  realtime_count number;
  verbose       boolean := TRUE;
  overlap_rules boolean := FALSE;
  latency       number;
begin
     
  -- Check  Registry Info STATUS
  for rec in reginfo_invalid loop
     dbms_output.put_line('+  <b>ERROR</b>:  The DBA_REGISTRY status information for component '''||rec.comp_id||
      ''' requires attention.  Status is '||rec.status||
                          '. Please recompile the component ');
     dbms_output.put_line('+');
  end loop;                

  -- Check consistent Instance and Registry Info
  for rec in version_diff loop
     dbms_output.put_line('+  <b>ERROR</b>:  The ORACLE_HOME software is '''||rec.inst_version||''' but the database catalog is '||rec.reg_version||
                          '.  CATPATCH must be run successfully to complete the upgrade');
     dbms_output.put_line('+');
  end loop;                


 --  OGG Administrator privilege checks

  for rec in ogg_cap_privs loop
       dbms_output.put_line('+  <b>WARNING</b>:  '''||rec.username||''' has not been granted OGG administrator privileges for CAPTURE');
       dbms_output.put_line('+            To grant appropriate privileges, use  ');
       dbms_output.put_line(' exec dbms_goldengate_auth.grant_admin_privilege('''||rec.username||''',PRIVILEGE_TYPE=>''*'',GRANT_SELECT_PRIVILEGES=>true);');
       dbms_output.put_line('+');
  end loop;

  

  -- Make sure it is in archivelog mode
  select count(*) into capture_count from dba_capture where capture_type != 'DOWNSTREAM';
  select count(cpp.parameter) into realtime_count from dba_capture_parameters cpp, 
dba_capture c  where c.capture_type = 'DOWNSTREAM' and 
c.capture_name = cpp.capture_name and cpp.parameter = 'DOWNSTREAM_REAL_TIME_MINE' 
and cpp.value = 'Y';
  select count(*) into row_count from v$database where log_mode = 'NOARCHIVELOG';
  if row_count > 0 and (capture_count > 0 or realtime_count>0) then
    dbms_output.put_line('+  <b>ERROR</b>:  ARCHIVELOG mode must be enabled for this database.');
     if verbose and  capture_count > 0   then
         dbms_output.put_line('+    For a local Capture process to function correctly, it'
                           || ' must be able to read the archive logs.');
     end if;
     if verbose and realtime_count > 0 then
         dbms_output.put_line('+    For a downstream Capture process to function in realtime mode, archive logging'
                           || ' must be enabled at both the source and downstream capture database.');
      end if;
      if verbose then 
         dbms_output.put_line('+    Please refer to the documentation to restart the database'
                           || ' in ARCHIVELOG format.');
         dbms_output.put_line('+');
      end if;
  end if;

 --  Make sure that downstream capture in real time mode has standby redo logs configured
     select count(*) into capture_count from (select c.capture_name,cp.value  from dba_capture c, dba_capture_parameters cp where cp.capture_name=c.capture_name  and c.capture_type = 'DOWNSTREAM' and cp.parameter = 'DOWNSTREAM_REAL_TIME_MINE' and cp.value = 'Y');
     select count(*),min(bytes), max(bytes) into row_count,min_count,max_count from v$standby_log;
     if row_count>0 and capture_count > 0 then
        dbms_output.put_line('+  <b>INFO</b>:  Number of standby redo logs configured is '||row_count);
        if min_count != max_count then
	    dbms_output.put_line('+  <b>INFO</b>:  Standby redo logs have different sizes, ranging in bytes from '||min_count||' to '||max_count);
        end if;
         dbms_output.put_line('+');
     end if;

  -- Basic supplemental logging checks
  -- #1.  If minimal supplemental logging is not enabled, this is an error
  select count(*) into row_count from v$database where SUPPLEMENTAL_LOG_DATA_MIN = 'NO';
  select count(*) into local_capture_count from dba_capture where capture_type = 'LOCAL';
  if row_count > 0 and local_capture_count > 0 then
    dbms_output.put_line('+  <b>ERROR</b>:  Minimal supplemental logging not enabled.');
    if verbose then 
      dbms_output.put_line('+    For a GoldenGate Capture process to function correctly, at'
                           || ' least minimal supplemental logging should be enabled.');
      dbms_output.put_line('+    Execute ''ALTER DATABASE ADD SUPPLEMENTAL LOG DATA'''
                           || ' to fix this issue.  Note you may need to specify further');
      dbms_output.put_line('+    levels of supplemental logging, see the GoldenGate documentation'
                           || ' for details on ADD TRANDATA and ADD SCHEMATRANDATA directives.');
      dbms_output.put_line('+');
    end if;
  end if;

  -- #2.  If Primary key database level logging not enabled, there better be some 
  -- log data per prepared table
  select count(*) into row_count from v$database where SUPPLEMENTAL_LOG_DATA_PK = 'NO';
  if row_count > 0 and local_capture_count > 0 then
    for rec in nonlogged_tables loop
      dbms_output.put_line('+  <b>ERROR</b>:   No supplemental logging specified for table '''
                           || rec.owner || '.' || rec.name || '''.');
      if verbose then 
        dbms_output.put_line('+    In order for Capture to work properly, it must' ||
                             ' have key information supplementally logged');
        dbms_output.put_line('+    for each table whose changes are being captured.  ' ||
                             'This system does not have database level primary key information ');
        dbms_output.put_line('+  logged, thus for each interested table manual logging '
                             || 'must be specified.  Please see the documentation for more info.');
        dbms_output.put_line('+');
      end if;
    end loop;
  end if;

  -- Rules checks
  -- TODO:  intergrate existing rules checks found above     
  for rec in overlapping_rules loop
    overlap_rules := TRUE;
    dbms_output.put_line('+  <b>WARNING</b>:  The rule ''' || rec.owner1 || '''.''' || rec.name1 
                         || ''' and ''' || rec.owner2 || '''.''' || rec.name2 
                         || ''' from rule set ''' || rec.rule_set_owner || '''.''' 
                         || rec.rule_set_name || ''' overlap.');
  end loop;

  if overlap_rules and verbose then
    dbms_output.put_line('+    Overlapping rules are a problem especially when rule-based transformations exist.');
    dbms_output.put_line('+    There is no guarantee on which rule in a rule set will evaluate to TRUE,');
    dbms_output.put_line('+    thus overlapping rules will cause inconsistent behavior, and should be avoided.');
  end if;
  dbms_output.put_line('+');

  --
  -- Suggestions.  These might help speedup performance.
  --

  -- Check capture parallelism is not zero (0)
  for rec in cparallel loop
    dbms_output.put_line('+  <b>WARNING</b>:  the Capture process ''' || rec.capture_name ||' for extract '||rec.client_name ||' has parallelism set to 0!');
    dbms_output.put_line('+ For Oracle Database Enterprise Edition, include the following line in the extract parameter file');
    dbms_output.put_line('+    TRANLOGOPTIONS INTEGRATEDPARAMS(PARALLELISM 2)');
    dbms_output.put_line('+ For Oracle Database Standard Edition, include the following line in the extract parameter file');
    dbms_output.put_line('+    TRANLOGOPTIONS INTEGRATEDPARAMS(PARALLELISM 1)'); 
    dbms_output.put_line('+');
  end loop;

 
    -- Database-level supplemental logging defined but only a few tables replicated
    select count(*) into row_count from v$database where supplemental_log_data_pk = 'YES';
    select count(*) into capture_count from dba_capture_prepared_tables;
    if row_count > 0 and capture_count < 10 and local_capture_count > 0 then
      dbms_output.put_line('+  <b>INFO</b>:  Database-level supplemental logging enabled but only a few tables');
      dbms_output.put_line('+    prepared for capture.  Database-level supplemental logging could write more');
      dbms_output.put_line('+    information to the redo logs for every update statement in the system.');
      dbms_output.put_line('+    If the number of tables you are interested in is small, you might consider');
      dbms_output.put_line('+    specifying supplemental logging of keys and columns on a per-table basis.');
      dbms_output.put_line('+    See the GoldenGate documentation for information on ADD TRANDATA and ADD SCHEMATRANDATA supplemental logging.');
      dbms_output.put_line('+');
    end if;


 
end;
/

prompt --  11.2.0.3 specific checks
prompt
declare
  post_install_complete EXCEPTION;
  PRAGMA
  EXCEPTION_INIT ( post_install_complete,-6502);
  

Begin
    dbms_xstream_gg_adm.set_checkpoint_scns('junk','junk','junk');
  EXCEPTION

  WHEN post_install_complete then
     dbms_output.put_line('+ <b>INFO</b>:  Post installation step completed');
  WHEN OTHERS then
         dbms_output.put_line('+ <b>ERROR</b>:  SET_CHECKPOINT_SCNS procedure is missing.  Please confirm that you have run the Post Installation step of the OGG/RDBMS bundled patch that has been installed');

END;
/


prompt
prompt  ++
prompt  ++ <a name="Performance Checks">Performance Checks</a> ++
prompt  ++
prompt  ++ Note:  Performance only checked for enabled  processes!
prompt  ++        Aborted and disabled processes will not report performance warnings!
prompt
declare
  verbose boolean := TRUE;

  -- how far back capture must be before we generate a warning
  capture_latency_threshold    number := 300;  -- seconds
  -- how far back the apply reader must be before we generate a warning
  applyrdr_latency_threshold   number := 600;  -- seconds
  -- how far back the apply coordinator's LWM must be before we generate a warning
  applylwm_latency_threshold   number := 1200;  -- seconds
  -- how many messages should be unconsumed before generating a warning
  unconsumed_msgs_threshold    number := 300000;
  -- percentage of messages spilled before generating a warning
  spill_ratio_threshold        number := 25;
  -- how long queue can be up before signalling a warning
  spill_startup_threshold      number := 3600;  -- seconds
  -- how long logminer can spend spilling before generating a warning
  logminer_spill_threshold     number := 30000000;  -- microseconds 

  complex_rules boolean := FALSE;
  slow_clients boolean := FALSE;

  cursor capture_latency (threshold NUMBER) is 
   select capture_name, 86400 *(available_message_create_time - capture_message_create_time) latency
     from gv$goldengate_capture 
    where 86400 *(available_message_create_time - capture_message_create_time) > threshold;

  cursor apply_reader_latency (threshold NUMBER) is 
   select apply_name, 86400 *(dequeue_time - dequeued_message_create_time) latency
     from gv$streams_apply_reader
    where 86400 *(dequeue_time - dequeued_message_create_time) > threshold;

  cursor apply_lwm_latency (threshold NUMBER) is 
   select r.apply_name, 86400 *(r.dequeue_time - c.lwm_message_create_time) latency
     from gv$streams_apply_reader r, gv$streams_apply_coordinator c
    where r.apply# = c.apply# and r.apply_name = c.apply_name 
      and 86400 *(r.dequeue_time - c.lwm_message_create_time) > threshold;

  cursor queue_stats is
  select queue_schema, queue_name, num_msgs, spill_msgs, cnum_msgs, cspill_msgs,
         (cspill_msgs/DECODE(cnum_msgs, 0, 1, cnum_msgs) * 100) spill_ratio,  86400 *(sysdate - startup_time) alive
    from gv$buffered_queues;

  cursor logminer_spill_time (threshold NUMBER) is
  select c.capture_name, l.name, l.value from gv$goldengate_capture c, gv$logmnr_stats l
   where c.logminer_id = l.session_id 
     and name = 'microsecs spent in pageout' and value > threshold;  

  cursor complex_rule_sets_cap is
  select capture_name, owner, name from gv$rule_set r, dba_capture c 
   where c.rule_set_owner = r.owner and c.rule_set_name = r.name 
     and r.sql_executions > 0; 

  cursor complex_rule_sets_prop is
  select propagation_name, owner, name from gv$rule_set r, dba_propagation p
   where p.rule_set_owner = r.owner and p.rule_set_name = r.name 
     and r.sql_executions > 0; 

  cursor complex_rule_sets_apply is
  select apply_name, owner, name from gv$rule_set r, dba_apply a
   where a.rule_set_owner = r.owner and a.rule_set_name = r.name 
           and r.sql_executions > 0; 


  cursor client_slow is
    select c.capture_name,substr(c.capture_name,9,8) extract_name, c.state,l.available_txn-l.delivered_txn difference from 
         gv$goldengate_capture c, 
         gv$logmnr_session l 
        where c.capture_name = l.session_name 
           and c.state in (NULL, 'WAITING FOR CLIENT REQUESTS', 'WAITING FOR TRANSACTION;WAITING FOR CLIENT','PAUSED FOR FLOW CONTROL');



begin

  for rec in client_slow loop
     dbms_output.put_line('+   <b>WARNING</b>:  Extract '||rec.extract_name||' is slow to request changes ('||rec.difference||' chunks available) from capture '||rec.capture_name);
      dbms_output.put_line('+  Use the following command to obtain Extract wait statistics');
      dbms_output.put_line('SEND extract '||rec.extract_name||', LOGSTATS ');
      dbms_output.put_line('+  Output of above command is written to extract report file');
      dbms_output.put_line('+ ');
     slow_clients := TRUE;
  end loop;
    if  slow_clients then
       dbms_output.put_line('+  The  WAITING FOR CLIENT REQUESTS state is an indicator to investigate the extract process rather than the logmining server when there are chunks available from capture.');
       dbms_output.put_line('+  If OGG version is 11.2.1.0.7 thru 11.2.1.0.12, upgrade to  version 11.2.1.0.13 or above  ( My Oracle Support article 1589437.1 )' );
       dbms_output.put_line('+');
       dbms_output.put_line('+  If Integrated Extract is V2 and wait statistics from SEND extract... LOGSTATS are high, ');
       dbms_output.put_line('+  add the following line to the extract parameter file and restart extract:');
       dbms_output.put_line('TRANLOGOPTIONS _READAHEADCOUNT 64');
       dbms_output.put_line('+');
       dbms_output.put_line('+  See My Oracle Support article 1063123.1 for instructions on additional troubleshooting of the extract process, if needed.'); 
       dbms_output.put_line('+');
    end if;


  for rec in capture_latency(capture_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the Capture process ''' || rec.capture_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the Capture process is in processing the');
      dbms_output.put_line('+    redo log.  ');
      dbms_output.put_line('+  If OGG version is 11.2.1.0.7 thru 11.2.1.0.12, upgrade to  version 11.2.1.0.13 or above  ( My Oracle Support article 1589437.1 )' );
       dbms_output.put_line('+');
      dbms_output.put_line('+  If this latency is chronic and not due');
      dbms_output.put_line('+     to errors or OGG version, consider the above suggestions for improving Capture Performance');
      dbms_output.put_line('+');
    end if;
  end loop;

  for rec in apply_reader_latency(applyrdr_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the reader process for Apply ''' || rec.apply_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the Apply reader is from when the message was');
      dbms_output.put_line('+    created, which in the normal case is by a Capture process.  In other words, ');
      dbms_output.put_line('+    the time between message creation and message dequeue by the Apply reader is too large.');
      dbms_output.put_line('+    If this latency is chronic and not due to errors, consider the above suggestions ');
      dbms_output.put_line('+    for improving Capture and Propagation performance.');
      dbms_output.put_line('+');
    end if;
  end loop;

  for rec in apply_lwm_latency(applylwm_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the coordinator process for Apply ''' || rec.apply_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the low-watermark of the Apply process is');
      dbms_output.put_line('+    from when the message was first created, which in the normal case is by a Capture process.');
      dbms_output.put_line('+    The low-watermark is the most recent transaction (in terms of SCN) that has been');
      dbms_output.put_line('+    successfully applied, for which all previous transactions have also been applied.');
      dbms_output.put_line('+    A high latency can be due to long-running tranactions, many dependent transactions,');
      dbms_output.put_line('+    or slow Capture, Propagation, or Apply processes.');
      dbms_output.put_line('+');
    end if;
  end loop;

  -- check queue performance
  for rec in queue_stats loop
    if rec.num_msgs > unconsumed_msgs_threshold then
      dbms_output.put_line('+  <b>WARNING</b>:  There are ' || rec.num_msgs || ' unconsumed messages in queue ''' || rec.queue_schema ||
                           '''.''' || rec.queue_name || '''!');
      dbms_output.put_line('+');
    end if;
     dbms_output.put_line('+');

  end loop;

   -- logminer spill time
  for rec in logminer_spill_time(logminer_spill_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  Excessive spill time for Capture process ''' 
                          || rec.capture_name || '''!');
    if verbose then
      dbms_output.put_line('+    Spill time implies that the Logminer component used by Capture ');
      dbms_output.put_line('+    does not have enough memory allocated to it.  This condition ');
      dbms_output.put_line('+    occurs when the system workload contains many DDLs and/or LOB');
      dbms_output.put_line('+    transactions.  Consider increasing the size of memory allocated to the');
      dbms_output.put_line('+    Capture process by increasing the ''MAX_SGA_SIZE''extract parameter TRANLOGOPTIONS INTEGRATEDPARAMS.');
    end if;
    dbms_output.put_line('+');
  end loop;

  -- sql executions in rule sets
  for rec in complex_rule_sets_cap loop
    complex_rules := TRUE;
    dbms_output.put_line('+  <b>WARNING</b>:  Complex rules exist for Capture process ''' 
                          || rec.capture_name || ' and rule set ''' 
                          || rec.owner || '''.''' || rec.name || '''!');
  end loop;



  for rec in complex_rule_sets_apply loop
    complex_rules := TRUE;
    dbms_output.put_line('+  <b>WARNING</b>:  Complex rules exist for Apply process ''' 
                          || rec.apply_name || ' and rule set ''' 
                          || rec.owner || '''.''' || rec.name || '''!');
  end loop;

  if verbose and complex_rules then 
    dbms_output.put_line('+    Complex rules require SQL evaluations per message by a GoldenGate ');
    dbms_output.put_line('+    process.  This slows down performance and should be avoided ');
    dbms_output.put_line('+    if possible.  Examine the rules in the rule set (for example');
    dbms_output.put_line('+    by looking at DBA_RULE_SET_RULES and DBA_RULES) and avoid uses');
    dbms_output.put_line('+    of the ''like'' operator and function/procedure calls in rule'); 
    dbms_output.put_line('+    conditions unless absolutely necessary.'); 
  end if;
  dbms_output.put_line('+');



end;
/

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 

set lines 180
set numf 9999999999999999999
set pages 9999
col apply_database_link HEAD 'Database Link|for Remote|Apply' format a15
set feedback on

prompt ============================================================================================
prompt
prompt ++ <a name="Database">DATABASE INFORMATION</a> ++
COL MIN_LOG FORMAT A7
COL PK_LOG FORMAT A6
COL UI_LOG FORMAT A6
COL FK_LOG FORMAT A6
COL ALL_LOG FORMAT A6
COL FORCE_LOG FORMAT A10
col archive_change# format 999999999999999999
col archivelog_change# format 999999999999999999
COL NAME HEADING 'Name'
col platform_name format a30 wrap
col current_scn format 99999999999999999

SELECT DBid,name,created,
SUPPLEMENTAL_LOG_DATA_MIN MIN_LOG,SUPPLEMENTAL_LOG_DATA_PK PK_LOG,
SUPPLEMENTAL_LOG_DATA_UI UI_LOG, 
SUPPLEMENTAL_LOG_DATA_FK FK_LOG,
SUPPLEMENTAL_LOG_DATA_ALL ALL_LOG,
 FORCE_LOGGING FORCE_LOG, 
resetlogs_time,log_mode, archive_change#,
open_mode,database_role,archivelog_change# , current_scn, min_required_capture_change#, platform_id, platform_name from v$database;

prompt
col banner heading 'Database Edition'
select * from v$version where banner like 'Oracle%';

prompt ============================================================================================
prompt
prompt ++ INSTANCE INFORMATION ++
col host format a20 wrap 
col blocked heading 'Blocked?'  format a8
col shutdown_pending Heading 'Shutdown|Pending?' format a8
col parallel Heading 'Parallel' format a8
col archiver Heading 'Archiver'
col active_state Heading 'Active|State' 
col instance heading 'Instance'
col name heading 'Name'
col host Heading 'Host'
col version heading 'Version'
col startup_time heading 'Startup|Time'
col status Heading 'Status'
col logins Heading 'Logins'
col instance_role Heading 'Instance|Role'

select instance_number INSTANCE, instance_name NAME, HOST_NAME HOST, VERSION,
STARTUP_TIME, STATUS, PARALLEL, ARCHIVER, LOGINS, SHUTDOWN_PENDING, INSTANCE_ROLE, ACTIVE_STATE, BLOCKED  from gv$instance;
prompt
prompt ============================================================================================

prompt +++  Current Database Incarnation   +++
prompt

col incarnation# HEADING 'Current|Incarnation' format 9999999999999999
col resetlogs_id HEADING 'ResetLogs|Id'  format 9999999999999999
col resetlogs_change# HEADING 'ResetLogs|Change Number' format 9999999999999999

Select Incarnation#, resetlogs_id,resetlogs_change# from v$database_incarnation where status = 'CURRENT';

prompt ============================================================================================
prompt
prompt ++ REGISTRY INFORMATION ++
col comp_id format a10 wrap Head 'Comp_ID'
col comp_name format a35 wrap Head 'Comp_Name'
col version format a10 wrap Head Version
col schema format a10 Head Schema
col modified Head Modified

select comp_id, comp_name,version,status,modified,schema from DBA_REGISTRY;

prompt +++ REGISTRY HISTORY +++
prompt
select * from dba_registry_history;
prompt

prompt ============================================================================================
prompt
prompt ++ NLS DATABASE PARAMETERS ++
col parameter format a30 wrap
col value format a30 wrap

select * from NLS_DATABASE_PARAMETERS;

prompt ============================================================================================
prompt
prompt ++ GLOBAL NAME ++


select global_name from global_name;

prompt
prompt ============================================================================================
prompt
prompt ++ Key Init.ORA parameters ++
prompt
col name HEADING 'Parameter|Name' format a30
col value HEADING 'Parameter|Value' format a15
col description HEADING 'Description' format a60 word

select name,value,description from v$parameter where name in
   ('archive_lag_target', 
    'shared_pool_size', 'sga_max_size', 
    'memory_max_target','memory_target',
    'sga_target','streams_pool_size',
    'compatible','log_parallelism',
    'logmnr_max_persistent_sessions', 
    'processes', 'sessions',
    'control_file_record_keep_time'
    );



prompt
prompt ============================================================================================
prompt
prompt ++  GoldenGate Administrator  ++
column username heading 'Administrator|Name' format a30
column priv_type Heading 'Privilege|Type' format a16
column priv_model Heading 'Privilege|Model' format a20
column create_time Heading 'Created' format a30
prompt
prompt Trusted privilege model administrators typically use DBA and V$ views to monitor the configuration
prompt Untrusted privilege model administrators use ALL and V$ views to monitor the configuration
prompt

select username,decode(privilege_type,'CAPTURE','CAPTURE','APPLY','APPLY','*','CAPTURE + APPLY',NULL) priv_type,decode(grant_select_privileges,'YES','Trusted (full)','NO','Untrusted (minimum)',null) priv_model, create_time  from DBA_goldengate_privileges;

prompt ++   Oracle Streams Administrator ++
prompt
column username heading 'Administrator|Name'
column local_privileges Heading 'Local|Privileges' format a10
column access_from_remote Heading 'Remote|Access' format a10

select * From dba_streams_administrator;

prompt
prompt  ++ Database User information
prompt
select username,user_id,account_status,created, lock_date,expiry_date,default_tablespace,
       profile, initial_rsrc_consumer_group, 
       password_versions, editions_enabled, authentication_type,
       external_name
  from dba_users 
  where
    username in  (select capture_user from dba_capture where purpose like 'GoldenGate%' union select apply_name from dba_apply  where purpose like 'GoldenGate%' union select username from dba_goldengate_privileges)  
order by 1;
prompt ============================================================================================

prompt 
prompt ++ <a name="Queues in Database"> QUEUES IN DATABASE</a> ++
prompt ==========================================================================================

prompt
COLUMN OWNER HEADING 'Owner' FORMAT A10
COLUMN NAME HEADING 'Queue Name' FORMAT A30
COLUMN QUEUE_TABLE HEADING 'Queue Table' FORMAT A30
COLUMN ENQUEUE_ENABLED HEADING 'Enqueue|Enabled' FORMAT A7
COLUMN DEQUEUE_ENABLED HEADING 'Dequeue|Enabled' FORMAT A7
COLUMN USER_COMMENT HEADING 'Comment' FORMAT A20
COLUMN PRIMARY_INSTANCE HEADING 'Primary|Instance|Owner'FORMAT 999999
column SECONDARY_INSTANCE HEADING 'Secondary|Instance|Owner' FORMAT 999999
COLUMN OWNER_INSTANCE HEADING 'Owner|Instance' FORMAT 999999
column NETWORK_NAME HEADING 'Network|Name' FORMAT A30

SELECT q.OWNER, q.NAME, t.QUEUE_TABLE, q.enqueue_enabled, 
  q.dequeue_enabled,t.primary_instance,t.secondary_instance, t.owner_instance,network_name, q.USER_COMMENT
  FROM DBA_QUEUES q, DBA_QUEUE_TABLES t
  WHERE t.OBJECT_TYPE = 'SYS.ANYDATA' AND
        q.QUEUE_TABLE = t.QUEUE_TABLE AND
        q.OWNER       = t.OWNER
    order by owner,queue_table,name;
prompt

prompt
prompt  +++   Queue Subscribers   ++
prompt

column subscriber HEADING 'Subscriber' format a35 wrap
column name HEADING 'Queue|Name' format a35 wrap
column delivery_mode HEADING 'Delivery|Mode' format a23
column queue_to_queue HEADING 'Queue to|Queue' format a5
column protocol clear
column protocol HEADING 'Protocol'
SELECT qs.owner||'.'||qs.queue_name name, qs.queue_table, 
       NVL2(qs.consumer_name,'CONSUMER: ','ADDRESS : ') ||
       NVL(qs.consumer_name,qs.address) Subscriber,
       qs.delivery_mode,qs.queue_to_queue,qs.protocol
FROM dba_queue_subscribers qs, dba_queue_tables qt
WHERE  qt.OBJECT_TYPE = 'SYS.ANYDATA'  AND
       qs.QUEUE_TABLE = qt.QUEUE_TABLE AND
       qs.OWNER = qt.OWNER
ORDER BY qs.owner,qs.queue_name;




prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 



prompt =========================================================================================
prompt
prompt ++ Minimum Archive Log Necessary to Restart Integrated Capture (local capture)++   
prompt Note:  This query is valid for databases where the capture processes exist for the same local source database.
prompt
col name format a60 head 'Log Name'
col consumer_name format a30 head 'Capture Name'
col first_time head 'First SCN Timestamp'

SELECT ral.consumer_name ,ral.name,ral.first_time  
               from DBA_REGISTERED_ARCHIVED_LOG ral , v$database db
               where db.min_required_capture_change#  >= ral.first_scn and db.min_required_capture_change# < ral.next_scn order by thread# ;


prompt ============================================================================================



prompt

prompt  ++ EXTRACT INFORMATION: Client
col capture_name HEADING 'Capture|Name' format a30 wrap
col status HEADING 'Capture|Status' format a10 wrap
col client_name HEADING 'Extract|Name' format a30 wrap
col Client_status HEADING 'Client|Status' format a15 wrap


SELECT substr(capture_name,9,8) client_name ,
capture_name, status,  
decode(purpose, 'GoldenGate Capture','Integrated Capture','Streams', 'Classic Capture','*',NULL) extract_mode 
,error_number, status_change_time, error_message 
FROM dba_CAPTURE where purpose like 'GoldenGate%' or capture_name like 'OGG%$%' order by capture_name;


prompt
prompt  ++ Integrated Capture Version
prompt

col capture_name Heading 'Capture Name' format a20
col version  Heading 'Version'format a7

select capname_knstcap capture_name, decode(bitand(flags_knstcap,64), 64,'V2','<b>V1</b>') version from x$knstcap order by version, capture_name;


prompt
prompt  ++ <a name="Capture Processes">CAPTURE PROCESSES IN DATABASE</a> ++  
col start_scn format 9999999999999999
col applied_scn format 9999999999999999 
col capture_name HEADING 'Capture|Name' format a30 wrap
col status HEADING 'Status' format a10 wrap
col capture_user Heading 'Capture|User' format a15 wrap

col QUEUE HEADING 'Queue' format a25 wrap
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col capture_type HEADING 'Capture|Type' format a10 wrap
col error_message HEADING 'Capture|Error Message' format a60 word
col logfile_assignment HEADING 'Logfile|Assignment'
col checkpoint_retention_time HEADING 'Days to |Retain|Checkpoints'
col Status_change_time HEADING 'Status|Timestamp'
col error_number HEADING 'Error|Number'
col version HEADING 'Version'
col purpose HEADING 'Purpose'
prompt
prompt  Applied_scn in DBA_CAPTURE view is the same as OGG Bounded Recovery (BR) scn
prompt  For OGG IO scn, check DBA_APPLY_PROGRESS view column oldest_scn
prompt

SELECT capture_name, 
queue_owner||'.'||queue_name QUEUE, capture_type, purpose,status,capture_user,
rule_set_owner||'.'||rule_set_name RSN, negative_rule_set_owner||'.'||negative_rule_set_name RSN2, 
DECODE(checkpoint_retention_time,60,'<b><a href="#Notification">'||checkpoint_retention_time||'</a></b>',checkpoint_retention_time ) checkpoint_retention_time,
version, logfile_assignment,error_number, status_change_time, error_message 
FROM DBA_CAPTURE where purpose like 'GoldenGate%' or capture_name like 'OGG%$%' order by capture_name;


prompt  ++ CAPTURE PROCESS SOURCE INFORMATION ++  

col QUEUE HEADING 'Queue' format a25 wrap
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col capture_type HEADING 'Capture|Type' format a10 wrap
col source_database HEADING 'Source|Database' format a30 wrap
col first_scn HEADING 'First|SCN' 
col start_scn HEADING 'Start|SCN'  
col captured_scn HEADING 'Captured|SCN'
col applied_scn HEADING 'Applied|SCN'
col last_enqueued_scn HEADING 'Last|Enqueued|SCN'
col required_checkpoint_scn HEADING 'Required|Checkpoint|SCN'
col max_checkpoint_scn HEADING 'Maximum|Checkpoint|SCN'
col source_dbid HEADING 'Source|Database|ID'
col source_resetlogs_scn HEADING 'Source|ResetLogs|SCN'
col logminer_id HEADING 'Logminer|Session|ID'
col source_resetlogs_time HEADING 'Source|ResetLogs|Time'


SELECT capture_name, capture_type, source_database,  
 captured_scn, applied_scn, last_enqueued_scn,
required_checkpoint_scn,
max_checkpoint_scn,
first_scn, start_scn ||' ('||start_time||') ' start_scn, source_dbid, source_resetlogs_scn, 
source_resetlogs_time, logminer_id
FROM DBA_CAPTURE  where purpose like 'GoldenGate%' or capture_name like 'OGG%$%'  order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt ++ <a name=CapParameters>CAPTURE PROCESS PARAMETERS</a> ++
prompt    Parameters set by Oracle GoldenGate Extract
prompt
col CAPTURE_NAME  HEADING 'Capture|Name' format a30 wrap
col parameter HEADING 'Parameter|Name' format a28
col value HEADING 'Parameter|Value' format a20
col set_by_user HEADING 'Usr|Set?'format a3


select cp.* from dba_capture_parameters cp,dba_capture c   where c.purpose like 'GoldenGate%' and c.capture_name = cp.capture_name and cp.set_by_user='YES' order by cp.capture_name,PARAMETER ; 
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt ============================================================================================
prompt
prompt ++ CAPTURE RULES  ++
col NAME Heading 'Capture|Name' format a25 wrap
col object format a45 wrap heading 'Object'

col source_database format a15 wrap
col rule_set_type heading 'Rule Set|Type'
col RULE format a45 wrap  heading 'Rule |Name'
col TYPE format a15 wrap heading 'Rule |Type'
col dml_condition format a40 wrap heading 'Rule|Condition'
col include_tagged_lcr heading 'Tagged|LCRs?' format a7
col same_rule_condition Head 'Rule Condition|Same as Orig?' format a14


select sr.streams_name NAME,sr.schema_name||'.'||sr.object_name OBJECT, 
sr.rule_set_type,
sr.SOURCE_DATABASE, 
sr.STREAMS_RULE_TYPE ||' '||sr.Rule_type TYPE ,
sr.INCLUDE_TAGGED_LCR, sr.same_rule_condition, 
sr.rule_owner||'.'||sr.rule_name RULE
from dba_streams_rules sr, dba_capture c where sr.streams_type = 'CAPTURE' 
and c.capture_name=sr.streams_name and c.purpose like 'GoldenGate%'
order by name,object, sr.source_database, sr.rule_set_type,rule;




prompt
prompt ++ CAPTURE RULES BY RULE SET ++
col capture_name format a25 wrap  heading 'Capture|Name'
col RULE_SET format a25 wrap heading 'Rule Set|Name'
col RULE_NAME format a25 wrap heading 'Rule|Name'
col condition format a50 wrap heading 'Rule|Condition'
set long 4000 
REM break on rule_set

select c.capture_name, rsr.rule_set_owner||'.'||rsr.rule_set_name RULE_SET ,rsr.rule_owner||'.'||rsr.rule_name RULE_NAME, 
r.rule_condition CONDITION from
dba_rule_set_rules rsr, DBA_RULES r ,DBA_CAPTURE c
where rsr.rule_name = r.rule_name and rsr.rule_owner = r.rule_owner  and 
rsr.rule_set_owner=c.rule_set_owner and rsr.rule_set_name=c.rule_set_name  and rsr.rule_set_name in 
(select rule_set_name from dba_capture where c.purpose like 'GoldenGate%') order by rsr.rule_set_owner,rsr.rule_set_name;

prompt  +** CAPTURE RULES IN NEGATIVE RULE SET **+
prompt
select c.capture_name, rsr.rule_set_owner||'.'||rsr.rule_set_name RULE_SET ,rsr.rule_owner||'.'||rsr.rule_name RULE_NAME, 
r.rule_condition CONDITION from
dba_rule_set_rules rsr, DBA_RULES r ,DBA_CAPTURE c
where rsr.rule_name = r.rule_name and rsr.rule_owner = r.rule_owner and 
rsr.rule_set_owner=c.negative_rule_set_owner and rsr.rule_set_name=c.negative_rule_set_name 
 and rsr.rule_set_name in 
(select negative_rule_set_name rule_set_name from dba_capture where c.purpose like 'GoldenGate%') order by rsr.rule_set_owner,rsr.rule_set_name;




prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt
prompt ============================================================================================
prompt
prompt ++  Registered Log Files for Capture ++
prompt

COLUMN CONSUMER_NAME HEADING 'Capture|Process|Name' FORMAT A15
COLUMN SOURCE_DATABASE HEADING 'Source|Database' FORMAT A10
COLUMN SEQUENCE# HEADING 'Sequence|Number' FORMAT 999999
COLUMN NAME HEADING 'Archived Redo Log|File Name' format a35
column first_scn HEADING 'Archived Log|First SCN' 
COLUMN FIRST_TIME HEADING 'Archived Log Begin|Timestamp' 
column next_scn HEADING 'Archived Log|Last SCN' 
COLUMN NEXT_TIME HEADING 'Archived Log Last|Timestamp' 
COLUMN MODIFIED_TIME HEADING 'Archived Log|Registered Time'
COLUMN DICTIONARY_BEGIN HEADING 'Dictionary|Build|Begin' format A6
COLUMN DICTIONARY_END HEADING 'Dictionary|Build|End' format A6
COLUMN PURGEABLE HEADING 'Purgeable|Archive|Log' format a9

SELECT r.CONSUMER_NAME,
       r.SOURCE_DATABASE,
       r.thread#,
       r.SEQUENCE#, 
       r.NAME, 
       r.first_scn,
       r.FIRST_TIME,
       r.next_scn,
       r.next_time,
       r.MODIFIED_TIME,
       r.DICTIONARY_BEGIN, 
       r.DICTIONARY_END, 
       r.purgeable
  FROM DBA_REGISTERED_ARCHIVED_LOG r, DBA_CAPTURE c
  WHERE r.CONSUMER_NAME = c.CAPTURE_NAME and c.purpose like 'GoldenGate%'
  ORDER BY source_database, consumer_name, r.first_scn; 

prompt ============================================================================================
prompt
prompt ++  CAPTURE EXTRA ATTRIBUTES ++
 
COLUMN CAPTURE_NAME HEADING 'Capture Process' FORMAT A30
COLUMN ATTRIBUTE_NAME HEADING 'Attribute Name' FORMAT A15
COLUMN INCLUDE HEADING 'Include Attribute in LCRs?' FORMAT A30
COLUMN ROW_ATTRIBUTE HEADING 'Row' format A3
COLUMN DDL_ATTRIBUTE Heading 'DDL' format A3

SELECT ca.CAPTURE_NAME, ca.ATTRIBUTE_NAME, ca.ROW_ATTRIBUTE, ca.DDL_ATTRIBUTE, ca.INCLUDE 
  FROM DBA_CAPTURE_EXTRA_ATTRIBUTES ca, dba_capture c
  where c.purpose like 'GoldenGate%' and ca.capture_name=c.capture_name ORDER BY ca.CAPTURE_NAME ;




prompt ============================================================================================
prompt


prompt ++  SCHEMAS PREPARED ALLKEY FOR GG CAPTURE ++

select * from SYS.LOGMNR$SCHEMA_ALLKEY_SUPLOG order by 1;


prompt ============================================================================================
prompt
prompt ++  TABLES WITH SUPPLEMENTAL LOGGING  ++
col OWNER format a30 wrap
col table_name format a30 wrap

select distinct owner,table_name from dba_log_groups;

prompt ++ DATABASE PREPARED FOR CAPTURE ++
col SUPPLEMENTAL_LOG_DATA_PK head 'PK Logging' format a11
col SUPPLEMENTAL_LOG_DATA_UI head 'UI Logging' format a11
col SUPPLEMENTAL_LOG_DATA_FK head 'FK Logging' format a11
col SUPPLEMENTAL_LOG_DATA_ALL head 'ALL Logging' format a11
col TIMESTAMP head 'Timestamp'

select cp.* from dba_capture_prepared_database cp, dba_capture c where c.purpose like 'GoldenGate%';

prompt
prompt ++  TABLE LEVEL SUPPLEMENTAL LOG GROUPS ENABLED FOR CAPTURE ++
col object format a40 wrap
col column_name format a30 wrap
col log_group_name format a25 wrap

select owner||'.'||table_name OBJECT, log_group_name, log_group_type,   decode(always,'ALWAYS','Unconditional','CONDITIONAL','Conditional',NULL,'Conditional') ALWAYS, generated from dba_log_groups;

prompt ++ SUPPLEMENTALLY LOGGED COLUMNS ++
col logging_property heading 'Logging|Property' format a9
prompt Skipping query for supplementally logged columns

REM select owner||'.'||table_name OBJECT, log_group_name, column_name,position,LOGGING_PROPERTY from dba_log_group_columns;







prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt
prompt
prompt ============================================================================================

prompt
prompt ++ <a name="Outbound Server Processes">GoldenGate CONFIGURATION</a> ++


prompt
col source_database format a40 wrap Heading 'Source|Database'
COLUMN SERVER_NAME HEADING 'Server|Name' 
COLUMN CAPTURE_NAME HEADING 'Capture|Process' 
COLUMN CAPTURE_USER HEADING 'Capture|User'
COLUMN committed_data_only HEADING 'Committed|Data Only'
COLUMN Start_scn Heading 'Start SCN' format 9999999999999999
COLUMN Connect_user Heading 'Connect|User'
Column Create_date Heading 'Create|Date'
Column Start_time Heading 'Start Time'

column queue_owner Heading 'Queue|Owner'
column queue_name Heading 'Queue|Name'
column apply_user Heading 'Apply|User'
column User_comment Heading 'User|Comment'




prompt

Select SERVER_NAME, STATUS, CONNECT_USER, CAPTURE_NAME, SOURCE_DATABASE,  
START_SCN ||' ('|| START_TIME||')' as "Start_SCN(Start_Time)", CAPTURE_USER,  QUEUE_OWNER,
QUEUE_NAME, USER_COMMENT, CREATE_DATE
from dba_xstream_outbound where committed_data_only='NO' order by 1; 

 

col apply_name format a25 wrap heading 'Outbound|Server Name'
col queue format a25 wrap heading 'Queue|Name'
col apply_tag format a7 wrap  heading 'Apply|Tag'
col ruleset format a25 wrap heading 'Rule Set|Name'
col apply_user format a15 wrap heading 'Apply|User'
col capture_user format a15 wrap heading 'Capture|User'
col apply_captured format a15 wrap heading 'Captured or|User Enqueued'
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col message_delivery_mode HEADING 'Message|Delivery' format a15
col apply_database_link HEADING 'Remote Apply|Database Link' format a25 wrap
col extract HEADING Extract|Name format a25

Select apply_name,status,replace(apply_name,'OGG$','') Extract, queue_owner||'.'||queue_name QUEUE,
 a.apply_user, apply_tag, rule_set_owner||'.'||rule_set_name RSN,
negative_rule_set_owner||'.'||negative_rule_set_name RSN2 
 from DBA_APPLY a where a.purpose like 'GoldenGate%' order by 1;

prompt ++   PROCESS INFORMATION ++
col applied_scn HEADING 'Minimum Applied|Message Number' 
col error_message HEADING 'Capture|Error Message' format a60 wrap
prompt  This command must be run as SYS
prompt

  select xo.server_name, c.applied_scn,
       xo_status, c.status_change_time,c.error_number,
  case
    when c.error_number =1013
      then 'STOP EXTRACT command performed ( '||c.error_message||' )'
    when xo_status ='DETACHED' then 'Extract is not started'
    else c.error_message
    end   error_message
  from   dba_xstream_outbound xo, dba_capture c,
      (select xo.capture_name ,case when (bitand(cp.flags_knstcap, 64) = 64)
         then 'ATTACHED'
         else decode(xo.status, 'ATTACHED', 'ATTACHED', 'DETACHED')
     end xo_status
       from dba_xstream_outbound xo, x$knstcap cp
       where cp.capname_knstcap (+)= xo.capture_name )  d
  where c.purpose like 'GoldenGate%' and
  xo.capture_name=d.capture_name and
 xo.capture_name=c.capture_name order by 1;




prompt


prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 



prompt
prompt =================================================================================
prompt




prompt
prompt 
prompt ++  OGG Outbound Progress Table ++
prompt
col processed_low_position format a40 wrap
col applied_low_position format a40 wrap
col applied_high_position format a40 wrap
col spill_position format a40 wrap

select xop.* From dba_xstream_outbound_progress xop , dba_apply a where xop.server_name=a.apply_name and a.purpose like 'Golden%' order by server_name;

prompt  ++  APPLY PROGRESS ++
prompt
prompt  Oldest Message SCN (oldest_message_number column in DBA_APPLY_PROGRESS) is the same as OGG IO scn
prompt
col oldest_message_number HEADING 'Oldest|Message|SCN'
col apply_time HEADING 'Apply|Timestamp'
select ap.* from dba_apply_progress ap, dba_apply a where a.purpose like 'GoldenGate%' and ap.apply_name=a.apply_name and a.purpose like 'Golden%';




prompt ============================================================================================
prompt
prompt ++ DBA OBJECTS - Rules, and CAPTURE/APPLY Processes ++
prompt
col OBJECT format a45 wrap heading 'Object'

select owner||'.'||object_name OBJECT,
      object_id,object_type,created,last_ddl_time, status from
      dba_objects
    WHERE object_type in ('CAPTURE','APPLY')
    OR   (object_type in ('RULE','RULE SET') AND OWNER in (select username from DBA_goldengate_privileges))
    order by object_type, object;



prompt
prompt ============================================================================================
prompt

prompt
prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 



prompt
prompt ++    <a name="History"> History</a>   ++
prompt

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

prompt
prompt ++ Buffered Queue History for last day ++

select s.begin_interval_time,s.end_interval_time , 
   bq.snap_id, 
   bq.num_msgs, bq.spill_msgs, bq.cnum_msgs, bq.cspill_msgs,
   bq.queue_schema||'.'||bq.queue_name Queue,
   bq.queue_id, bq.startup_time,bq.instance_number,bq.dbid
from   dba_hist_buffered_queues bq, dba_hist_snapshot s 
where  bq.snap_id=s.snap_id   and s.end_interval_time >= systimestamp-1 
       and bq.instance_number =s.instance_number
order by bq.queue_schema,bq.queue_name,s.end_interval_time;


prompt
prompt ++ Buffered Subscriber History for last day ++

select s.begin_interval_time,s.end_interval_time , 
   bs.snap_id,bs.subscriber_id, 
   bs.num_msgs, bs.cnum_msgs, bs.total_spilled_msg,
   bs.subscriber_name,subscriber_address,
   bs.queue_schema||'.'||bs.queue_name Queue,
   bs.startup_time,bs.instance_number,bs.dbid
from   dba_hist_buffered_subscribers bs, dba_hist_snapshot s 
where    bs.snap_id=s.snap_id and s.end_interval_time >= systimestamp-1 
       and bs.instance_number =s.instance_number
order by    bs.queue_schema,bs.queue_name,bs.subscriber_id,s.end_interval_time;



prompt
prompt ++ Capture History for last day ++
column total_messages_created HEADING 'Total|Messages|Created'
column total_messages_enqueued HEADING 'Total Messages|Enqueued'
column lag HEADING 'Capture|Lag|(Seconds)' format 99999.99
column elapsed_capture HEADING 'Elapsed Time|Capture|(centisecs'
column elapsed_rule_time HEADING 'Elapsed Time|Rule Evaluation|(centisecs)'
column elapsed_enqueue_time HEADING 'Elapsed Time|Enqueuing Messages|(centisecs)'
column elapsed_lcr HEADING 'Elapsed Time|LCR Creation|(centisecs)'
column elapsed_redo_wait_time HEADING 'Elapsed Time|Redo Wait|(centisecs)'
column elapsed_Pause_time HEADING 'Elapsed Time|Paused|(centisecs)'



select s.begin_interval_time,s.end_interval_time , 
   sc.capture_name,sc.lag,
   sc.total_messages_captured,sc.total_messages_enqueued,
   sc.elapsed_pause_time,
   sc.elapsed_redo_wait_time, 
   sc.elapsed_rule_time, sc.elapsed_enqueue_time, 
   sc.startup_time,sc.instance_number,sc.dbid
from   dba_hist_streams_capture sc, dba_hist_snapshot s 
where  sc.capture_name in (select capture_name from dba_capture where purpose like 'GoldenGate%') and
sc.snap_id=s.snap_id       and s.end_interval_time >= systimestamp-1 
       and sc.instance_number =s.instance_number
order by sc.capture_name,s.end_interval_time;






prompt
prompt ++    <a name="Rules"> SUSPICIOUS   RULES</a>   ++
prompt
col object format a45 wrap
col rule format a45 wrap


REM  This script does sanity checking of OGG and Streams objects compared to the underlying RULES.


prompt
prompt ++ Check for EXTRA RULES IN DBA_RULES ++
prompt .  Rows are returned if a rule is defined in the DBA_RULES view 
prompt .  but does not exist in the DBA_STREAMS_RULES  view.
prompt
col rule_name format a30

select rule_owner,rule_name from dba_rules where (rule_name  not like 'ALERT_QUE%' and rule_owner != 'SYS')
MINUS 
select rule_owner,rule_name from dba_streams_rules;

prompt
prompt ++ Check for RULE_CONDITIONS DO NOT MATCH BETWEEN STREAMS AND RULES ++
prompt .  Rows are returned if the rule condition is different between the DBA_STREAMS_RULES view
prompt .  and the DBA_RULES view.  This indicates that a manual modification has been performed on the 
prompt .  underlying rule.  DBA_STREAMS_TABLE_RULES always shows the initial configuration rule condition. 
prompt

select s.streams_type, s.streams_name, r.rule_owner||'.'||r.rule_name RULE,r.rule_condition 
  from dba_streams_rules s, dba_rules r
  where r.rule_name=s.rule_name and r.rule_owner=s.rule_owner and 
  dbms_lob.substr(s.rule_condition) != dbms_lob.substr(r.rule_condition);

prompt
prompt ++ Check for SOURCE DATABASE NAME DOES NOT MATCH FOR CAPTURE  RULES ++

prompt .  Rows are returned if the source database column in the  DBA_STREAMS_ RULES view
prompt .  for capture  defined at this site does not match the 
prompt .  global_name of this site.  For capture rules, the source database must match the global_name
prompt .  of database.  
prompt .   In some cases, it may be correct to have a different source
prompt .  database name from the global name.  For example, at an intermediate node between a source site
prompt .  and the ultimate target site OR when using a downstream capture configuration, the rule source database 
prompt .  name field will be diferent from the local.  global name of the intermediate site.
prompt

select streams_type, streams_name, r.rule_owner||'.'||r.rule_name RULE from dba_streams_rules r
where source_database is not null and source_database != (select global_name from global_name) and streams_type in ('CAPTURE');



prompt
REM prompt ++ Check for No RULE SET DEFINED FOR INTEGRATED CAPTURE ++
REM prompt
REM Prompt .  OGG Integrated Capture always configures a positive and negative rule set for capture
REM prompt

REM select capture_name, capture_type, source_database from dba_capture where rule_set_name is null and negative_rule_set_name is null and purpose like 'GoldenGate%';

rem prompt
rem prompt ++ Check for RULE SETs DEFINED FOR INTEGRATED CAPTURE OUTBOUND SERVER ++
rem prompt
rem Prompt .  OGG Integrated Capture never configures a positive or negative rule set for Apply (Outbound Server)
rem prompt

rem select apply_name from dba_apply where (rule_set_name is not null or  negative_rule_set_name is not null) and purpose ='GoldenGate Capture';



prompt
prompt ++ Check for SCHEMA RULES FOR NON_EXISTANT SCHEMA ++

select s.streams_type, s.streams_name, s.rule_owner||'.'||s.rule_name RULE, s.schema_name,
ac.nvn_name ACTION_CONTEXT_NAME, ac.nvn_value.accessvarchar2() ACTION_CONTEXT_VALUE
from dba_streams_rules s , dba_rules r, dba_users u, table(r.rule_action_context.actx_list) ac
where s.schema_name is null and u.username=s.schema_name 
and r.rule_owner=s.rule_owner and r.rule_name = s.rule_name and ac.nvn_value.accessvarchar2() is null;





prompt
--   To improve time in getting constraint info, compute Stats on sys.APPLY$_SOURCE_OBJ ; SYS only

--   analyze table  SYS.APPLY$_SOURCE_OBJ compute statistics;


REM prompt  
REM prompt ++ TABLES NOT SUPPORTED BY GOLDENGATE Integrated Capture ++
REM prompt  Lists tables that can not be supported by OGG 

REM select * from DBA_XSTREAM_OUT_SUPPORT_MODE where support_mode = 'NONE';




prompt
prompt ++ DICTIONARY INFORMATION ++
prompt    Capture processes defined on system
prompt

col queue format a30 wrap heading 'Queue|Name'
col capture_name format a20 wrap heading 'Capture|Name'
col capture# format 9999 heading 'Capture|Number'
col ruleset format a30 wrap heading 'Positive|Rule Set'
col ruleset2 format a30 wrap heading 'Negative|Rule Set'

select capture_name,status,purpose, checkpoint_retention_time,logminer_id,capture_type,required_checkpoint_scn from dba_capture order by capture_name;

select queue_owner||'.'||queue_name queue,capture_name,capture#,
   ruleset_owner||'.'||ruleset_name ruleset,
   negative_ruleset_owner||'.'||negative_ruleset_name ruleset2
   from sys.streams$_capture_process order by capture_name;

prompt
prompt    Apply processes defined on system
prompt
col apply_name format a20 wrap heading 'Apply|Name'
col apply# format 9999 heading 'Apply|Number'

select apply_name,status,purpose, apply_tag,apply_user,message_delivery_mode,error_number,error_message from dba_apply order by apply_name;

select queue_owner||'.'||queue_name queue,apply_name,apply#,
  ruleset_owner||'.'||ruleset_name  ruleset ,
  negative_ruleset_owner||'.'||negative_ruleset_name  ruleset2
  from sys.streams$_apply_process order by apply_name;

prompt
prompt    Propagations defined on system
prompt
col source_queue format a30 wrap heading 'Queue|Name'
col destination format a35 wrap heading 'Destination'

select source_queue_schema||'.'||source_queue source_queue, 
   destination_queue_schema||'.'||destination_queue||'@'||
   destination_dblink destination,
   ruleset_schema||'.'||ruleset ruleset,
   negative_ruleset_schema||'.'||negative_ruleset ruleset2
 from sys.STREAMS$_PROPAGATION_PROCESS;

prompt
prompt    Rules defined on system
prompt
col nbr format 9999999999999999 heading 'Number of|Rules'
col streams_name HEADING 'Streams Name' 
col streams_type HEADING 'Streams Type'

select streams_name,streams_type,count(*) nbr From sys.streams$_rules group by streams_name,streams_type;
prompt

prompt ++  GoldenGate sessions order by action
prompt   
prompt   SVR is server connection type:  DED=DEDICATED;  SHR=SHARED
prompt
col module format a30 wrap
col action format a40 wrap
col program format a30
col process format a15 wrap
col SVR format a3 Heading 'SVR'
col status heading 'Status'
col state heading 'State'

select inst_id,logon_time,s.sid, s.serial#,s.module,action,process, program,status,
decode(server,'DEDICATED','DED','SHR') SVR,s.state, s.event From gv$session s where (module = 'GoldenGate' or module like '%tream%' or module like 'OGG%') order by inst_id,module,action;

prompt
prompt  ++ Standby Redo Logs

select * from v$standby_log order by first_change#,thread#,sequence#;

prompt
prompt
prompt ++ 
prompt ++ <a name=LogmnrDetails>LOGMINER DATABASE MAP</a> ++
prompt    Databases with information in logminer tables
prompt
col global_name format a30 wrap heading 'Global|Name'
col logmnr_uid format 99999999  heading 'Logminer|Identifier';

select global_name,logmnr_uid,flags,'MAP' SRC from system.logmnrc_dbname_uid_map
union
select s.global_db_name,u.logmnr_uid,null,'UID$' SRC from system.logmnr_uid$ u , system.logmnr_session$ s
    where u.session#=s.session# order by 2;

prompt    LOGMNR_UID$ table
prompt
select * from system.logmnr_uid$;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt    LOGMNR_SESSION$ table
prompt
prompt
select * from system.logmnr_session$;
prompt
prompt <a href="#Summary">Return to Summary</a>
prompt
prompt ++  Logminer Dictionary Load ++
prompt
col command format a30
select * from gv$logmnr_dictionary_load order by 1,2,3;

prompt
prompt
prompt ++  LOGMINER PARAMETERS  ++
REM select * from system.logmnr_parameter$;
   SELECT session#, type, scn, name, value
      FROM SYSTEM.logmnr_parameter$
      ORDER BY session#, name; 
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
prompt ++  LOGMINER STATISTICS  ++
prompt 
COLUMN NAME HEADING 'Name' FORMAT A32
COLUMN VALUE HEADING 'Value' FORMAT 99999999999999999




select c.capture_name, name, value from gv$goldengate_capture c, gv$logmnr_stats l
 where c.logminer_id = l.session_id 
   order by capture_name,name;  

col capture_name format a15
column name format a40
column value format a30 
select c.capture_name, x.name,x .value from x$krvxsv x, dba_capture c where value != '0' and c.logminer_id=x.session_id order by capture_name, name;
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt ++  LOGMINER SESSION STATISTICS  ++
prompt 
select * from  gv$logmnr_session 
   order by session_name;  
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
REM prompt   Ordered by session_name
prompt
REM select session_name, USED_MEMORY_SIZE, DELIVERED_TXN, AVAILABLE_TXN, BUILDER_WORK_SIZE, PREPARED_WORK_SIZE from gv$logmnr_session order by available_txn; 
prompt      calculate difference, order by session_name
select sysdate, session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as difference,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size
      FROM v$logmnr_session order by session_name; 
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
prompt ++ LOGMINER CACHE OBJECTS ++
prompt     Objects of interest to Streams from each source database
prompt
col count(*) format 9999999999999999  heading 'Number of|Interesting|DB Objects';

select logmnr_uid, count(*) from system.logmnrc_gtlo group by logmnr_uid;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt     Intcol Verification
prompt  

select logmnr_uid, obj#, objv#, intcol#
      from system.logmnrc_gtcs
      group by logmnr_uid, obj#, objv#, intcol#
      having count(1) > 1
      order by 1,2,3,4;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
REM prompt     Segcol Verification  
REM prompt  Check bug 7033630 if rows returned

REM  removed 8/26/2013
REM select a.logmnr_uid,a.obj#,a.objv#,a.segcol#, a.intcol# from system.logmnrc_gtcs a
REM   where exists ( select 1 from system.logmnrc_gtcs b where
REM                           a.logmnr_uid = b.logmnr_uid and
REM                           a.obj# = b.obj# and
REM                           a.objv# = b.objv# and
REM                           a.segcol# = b.segcol# and
REM                           a.segcol# <> 0 and
REM                           a.intcol# <> b.intcol#);

prompt
prompt    ++   Streams Pool Statistics   ++
prompt
col total_memory_allocated Head 'Total Memory|Allocated'
col current_size  Head 'Streams Pool|Size'
col SGA_TARGET_VALUE Head 'SGA_TARGET|Value'
col used Head 'Total Memory|Allocated (MB)'
col max  Head 'Streams Pool|Size(MB)'
col pct Head 'Percent Memory|Used'
col shrink_phase Head 'Shrink|Phase'
col Advice_disabled Head 'Advice|Disabled'

select * from gv$streams_pool_statistics;
prompt 
select TOTAL_MEMORY_ALLOCATED/(1024*1024) as used_MB,  CURRENT_SIZE/(1024*1024) as  max_MB,  
decode(current_size, 0,to_number(null),(total_memory_allocated/current_size)*100) as pct_Streams_pool from gv$streams_pool_statistics;



prompt  ++  Streams Pool Statistics for capture session ++
prompt   .  Capture specific memory - excludes the logminer memory if bundled patch <= bp8
prompt   .  With BP11, capture memory includes logminer memory
prompt
set serveroutput on
col used Head 'Total Memory|Used (MB)'
col alloced  Head 'Total Memory|Allocated(MB)'
col pct Head 'Percent of Allocated|Memory Used'
col captured Head 'Total LCRs|Captured'
col enqueued Head 'Total LCRs|Enqueued'
select capture_name,sga_used/(1024*1024) as used, sga_allocated/(1024*1024) as alloced, (sga_used/sga_allocated)*100 as pct,total_messages_captured as msgs_captured, total_messages_enqueued as msgs_enqueued from gv$goldengate_capture order by capture_name;
prompt
prompt  ++ Memory Used by Logminer Sessions ++
col used Head 'Total Memory|Used (MB)'
col max  Head 'Total Memory|Allocated(MB)'
col pct Head 'Percent of Allocated|Memory Used'
select session_name, l.USED_MEMORY_SIZE/(1024*1024) as used_MB, l.MAX_MEMORY_SIZE/(1024*1024) as max_MB,  (l.USED_MEMORY_SIZE/l.MAX_MEMORY_SIZE)*100 as pct_logminer_mem_used, 
decode(s.current_size, 0,to_number(null),(l.max_memory_size/s.current_size)*100) pct_streams_pool from gv$logmnr_session l, gv$streams_pool_statistics s where l.inst_id=s.inst_id order by session_name;

prompt


prompt
prompt  ++ Streams Pool memory Information ++
prompt
col name heading 'NAME'
col value heading 'VALUE'

select * from x$knlasg;
prompt
prompt  ++  Cache statistics summary ++  
prompt     valid only if executed on instance running capture
set lines 180

select CAPNAME_KNSTCAPCACHE as capture, CACHENAME_KNSTCAPCACHE as cache, NUM_LCRS_KNSTCAPCACHE as lcrs, NUM_COLS_KNSTCAPCACHE as cols, TOTAL_MEM_KNSTCAPCACHE/(1024*1024) as mem from x$knstcapcache order by 1,2;
prompt
prompt  ++  Cache statistics  ++  
select * from x$knstcapcache;
prompt
prompt  ++ LCR Cache Information ++
prompt    Internal LCRs
select * from x$kngfl order by streams_name_kngfl,colcount_kngfl;
prompt
prompt    External LCRs
select * from x$kngfle order by streams_name_kngfl,colcount_kngfl;
prompt
prompt
prompt  ++ Queue Memory and Flow Control Values ++
prompt         FLCP_KWQBPMT is threshold for capture flow control
prompt         FRUSED_KWQBPMT is the percent of streams pool memory used
prompt
select * from x$kwqbpmt;

prompt 
prompt  ++ PGA Memory  ++
prompt         
prompt
col value format 999999999999999999
select * from gv$pgastat;
prompt

prompt 
prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 



prompt
Prompt   ++ JOBS in Database ++
prompt
set recsep each
set recsepchar =
select instance,job,what,log_user,priv_user,schema_user
      ,total_time,broken,interval,failures
      ,last_date,last_sec,this_date,this_sec,next_date,next_sec     
  from dba_jobs;

prompt ++ <a name="SECONDS">SCHEDULED JOBs run every SECOND</a>  ++
select owner,job_name,repeat_interval,enabled from dba_scheduler_jobs where repeat_interval ='FREQ=SECONDLY' and enabled='TRUE';

prompt
Prompt   ++ Scheduler Jobs in Database ++
prompt
select OWNER,JOB_NAME,JOB_SUBNAME,JOB_STYLE,JOB_CREATOR
,PROGRAM_OWNER,PROGRAM_NAME,JOB_TYPE,JOB_ACTION
,NUMBER_OF_ARGUMENTS
,SCHEDULE_OWNER,SCHEDULE_NAME,SCHEDULE_TYPE
,START_DATE,REPEAT_INTERVAL,END_DATE
,JOB_CLASS
,ENABLED
,AUTO_DROP
,RESTARTABLE
,STATE
,JOB_PRIORITY
,RUN_COUNT,MAX_RUNS,FAILURE_COUNT,MAX_FAILURES,RETRY_COUNT
,LAST_START_DATE,LAST_RUN_DURATION,NEXT_RUN_DATE,SCHEDULE_LIMIT,MAX_RUN_DURATION
,LOGGING_LEVEL
,STOP_ON_WINDOW_CLOSE
,INSTANCE_STICKINESS
,RAISE_EVENTS
,SYSTEM
,JOB_WEIGHT
,SOURCE
,NUMBER_OF_DESTINATIONS
,DESTINATION_OWNER
,DESTINATION
,CREDENTIAL_OWNER
,CREDENTIAL_NAME
,INSTANCE_ID
,DEFERRED_DROP
,ALLOW_RUNS_IN_RESTRICTED_MODE
 from dba_scheduler_jobs;

set recsep off



prompt
prompt  ++  Current Long Running Transactions  ++  
prompt  . Current Database transactions open for more than 20 minutes
prompt
col runlength HEAD 'Txn Open|Minutes' format 9999.99
col sid HEAD 'Session' format a13
col xid HEAD 'Transaction|ID' format a18
col terminal HEAD 'Terminal' format a10
col program HEAD 'Program' format a27 wrap
col start_scn HEAD 'Start|SCN' 

select t.inst_id, sid||','||serial# sid,xidusn||'.'||xidslot||'.'||xidsqn xid, 
(sysdate -  start_date ) * 1440 runlength ,terminal, start_scn,
program from gv$transaction t, gv$session s 
where t.addr=s.taddr and (sysdate - start_date) * 1440 > 20
order by t.inst_id asc, runlength desc;




prompt

prompt ++ <a name="Alerts">  ALERTS History </a> ++
prompt

prompt  +++ Outstanding alerts 
prompt

select message_type,creation_time,reason, suggested_action,
     module_id,object_type,
     instance_name||' (' ||instance_number||' )' Instance,
     time_suggested
from dba_outstanding_alerts 
   where creation_time >= sysdate -10 and rownum < 11
   order by creation_time desc;

prompt
prompt  +++ Most recent GoldenGate alerts(max=10) occuring within last 10 days +++
prompt
column Instance Heading 'Instance Name|(Instance Number)'
select message_Type,creation_time, reason,suggested_action,
       module_id,object_type,                    host_id,
       instance_name||'   ( '||instance_number||' )' Instance,      
       resolution,time_suggested
from dba_alert_history where message_group ='GoldenGate' 
      and creation_time >= sysdate -10 and rownum < 11
order by creation_time desc;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt
REM prompt  ++  Current Contents of the STREAMS Pool ++  
REM prompt   Applies only to versions 10.1.0.4+, and to this instance only
REM prompt   Do not use this query - can cause database to hang or crash

REM col comm HEAD 'Allocation Comment' format A18
REM col alloc_size HEAD 'Bytes Allocated' format 9999999999999999
REM select ksmchcom comm, sum(ksmchsiz) alloc_size from x$ksmsst group by ksmchcom order by 2 desc;

prompt

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt
prompt   ++ init.ora parameters ++
Prompt  Key parameters are aq_tm_processes, job_queue_processes
prompt                     streams_pool_size, sga_max_size,  compatible
prompt                     
col type heading 'TYPE'

show parameters

set serveroutput on 
prompt  ++  <a name="Statistics"> OGG Integrated Capture Statistics</a>  ++
prompt
alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
set heading off 
set feedback off
select 'OGG Integrated Capture Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on
set feedback on

prompt =========================================================================================
prompt
prompt ++ <a name="Queue Statistics">MESSAGES IN BUFFER QUEUE</a> ++
prompt
prompt
col QUEUE format a50 wrap
col "Message Count" format 9999999999999999 heading 'Current Number of|Outstanding|Messages|in Queue'

col "Total Messages" format 9999999999999999 heading 'Cumulative |Number| of Messages|in Queue'



SELECT queue_schema||'.'||queue_name Queue, startup_time, num_msgs "Message Count",  cnum_msgs "Total Messages" FROM  gv$buffered_queues;

prompt

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 

prompt
prompt  ++ Integrated Capture Information
prompt

col capture_name Heading 'Capture Name' format a20
col version  Heading 'Version'format a7

select capname_knstcap capture_name, decode(bitand(flags_knstcap,64), 64,'V2','<b><a href="#SYSCheck">V1</a></b>') version from x$knstcap order by version, capture_name;


prompt
col name format A30
col value$ format A30 HEADing 'Bundled Patch version'
select value$ from sys.props$ where name ='REPLICATION_BUNDLE';
prompt


prompt ============================================================================================
prompt
prompt ++ <a name="Capture Statistics">GOLDENGATE CAPTURE STATISTICS</a> ++
COLUMN PROCESS_NAME HEADING "Capture|Process|Number" FORMAT A7
COLUMN CAPTURE_NAME HEADING 'Capture|Name' 
COLUMN SID HEADING 'Session|ID' FORMAT 99999999999999
COLUMN SERIAL# HEADING 'Session|Serial|Number' 
COLUMN STATE HEADING 'State' FORMAT A17
column STATE_CHANGED_TIME HEADING 'Last|State Change|Time'
COLUMN TOTAL_MESSAGES_CAPTURED HEADING 'Redo Entries|Scanned'  
COLUMN TOTAL_MESSAGES_ENQUEUED HEADING 'Total|LCRs|Enqueued'  
COLUMN TOTAL_MESSAGES_CREATED HEADING 'Total|Messages|Created'  
COLUMN CAPTURE_TIME HEADING 'Capture Update|Timestamp'
Column PURPOSE  HEADING 'Capture|Purpose'
column CCA Heading 'CCA?'
column SGA_USED  Heading 'Streams Pool|Used|MB'
column SGA_ALLOCATED Heading 'Streams Pool| Allocated|MB'
column BYTES_MINED Heading 'Redo|Mined|MB '
column SESSION_RESTART_SCN Heading 'SCN at |Startup'

COLUMN LATENCY_SECONDS HEADING 'Latency|Seconds' FORMAT 9999999999999999
COLUMN CREATE_TIME HEADING 'Event Creation|Time' FORMAT A19
COLUMN ENQUEUE_TIME HEADING 'Last|Enqueue |Time' FORMAT A19
COLUMN ENQUEUE_MESSAGE_NUMBER HEADING 'Last Queued|Message Number' FORMAT 9999999999999999
COLUMN ENQUEUE_MESSAGE_CREATE_TIME HEADING 'Last Queued|Message|Create Time'FORMAT A19
COLUMN CAPTURE_MESSAGE_CREATE_TIME HEADING 'Last Redo|Message|Create Time' FORMAT A19
COLUMN CAPTURE_MESSAGE_NUMBER HEADING 'Last Redo|Message Number' FORMAT 9999999999999999
COLUMN AVAILABLE_MESSAGE_CREATE_TIME HEADING 'Available|Message|Create Time' FORMAT A19
COLUMN AVAILABLE_MESSAGE_NUMBER HEADING 'Available|Message Number' FORMAT 9999999999999999
COLUMN STARTUP_TIME HEADING 'Startup Timestamp' FORMAT A19

COLUMN MSG_STATE HEADING 'Message State' FORMAT A13
COLUMN CONSUMER_NAME HEADING 'Consumer' FORMAT A30

COLUMN PROPAGATION_NAME HEADING 'Propagation' FORMAT A8
COLUMN START_DATE HEADING 'Start Date'
COLUMN PROPAGATION_WINDOW HEADING 'Duration' FORMAT 99999
COLUMN NEXT_TIME HEADING 'Next|Time' FORMAT A8
COLUMN LATENCY HEADING 'Latency|Seconds' FORMAT 99999999


-- ALTER session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';

SELECT SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
       c.CAPTURE_NAME,
       C.STARTUP_TIME,
       c.SID,
       c.SERIAL#,
       DECODE (c.STATE,null,'<b><a href="#Performance Checks">WAITING FOR CLIENT REQUESTS</a></b>',
              'WAITING FOR INACTIVE DEQUEUERS','<b><a href="#Notification">'''||c.state||'''</a></b>',
                c.state) State,
       c.state_changed_time,
       c.TOTAL_MESSAGES_CAPTURED,
       c.TOTAL_MESSAGES_ENQUEUED, 
       c.sga_used/1024/1024 sga_used,
       c.sga_allocated/1024/1024 sga_allocated,
       c.bytes_of_redo_mined/1024/1024 bytes_mined,
       c.session_restart_scn
  FROM gV$GOLDENGATE_CAPTURE c, gV$SESSION s
  WHERE c.SID = s.SID AND
        c.SERIAL# = s.SERIAL#  order by c.capture_name;

SELECT capture_name, 
   SYSDATE "Current Time",
   capture_time "Capture Process TS",
   capture_message_number,
   capture_message_create_time ,
   enqueue_time ,
   enqueue_message_number,
   enqueue_message_create_time ,
   available_message_number,
   available_message_create_time,
   session_restart_scn
FROM gV$GOLDENGATE_CAPTURE  order by capture_name;


COLUMN processed_scn HEADING 'Logminer Last|Processed Message' FORMAT 9999999999999999
COLUMN AVAILABLE_MESSAGE_NUMBER HEADING 'Last Message|Written to Redo' FORMAT 9999999999999999
SELECT c.capture_name, l.processed_scn, c.available_message_number
FROM gV$LOGMNR_SESSION l, gv$GOLDENGATE_CAPTURE c
WHERE c.logminer_id = l.session_id order by c.capture_name;

COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A15
COLUMN TOTAL_PREFILTER_DISCARDED HEADING 'Prefilter|Events|Discarded' FORMAT 9999999999999999
COLUMN TOTAL_PREFILTER_KEPT HEADING 'Prefilter|Events|Kept' FORMAT 9999999999999999
COLUMN TOTAL_PREFILTER_EVALUATIONS HEADING 'Prefilter|Evaluations' FORMAT 9999999999999999
COLUMN UNDECIDED HEADING 'Undecided|After|Prefilter' FORMAT 9999999999999999
COLUMN TOTAL_FULL_EVALUATIONS HEADING 'Full|Evaluations' FORMAT 9999999999999999

SELECT CAPTURE_NAME,
       TOTAL_PREFILTER_DISCARDED,
       TOTAL_PREFILTER_KEPT,
       TOTAL_PREFILTER_EVALUATIONS,
       (TOTAL_PREFILTER_EVALUATIONS - 
         (TOTAL_PREFILTER_KEPT + TOTAL_PREFILTER_DISCARDED)) UNDECIDED,
       TOTAL_FULL_EVALUATIONS
  FROM gV$GOLDENGATE_CAPTURE  order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>


column elapsed_capture HEADING 'Elapsed Time|Capture|(centisecs)'
column elapsed_rule HEADING 'Elapsed Time|Rule Evaluation|(centisecs)'
column elapsed_enqueue HEADING 'Elapsed Time|Enqueuing Messages|(centisecs)'
column elapsed_lcr HEADING 'Elapsed Time|LCR Creation|(centisecs)'
column elapsed_redo HEADING 'Elapsed Time|Redo Wait|(centisecs)'
column elapsed_Pause HEADING 'Elapsed Time|Paused|(centisecs)'

SELECT CAPTURE_NAME, ELAPSED_CAPTURE_TIME elapsed_capture,  
       elapsed_rule_time elapsed_rule,        
       ELAPSED_ENQUEUE_TIME 
       elapsed_enqueue, 
       ELAPSED_LCR_TIME elapsed_lcr,
       ELAPSED_REDO_WAIT_TIME elapsed_redo, 
       ELAPSED_PAUSE_TIME elapsed_pause,       
       total_messages_created,    total_messages_enqueued,     total_full_evaluations 
  from gv$GOLDENGATE_capture  order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>



prompt ============================================================================================
prompt
prompt ++ LOGMINER STATISTICS  ++
prompt ++ (pageouts imply logminer spill) ++
COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A32
COLUMN NAME HEADING 'Statistic' FORMAT A32
COLUMN VALUE HEADING 'Value' FORMAT 9999999999999999

select c.capture_name, name, value from gv$goldengate_capture c, gv$logmnr_stats l
 where c.logminer_id = l.session_id 
   and name in ('bytes paged out', 'pageout time (seconds)', 
                'bytes of redo mined', 'bytes checkpointed',
                'checkpoint time (seconds)',
                'resume from low memory', 'distinct txns in queue'
                  )
   order by 1,2;  
prompt
prompt      Logminer Session Stats for logminer chunks available to be CONSUMED (DIFFERENCE)  and Memory 
select sysdate, session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as DIFFERENCE,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size
      FROM v$logmnr_session order by session_name; 
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt ==========================================================================
prompt
prompt ++ <a name="XStream Outbound Server Statistics">  EXTRACT CAPTURE SERVER STATISTICS  </a> ++
prompt
prompt ==========================================================================
prompt 
prompt

col sid HEADING 'Session id'
col serial# HEADING 'Serial#'
col state HEADING 'State'
col spid HEADING 'Spid'
col total_messages_sent HEADING 'Total|Messages|Sent'
col Server_name HEADING 'Outbound|Server|Name' format a22 wrap
col total_messages_sent heading 'Total|Messages|Sent' FORMAT 9999999999999999
col MESSAGE_SEQUENCE Heading 'Message within|Current transaction' 
col message_sequence FORMAT 9999999999999999
col last_sent_message_create_time HEADING 'Last Sent Message|Creation|Time'
col last_sent_message_number HEADING 'Last Sent|Message|SCN'
col last_sent_position HEADING 'Last Sent|Position'
col commitscn  Heading 'Source|Commit|SCN'
col commit_position Heading 'Source|Commit|Position'
col bytes_sent Heading 'Total Bytes|Sent'
col committed_data_only Heading 'Committed|Data|Only'
col startup_time Heading 'Server|Startup|Time'
col elapsed_send_time HEADING 'Elapsed|Send|Time'
col Send_time Heading 'Send Time'

select inst_id,sid,serial#,spid,server_name,startup_time,state,total_messages_sent,
last_sent_message_number,last_sent_message_create_time,send_time, elapsed_send_time,
bytes_sent from gv$xstream_outbound_server where committed_data_only='NO' order by server_name;

prompt 
prompt ++  Outbound Progress Table ++
prompt
col processed_low_position format a40  wrap HEAD 'Processed|Low Position'
col processed_low_time format a40 wrap HEAD 'Processed|Low Position|Time'
col oldest_position format a40 wrap  HEAD 'Oldest|Position'
col source_database format a40 wrap HEAD 'Source DB|GlobalName' 


select server_name, source_database,
    processed_low_position,
    processed_low_time,
    oldest_position
  From dba_xstream_outbound_progress order by server_name;

prompt  ++  APPLY PROGRESS ++
col oldest_message_number HEADING 'Oldest|Message|SCN'
col apply_time HEADING 'Apply|Timestamp'
select ap.* from dba_apply_progress ap, dba_apply a where a.purpose like 'GoldenGate%' and ap.apply_name=a.apply_name and a.purpose like 'Golden%' order by ap.apply_name;
prompt
prompt ++ BUFFERED PUBLISHERS ++
prompt    
prompt
select * from gv$buffered_publishers;




prompt
prompt ++ OPEN GOLDENGATE CAPTURE TRANSACTIONS ++
prompt

prompt +**   Count    **+
select component_name, count(*) "Open Transactions",sum(cumulative_message_count) "Total LCRs" from gv$goldengate_transaction where component_type='CAPTURE' group by component_name;

prompt
prompt ++  OPEN GOLDENGATE CAPTURE TRANSACTION DETAILS  ++
select * from gv$goldengate_transaction where component_type='CAPTURE' order by 
component_name,first_message_number;

prompt

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 





prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \;  

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 



prompt
prompt ++ BUFFERED SUBSCRIBERS ++
prompt    
prompt

select * from gv$buffered_subscribers order by subscriber_name;

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 




prompt
prompt  ++  GoldenGate Message Tracking ++
prompt
col message_number Heading 'Message|Number'
col tracking_label Heading 'Tracking|Label'
col Component_name Heading 'Component|Name'
col Component_type Heading 'Component|Type'
col action Heading 'Action'
col action_details Heading 'Action|Details'
col Message_creation_time Heading 'Message Creation|Time'
col tracking_id Heading 'Tracking|ID'
col source_database_name Heading 'Source|Database'
col object_owner Heading 'Owner|Name'
col object_name Heading 'Object|Name'
col command_type Heading 'Command|Type'
col message_position Heading 'Message|Position'

select * from gv$goldengate_message_tracking order by tracking_label,timestamp;
prompt

prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \;  

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt

prompt
prompt ++   STATISTICS on RULES and RULE SETS  ++
prompt ++
prompt ++   RULE SET STATISTICS  ++
prompt

col name HEADING 'Name'

select * from gv$rule_set;




prompt
prompt ++  RULE STATISTICS  ++
prompt

select * from gv$rule;
prompt
prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt


prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \;  

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 


prompt ================================================================================
prompt ++ <a name="Wait Analysis">Process Wait Analysis</a> ++ 


prompt
set lines 180
set numf 9999999999999
set pages 9999
set verify OFF

COL BUSY FORMAT A4
COL PERCENTAGE FORMAT 999D9
COL event wrapped

-- This variable controls how many minutes in the past to analyze
DEFINE minutes_to_analyze = 30

prompt  Analysis of last &minutes_to_analyze minutes of GoldenGate processes
prompt

PROMPT Note:  When computing the busiest component, be sure to subtract the percentage where BUSY = 'NO'
PROMPT Note:  'no rows selected' means that the process was performing no busy work, or that no such process exists on the system.
PROMPT Note:  A null Wait Event implies running - either on the cpu or waiting for cpu

prompt
prompt ++ LOGMINER READER PROCESSES ++

COL LOGMINER_READER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_READER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_READER_NAME;
SELECT c.capture_name || ' - reader' as logminer_reader_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'reader' and lp.session_id = c.logminer_id
ORDER BY logminer_reader_name, percentage;

prompt
prompt ++ LOGMINER PREPARER PROCESSES ++

COL LOGMINER_PREPARER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_PREPARER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_PREPARER_NAME;
SELECT c.capture_name || ' - preparer' || lp.spid as logminer_preparer_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'preparer' and lp.session_id = c.logminer_id
ORDER BY logminer_preparer_name, percentage;

prompt
prompt ++ LOGMINER BUILDER PROCESSES ++

COL LOGMINER_BUILDER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_BUILDER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_BUILDER_NAME;
SELECT c.capture_name || ' - builder' as logminer_builder_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'builder' and lp.session_id = c.logminer_id
ORDER BY logminer_builder_name, percentage;


prompt
prompt ++ CAPTURE PROCESSES ++

COL CAPTURE_NAME FORMAT A30 WRAP
BREAK ON CAPTURE_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON CAPTURE_NAME;
SELECT c.capture_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       DECODE(ash_capture.event, 
              'Streams capture: waiting for subscribers to catch up', 'NO',
              'Streams capture: resolve low memory condition', 'NO',
              'Streams capture: waiting for archive log', 'NO',
              'YES') busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$goldengate_capture c
WHERE c.SID = ash_capture.SESSION_ID and c.serial# = ash_capture.SESSION_SERIAL#
ORDER BY capture_name, percentage;




prompt
prompt ++  OUTBOUND  SERVER PROCESSES ++

COL SERVER_NAME FORMAT A30 WRAP
BREAK ON SERVER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON SERVER_NAME;
SELECT a.server_name ,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$xstream_outbound_server a
WHERE a.sid = ash.SESSION_ID and a.serial# = ash.SESSION_SERIAL#
ORDER BY server_name, percentage;

prompt
prompt Configuration: <a href="#Database"> Database </a> \; <a href="#Queues in Database"> Queue </a> \;  <a href="#Capture Processes"> Capture </a>\;  <a href="#Outbound Server Processes"> GoldenGate Configuration </a> \; 

prompt Analysis: <a href="#History"> History </a> \;  <a href="#Rules"> Rules </a> \;  <a href="#Notification"> Notifications </a> \; <a href="#Configuration checks"> Configuration </a>\;  <a href="#Performance Checks"> Performance </a>\;  <a href="#Wait Analysis">  Wait Analysis </a>\; 



prompt Statistics: <a href="#Statistics"> OGG Integrated Capture Statistics </a> \; <a href="#Queue Statistics"> Queue </a> \; <a href="#Capture Statistics"> Capture </a>\; 

prompt
set heading off
select 'Oracle GoldenGate Integrated Extract/Replicat Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on

set timing off
set markup html off
clear col
clear break
spool
prompt   Turning Spool OFF!!!
spool off

exit;

@?/rdbms/admin/sqlsessend.sql
