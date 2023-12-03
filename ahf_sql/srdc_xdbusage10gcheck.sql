Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_xdbusage10gcheck.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_xbdusage10gcheck.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_xbdusage10gcheck.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_xbdusage10gcheck.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     07/11/17 - Sql to collect information about XBD usage for
Rem                           diagnosing issues
Rem    bburton     07/11/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_xdbusage10gcheck.sql - collect Oracle XDB Usage information 
define SRDCNAME='XDB_USAGE_CHECK_10G'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
       to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on 
REM
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||
          to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine: '||host_name from v$instance
union all
select '| Version: '||version from v$instance
union all
select '| DBName: '||name from v$database
union all
select '| Instance: '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set HEADING on MARKUP html preformat off 
REM === -- end of standard header -- ===
set serveroutput on size 100000
set pagesize 0

declare
--define cursors
--check for version
cursor c_ver is select version from v$instance;
--check for invalids owned by XDB
cursor c_inval is select * from dba_objects
where status='INVALID' and OWNER in ('SYS','XDB');
-- Check status of other database features
cursor c_feat is select comp_name,status,version from dba_registry;
--check for xml type tables
cursor c_xml_tabs is select owner,storage_type,count(*) "TOTAL"
from dba_xml_tables group by owner,storage_type;
--check for xml type colmns
cursor c_xml_tab_cols is select owner,storage_type,count(*) "TOTAL"
from dba_xml_tab_cols group by owner,storage_type;
--check for xml type views
cursor c_xml_vw is select owner,count(*) "TOTAL"
from dba_xml_views group by owner;
--check for API's bbuilt with XML API's
cursor c_api is select owner,name,type from dba_dependencies
where referenced_name in (select object_name from dba_objects
where object_name like 'DBMS_XML%' or object_name like 'DBMS_XSL%')
and TYPE !='SYNONYM' and owner !='SYS';
--check for registered Schemas
cursor c_xml_schemas is select owner,count(*) "TOTAL"
from dba_xml_schemas group by owner;
--check for user defined resources in the repository
cursor c_res is select distinct (a.username) "USER",count (r.xmldata) "TOTAL"
from dba_users a, xdb.xdb$resource r
where sys_op_rawtonum
 (extractvalue (value(r),'/Resource/OwnerID/text()')) =a.USER_ID
group by a.username;
-- check xdbconfig.xml values
cursor c_config is select value(x).GETROOTELEMENT() NODENAME,
  extractValue(value(x),'/*') NODEVALUE
from table
 (xmlsequence(extract(xdburitype('/xdbconfig.xml').getXML(),'//*[text()]'))) x;
--define variables for fetching data from cursors
v_ver c_ver%ROWTYPE;
v_inval c_inval%ROWTYPE;
v_feat  c_feat%ROWTYPE;
v_xml_tabs c_xml_tabs%ROWTYPE;
v_xml_tab_cols  c_xml_tab_cols%ROWTYPE;
v_xml_vw c_xml_vw%rowtype;
v_api c_api%rowtype;
v_xml_schemas c_xml_schemas%rowtype;
v_res c_res%ROWTYPE;
v_config c_config%rowtype;
-- Static variables
v_errcode       NUMBER := 0;
v_errmsg        varchar2(50) := ' ';
--stylesheet for xdbconfig.xml reading
v_style clob :='';
begin open c_ver;
fetch c_ver into v_ver;
--check minimum XDB requirements
if dbms_registry.version('XDB') in ('9.2.0.1.0','9.2.0.2.0') then
DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!  UNSUPPORTED VERSION  !!!!!!!!!!!!!');
DBMS_OUTPUT.PUT_LINE('Minimun version is 9.2.0.3.0. actual version is: '
||dbms_registry.version('XDB'));
end if;
if v_ver.version like '10.%' then DBMS_OUTPUT.PUT_LINE(' Doing  '
||v_ver.version||' checks');
-- Print XDB status
DBMS_OUTPUT.PUT_LINE('#############  Status/Version  #############');
DBMS_OUTPUT.PUT_LINE('XDB Status is: '||dbms_registry.status('XDB')
||' at version '||dbms_registry.version('XDB'));
end if;
if v_ver.version != dbms_registry.version('XDB') then
DBMS_OUTPUT.PUT_LINE('Database is at version '||v_ver.version
||' XDB is at version '||dbms_registry.version('XDB'));
end if;
--Check Status if invalid gather invalid objects list and check for usage
--if valid simply check for usage
if dbms_registry.status('XDB') != 'VALID' then
DBMS_OUTPUT.PUT_LINE('#############  Invalid Objects  #############');
open c_inval;
loop
fetch c_inval into v_inval;
  DBMS_OUTPUT.PUT_LINE('Type: '||v_inval.object_type
                               ||' '
                               ||v_inval.owner
                               ||'.'
                               ||v_inval.object_name);
  exit when c_inval%NOTFOUND;
