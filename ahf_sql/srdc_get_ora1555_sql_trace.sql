Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_ora1555_sql_trace.sql /main/2 2021/03/03 20:02:13 bburton Exp $
Rem
Rem srdc_get_ora1555_sql_trace.sql
Rem
Rem Copyright (c) 2019, 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_get_ora1555_sql_trace.sql
Rem
Rem    DESCRIPTION
Rem      Called by SRDC collection ora1555
Rem
Rem    NOTES
Rem      None 
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_ora1555_sql_trace.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    Andy		   02/18/21 - Added reproduce sql
Rem    xiaodowu    02/12/19 - Called by SRDC collection ora1555
Rem    xiaodowu    02/12/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool SQL_EXEC.OUT
set echo on
set timing on
DEFINE SQLFILE = &1
alter session set events '1555 trace name context forever,level 12';
alter session set events '10442 trace name context forever,level 10';
alter session set statistics_level=all;
alter session set max_dump_file_size = unlimited;
alter session set timed_statistics = true;
alter session set tracefile_identifier='ORA-1555';
@&&SQLFILE
ALTER SESSION SET EVENTS '1555 trace name errorstack off';
ALTER SESSION SET EVENTS '10442 trace name context off';
set echo off
@?/rdbms/admin/sqlsessend.sql
exit; 
