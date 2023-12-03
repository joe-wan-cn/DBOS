Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_logging_info.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_logging_info.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_logging_info.sql
Rem
Rem    DESCRIPTION
Rem      Query for logging information.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_logging_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/29/18 - Called by srdc_ora1578.xml
Rem    xiaodowu    03/29/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool logging.log
set echo on
set line 150
col UNRECOVERABLE_TIME format 999999999999999
col FIRST_NONLOGGED_SCN format 999999999999999
col RESETLOGS_CHANGE# format 999999999999999
 
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS';

select NAME, FORCE_LOGGING, CONTROLFILE_TYPE, DATABASE_ROLE, RESETLOGS_CHANGE#, RESETLOGS_TIME, STANDBY_BECAME_PRIMARY_SCN
from V$DATABASE;

select FILE#, UNRECOVERABLE_CHANGE#, UNRECOVERABLE_TIME, FIRST_NONLOGGED_SCN, FIRST_NONLOGGED_TIME
from   V$DATAFILE
where  UNRECOVERABLE_TIME is not NULL   
   OR  FIRST_NONLOGGED_TIME is not NULL;
   
   
spool off

@?/rdbms/admin/sqlsessend.sql
