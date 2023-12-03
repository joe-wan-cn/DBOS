Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_statsadvisor_report.sql /main/1 2019/08/02 06:20:12 xiaodowu Exp $
Rem
Rem srdc_statsadvisor_report.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_statsadvisor_report.sql
Rem
Rem    DESCRIPTION
Rem      To generate Statstics Advisor Report
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_statsadvisor_report.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    07/26/19 - Called by dbperf SRDC collection
Rem    xiaodowu    07/26/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='Statistics_Advisor_Report'
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select '&&SRDCNAME'||'_'||instance_name||'_'||
       to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..txt


SET LINESIZE 3000
SET LONG 500000
SET PAGESIZE 0
SET LONGCHUNKSIZE 100000

SELECT DBMS_STATS.REPORT_ADVISOR_TASK('AUTO_STATS_ADVISOR_TASK',NULL,'TEXT','ALL','ALL') AS REPORT FROM DUAL;
spool Off
@?/rdbms/admin/sqlsessend.sql
 
