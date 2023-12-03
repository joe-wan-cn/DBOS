Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_aq_client_register_info.sql /main/1 2019/07/12 08:10:34 xiaodowu Exp $
Rem
Rem srdc_aq_client_register_info.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_aq_client_register_info.sql 
Rem
Rem    DESCRIPTION
Rem      None
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_aq_client_register_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    07/05/19 - Called by dbaqnotify SRDC collection
Rem    xiaodowu    07/05/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
                        define SRDCNAME='NOTIFICATION_TRACE'
                        SET MARKUP HTML ON PREFORMAT ON
                        set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
                        COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
                        select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
                        set TERMOUT on MARKUP html preformat on
                        SET ECHO ON
                        SET PAGESIZE 200
                        ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
                        set HEADING on MARKUP html preformat off
                        set sqlprompt "#"
                        spool &&SRDCSPOOLNAME..htm

set echo on
set markup html on spool on ENTMAP OFF
alter session set max_dump_file_size=unlimited;
alter session set tracefile_identifier='NOTIFICATION_TRACE';
alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';
select * from dba_jobs;
select * from SYS.REG$ ;
select * from SYS.LOC$;
select * from dba_jobs_running;
select * from dba_ddl_locks where name='DBMS_AQ';
select count(*), msg_state, queue from aq$aq_srvntfn_table_1 group by msg_state, queue;
select event,count(*) from v$session where status = 'ACTIVE' group by event order by 2;
select subscription_name from sys.reg$ where location_name not in (select location_name from sys.loc$);
select owner,object_type, object_name from dba_objects where status ='INVALID' and owner IN ('SYS','SYSTEM','PUBLIC');
select a.event, b.program, a.state from v$session_wait a, v$session b where a.sid = b.sid and a.event like '%EMON%' order by 2;
spool off
set markup html off spool off ENTMAP on

@?/rdbms/admin/sqlsessend.sql
 