end loop;
close c_inval;
end if;
-- Check XDBCONFIG.XML paramareters
DBMS_OUTPUT.PUT_LINE('#############  OTHER DATABASE FEATURES  #############');
open c_feat;
loop
fetch c_feat into v_feat;
exit when c_feat%NOTFOUND;
if c_feat%rowcount >0 then
DBMS_OUTPUT.PUT_LINE(v_feat.comp_name||' is '
                                     ||v_feat.status
                                     ||' at version '
                                     ||v_feat.version);
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_feat;
-- Check XDBCONFIG.XML paramareters
DBMS_OUTPUT.PUT_LINE('#############  XDBCONFIG INFORMATION #############');
open c_config;
loop
fetch c_config into v_config;
exit when c_config%NOTFOUND;
if c_config%rowcount >0 then
DBMS_OUTPUT.PUT_LINE(v_config.NODENAME||'= = = '||v_config.NODEVALUE);
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_config;
-- Check if they have any xmltype tables or columns
-- and if they are schema based, clob or binary
DBMS_OUTPUT.PUT_LINE('#############  XMLTYPE Tables #############');
open c_xml_tabs;
loop
fetch c_xml_tabs into v_xml_tabs;
exit when c_xml_tabs%NOTFOUND;
DBMS_OUTPUT.PUT_LINE(v_xml_tabs.owner||' has '
                                     ||v_xml_tabs.TOTAL
                                     ||' XMLTYPE TABLES stored as '
                                     ||v_xml_tabs.storage_type);
end loop;
close c_xml_tabs;
DBMS_OUTPUT.PUT_LINE('#############  XMLTYPE Columns #############');
open c_xml_tab_cols;
loop
fetch c_xml_tab_cols into v_xml_tab_cols;
exit when c_xml_tab_cols%NOTFOUND;
if c_xml_tab_cols%rowcount > 0 then
DBMS_OUTPUT.PUT_LINE(v_xml_tab_cols.owner||' has '||v_xml_tab_cols.TOTAL
                                         ||' XMLTYPE Columns stored as '
                                         ||v_xml_tab_cols.storage_type);
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_xml_tab_cols;
DBMS_OUTPUT.PUT_LINE('#############  XMLTYPE Views #############');
open c_xml_vw;
loop
fetch c_xml_vw into v_xml_vw;
exit when c_xml_vw%NOTFOUND;
if c_xml_vw%rowcount > 0 then
DBMS_OUTPUT.PUT_LINE(v_xml_vw.owner||' has '
                                   ||v_xml_vw.TOTAL
                                   ||' XMLTYPE Views');
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_xml_vw;
DBMS_OUTPUT.PUT_LINE('############  Items built with XML API''s  ############');
open c_api;
loop
fetch c_api into v_api;
exit when c_api%NOTFOUND;
if c_api%rowcount > 0 then
DBMS_OUTPUT.PUT_LINE(v_api.type||' '||v_api.owner||'.'||v_api.name);
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_api;
DBMS_OUTPUT.PUT_LINE('#############  XML SCHEMAS #############');
open c_xml_schemas;
loop
fetch c_xml_schemas into v_xml_schemas;
exit when c_xml_schemas%NOTFOUND;
if c_xml_schemas%rowcount >0 then
DBMS_OUTPUT.PUT_LINE(v_xml_schemas.owner||' has '
||v_xml_schemas.TOTAL||' registered.');
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_xml_schemas;
-- Check for repository resources
DBMS_OUTPUT.PUT_LINE('#############  Repository Resources #############');
open c_res;
loop
fetch c_res into v_res;
exit when c_res%NOTFOUND;
if c_res%rowcount >0 then
DBMS_OUTPUT.PUT_LINE(v_res.USER||' has '||v_res.TOTAL||' resources.');
else DBMS_OUTPUT.PUT_LINE('No Data Found');
end if;
end loop;
close c_res;
close c_ver;
EXCEPTION
     WHEN no_data_found THEN
       DBMS_OUTPUT.PUT_LINE('No Data Found');
     WHEN others THEN
       v_errcode := sqlcode;
       v_errmsg := SUBSTR(sqlerrm, 1, 50);
       DBMS_OUTPUT.PUT_LINE('ERROR: '||v_errcode||': ' || v_errmsg);
end;
/
spool off
exit;
@?/rdbms/admin/sqlsessend.sql
 
