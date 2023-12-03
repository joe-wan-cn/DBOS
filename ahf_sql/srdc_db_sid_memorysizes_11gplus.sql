Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_sid_memorysizes_11gplus.sql /main/1 2017/04/20 22:18:55 bburton Exp $
Rem
Rem srdc_db_sid_memorysizes_11gplus.sql
Rem
Rem Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_sid_memorysizes_11gplus.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_sid_memorysizes_11gplus.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     04/11/17 - Gathers memory information for ora-4030 errorsDB
Rem                           versions 11.1 and above
Rem    bburton     04/11/17 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
SET PAGESIZE 900
col 'Total SGA (Fixed+Variable)' format 99999999999999999999999
col 'Total PGA Allocated (Mb)' format 99999999999999999999999
col component format a40
col current_size format 99999999999999999999999
COLUMN alme HEADING "Allocated MB" FORMAT 99999D9
COLUMN usme HEADING "Used MB" FORMAT 99999D9
COLUMN frme HEADING "Freeable MB" FORMAT 99999D9
COLUMN mame HEADING "Max MB" FORMAT 99999D9
COLUMN username FORMAT a15
COLUMN program FORMAT a22
COLUMN sid FORMAT a5
COLUMN spid FORMAT a8
SET LINESIZE 300
spool DBMEMINFO_$ORACLE_SID.TXT
/* Database Identification */
select NAME, PLATFORM_ID, DATABASE_ROLE from v$database;
select * from V$version where banner like 'Oracle Database%';
select INSTANCE_NAME, to_char(STARTUP_TIME,'DD/MM/YYYY HH24:MI:SS') "STARTUP_TIME" from v$instance;
/* AMM MEMORY settings */
show parameter MEMORY%TARGET
/* Current MEMORY settings */
select component, current_size from V$MEMORY_DYNAMIC_COMPONENTS;
/* SGA */
select sum(value) "Total SGA (Fixed+Variable)" from v$sga;
/* PGA */
select sum(PGA_ALLOC_MEM)/1024/1024 "Total PGA Allocated (Mb)" from v$process p, v$session s where p.addr = s.paddr;
/* PGA Memory per process */
SELECT s.username, SUBSTR(s.sid,1,5) sid, p.spid, logon_time,
SUBSTR(s.program,1,22) program , s.process pid_remote,
s.status,
ROUND(pga_used_mem/1024/1024) usme,
ROUND(pga_alloc_mem/1024/1024) alme,
ROUND(pga_freeable_mem/1024/1024) frme,
ROUND(pga_max_mem/1024/1024) mame
FROM v$session s,v$process p
WHERE p.addr=s.paddr
ORDER BY pga_max_mem,logon_time;
SPOOL OFF
@?/rdbms/admin/sqlsessend.sql
