Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_getevents.sql /main/1 2021/06/01 13:25:12 bvongray Exp $
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem    NAME
Rem      srdc_getevents.sql - script to collect  diagnostic details required for troubleshooting 
Rem                         database startup related issues.
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to single instance 
Rem		   startup , for both multitenant and non-multitenant architecture.
Rem		 * The checks here might not be enough for troubleshooting issues on RAC or dataguard. 
REM			Check the respective SRDC document for the complete set of data.
Rem		 * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS and is required only if the instance is in mount or open stage.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem       02/19/19  - created the script
Rem
Rem
Rem
Rem
Rem   
@@?/rdbms/admin/sqlsessstart.sql

spool events.txt
oradebug setmypid
oradebug eventdump system;
oradebug eventdump session;
oradebug eventdump process;
spool off;
Rem======================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
exit;
