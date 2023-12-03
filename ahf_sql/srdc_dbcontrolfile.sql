Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_dbcontrolfile.sql /main/1 2021/07/26 08:55:41 bvongray Exp $
Rem
Rem srdc_dbcontrolfile.sql
Rem 
Rem Copyright (c) 2019, 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_dbcontrolfile.sql - script to collect controlfile related diagnostic data 
Rem
Rem    NOTES
Rem      * This script collects the data related to the controlfile issues 
Rem		   including the configuration, parameters , statistics etc
Rem		   and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_dbcontrolfile.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/22/21 - Created
Rem
Rem


@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_CONTROLFILE'
set long 2000000000
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME

set echo off
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '      ||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine:         '||host_name from v$instance
union all
select '| Version:         '||version from v$instance
union all
select '| DBName:          '||name from v$database
union all
select '| Instance:        '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual 
/

set echo off
prompt
prompt ============================================================================================
prompt                     ++ Control File Details ++
prompt ============================================================================================
prompt

prompt **** v$controlfile ****
set echo on
select * from v$controlfile;

set echo off
prompt **** v$controlfile_record_section ****

set echo on
select * from v$controlfile_record_section order by type;

set echo off
prompt **** v$database ****

set echo on
select * from v$database;

set echo off
prompt
prompt ============================================================================================
prompt            +++++++++++++++++++++End of SRDC Data Collection+++++++++++++ 
prompt ============================================================================================
prompt
spool off

set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT======================================================================================================================================
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem======================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
exit;



 
