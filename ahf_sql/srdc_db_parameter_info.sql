Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_parameter_info.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_parameter_info.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_parameter_info.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_parameter_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - Sql to collect DB Parameter details
Rem    bburton     09/22/17 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
spool AWR_Parameter_Settings.txt
show parameter control_management_pack_access
show parameter statistics_level
show parameter compatible
spool off
@?/rdbms/admin/sqlsessend.sql
 
