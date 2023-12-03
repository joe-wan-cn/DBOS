Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_audit.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_audit.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_audit.sql - Query database audit information
Rem
Rem    DESCRIPTION
Rem	Query database audit information

Rem    NOTES
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_audit.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/28/18 - Called by srdc_dbaudit.xml
Rem    xiaodowu    03/28/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
col user_name for a12 heading "User name"
col proxy_name for a12 heading "Proxy name"
col privilege for a30 heading "Privilege"
col user_name for a12 heading "User name" 
col audit_option format a30 heading "Audit Option"
col timest format a13 
col userid format a8 trunc 
col obn format a10 trunc 
col name format a13 trunc 
col sessionid format 99999 
col entryid format 999 
col owner format a10 
col object_name format a10 
col object_type format a6 
col priv_used format a15 trunc 
break on user_name
set pages 1000

col name for a20 
col display_value for a20

spool srdc_audit.log

prompt
prompt Auditing parameters

SELECT NAME ,DISPLAY_VALUE 
FROM V$PARAMETER 
WHERE UPPER(NAME) LIKE UPPER('%audit%') 
ORDER BY NAME,ROWNUM
/

prompt 
prompt System auditing options across the system and by user

select * from sys.dba_stmt_audit_opts
order by user_name, proxy_name, audit_option 
/

prompt
prompt System auditing options on all objects

select owner, object_name, object_type, 
 alt,aud,com,del,gra,ind,ins,loc,ren,sel,upd,ref,exe 
from sys.dba_obj_audit_opts 
where 
 alt !='-/-' or aud !='-/-' or com !='-/-' 
or del !='-/-' or gra !='-/-' or ind !='-/-' 
or ins !='-/-' or loc !='-/-' or ren !='-/-' 
or sel !='-/-' or upd !='-/-' or ref !='-/-' or exe !='-/-' 
/ 

prompt
prompt Audit trail for the last day
  
col acname format a12 heading "Action name" 
select username userid, to_char(timestamp,'dd-mon hh24mi') timest , 
 action_name acname, priv_used, obj_name obn, ses_actions 
from sys.dba_audit_trail
where timestamp>sysdate-1
order by timestamp 
/ 

prompt
prompt System privileges audited across the system and by user

select * from dba_priv_audit_opts
order by user_name, proxy_name, privilege
/

spool off
@?/rdbms/admin/sqlsessend.sql
