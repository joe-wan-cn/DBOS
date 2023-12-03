Rem srdc_invobject.sql
Rem
Rem Copyright (c) 2006, 2021, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_invobject.sql- script to collect  diagnostic details related to a prticular schema or object
Rem
Rem    NOTES
Rem      * This script collects the diagnostic data related to a
Rem		   particular invalid object in a schema. You will have to input the
Rem		   object name and the scehma name.  
Rem		 * The script creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    slabraha   12/14/18 - updated the header
Rem    slabraha   11/06/18 - updated the script
Rem    slabraha   03/05/18 - created the script
Rem
Rem
Rem
Rem
@@?/rdbms/admin/sqlsessstart.sql
CLEAR BUFFER
Rem   
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
define SRDCNAME='DB_INVALID_OBJECT'
define Schema_name='&1'
define Obj_name='&2'
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS')||'_'||upper('&&Schema_name')||'_'||upper('&&Obj_name') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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
set echo on
set serveroutput on

alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
SELECT 'SRDC_INVALID_OBJECT' "CHECK_NAME",sysdate from dual
/
SELECT 'Instance_status' "CHECK_NAME",logins,status from v$instance
/
SELECT 'Database_status' "CHECK_NAME",open_mode from v$database
/
select 'Selection' "CHECK_NAME",upper('&&Schema_name')  Owner ,upper('&&Obj_name') Object  from dual
/
SELECT 'Object_Status' "CHECK_NAME",owner,object_name,object_id,object_type,status from dba_objects 
where owner = upper('&&Schema_name') and object_name = upper('&&Obj_name')
/
select * from dba_objects where owner= upper('&&Schema_name') and object_name = upper('&&Obj_name')
/
select * from dba_editions order by edition_name
/

select 'All_Editions' "CHECK_NAME",o.name,e.obj#, p_obj# from edition$ e, obj$ o where  e.obj# = o.obj# order by e.obj#
/
select 'Default_Edition' "CHECK_NAME",property_value from database_properties where property_name='DEFAULT_EDITION'
/
select 'User_Detail' "CHECK_NAME",user#, name , type# from sys.user$ where name = upper('&&Schema_name') order by user#
/
select 'Errors' "CHECK_NAME",owner,name,text,message_number from dba_errors where owner= upper('&&Schema_name') and name = upper('&&Obj_name')
/
 select 'Obj_and_edition' "CHECK_NAME",OWNER,OBJECT_NAME,OBJECT_ID,DATA_OBJECT_ID,OBJECT_TYPE,CREATED,LAST_DDL_TIME,STATUS,EDITION_NAME,EDITIONABLE from dba_objects_ae
 where owner= upper('&&Schema_name') and object_name = upper('&&Obj_name')
/
select * from dba_objects_ae where owner= upper('&&Schema_name') and object_name = upper('&&Obj_name')
/

-- dependencies

select 'Dependencies' "CHECK_NAME",d.spare3 d_base_own, d.owner# , d.obj# , d.name,d.type# , d.status ,p.spare3 p_base_own, p.owner# , p.obj# , p.name ,p.status 
from sys.obj$ d, sys.dependency$ dep, sys.obj$ p where d.obj# = dep.d_obj# and p.obj# = dep.p_obj#
and (p.name=upper('&&Obj_name') or d.name=upper('&&Obj_name'))
and p.spare3 = (select user# from user$ where name = upper('&&Schema_name')) order by p.spare3, p.owner#, d.owner#
/

Select 'Dependent_Objects' "CHECK_NAME",referenced_owner, referenced_name,referenced_type,owner,name,type from dba_dependencies 
where name = upper('&&Obj_name')  and owner = upper('&&Schema_name')
/

Rem===========================================================================================================================================
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem===========================================================================================================================================
exit
@?/rdbms/admin/sqlsessend.sql