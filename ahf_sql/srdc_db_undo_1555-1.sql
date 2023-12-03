Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_1555-1.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_undo_1555-1.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_undo_1555-1.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_1555-1.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    11/02/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_db_undo_1555-1.sql
REM collect collect Undo parameters and Segments details.
define SRDCNAME='DB_Undo_1555-1'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name : ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine : ' , host_name from v$instance
union all
select 'Version : ',version from v$instance
union all
select 'DBName : ',name from v$database
union all
select 'Instance : ',instance_name from v$instance
/
set echo on

--***********************Undo Extents breakdown information***********************

select status, count(*) cnt from dba_rollback_segs
group by status
/

col segment_name format a30 head "Segment Name"
 col "ACT BYTES" format 999,999,999,999 head "Active Bytes"
 col "UNEXP BYTES" format 999,999,999,999 head "Unexpired Bytes"
 col "EXP BYTES" format 999,999,999,999 head "Expired Bytes"
 
 select segment_name, nvl(sum(act),0) "ACT BYTES",
    nvl(sum(unexp),0) "UNEXP BYTES",
    nvl(sum(exp),0) "EXP BYTES"
    from (select segment_name, nvl(sum(bytes),0) act,00 unexp, 00 exp
    from dba_undo_extents where status='ACTIVE' group by segment_name
    union
    select segment_name, 00 act, nvl(sum(bytes),0) unexp, 00 exp
    from dba_undo_extents where status='UNEXPIRED' group by segment_name
    union
   select segment_name, 00 act, 00 unexp, nvl(sum(bytes),0) exp
   from dba_undo_extents where status='EXPIRED' group by segment_name)
   group by segment_name
   order by 1
/

select distinct status st, count(*) "HOW MANY", sum(bytes) "SIZE"
from dba_undo_extents
group by status
/

select SEGMENT_NAME, TABLESPACE_NAME, EXTENT_ID, 
FILE_ID, BLOCK_ID, BYTES, BLOCKS, STATUS
from dba_undo_extents
order by 1,3,4,5
/



---***********************Undo Extents Contention breakdown***********************
-- Take out column TUNED_UNDORETENTION if customer 
-- prior to 10.2.x
--
-- The time frame can be adjusted with this query
-- By default using around 4 hour window of time
--
-- Ex.
-- Using sysdate-.04 looking at the last hour
-- Using sysdate-.1 looking at the last 4 hours
-- Using sysdate-.32 looking at the last 8 hours
-- Using sysdate-1 looking at the last 24 hours


select inst_id, to_char(begin_time,'MM/DD/YYYY HH24:MI') begin_time, 
UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, MAXQUERYLEN,
TUNED_UNDORETENTION, TUNED_UNDORETENTION/60/60 hours
from gv$undostat
where begin_time between (sysdate-.1) 
and sysdate
order by inst_id, begin_time
/

set echo off
set sqlprompt "SQL> " term on
set verify on
spool off
set markup html off spool off
set echo on

@?/rdbms/admin/sqlsessend.sql
 
