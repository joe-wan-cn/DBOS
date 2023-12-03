Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_statretention_info.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_statretention_info.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_statretention_info.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_statretention_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - Gather AWR Parameter settings
Rem    bburton     09/22/17 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
spool Statistic_Retention.txt
set serveroutput on

    DECLARE
      v_stats_retn  NUMBER;
      v_stats_date  DATE;
    BEGIN
      v_stats_retn := DBMS_STATS.GET_STATS_HISTORY_RETENTION;
      DBMS_OUTPUT.PUT_LINE('The retention setting is ' || v_stats_retn || '.');
      v_stats_date := DBMS_STATS.GET_STATS_HISTORY_AVAILABILITY;
      DBMS_OUTPUT.PUT_LINE('The earliest restore date is ' || v_stats_date || '.');
    END;
    / 
spool off
@?/rdbms/admin/sqlsessend.sql
 
