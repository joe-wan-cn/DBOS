Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_session_stats_before_test.sql /main/1 2019/03/22 10:15:41 xiaodowu Exp $
Rem
Rem srdc_session_stats_before_test.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_session_stats_before_test.sql 
Rem
Rem    DESCRIPTION
Rem      Collect session stats before test
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_session_stats_before_test.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/14/19 - Called by exsmartscan SRDC collection
Rem    xiaodowu    03/14/19 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
        set pagesize 200 verify off term off entmap off echo off
			define SRDCNAME='SESSION_STATS_before_test'
			set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
			COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select '/var/tmp/SRDC_'||upper('&&SRDCNAME')||'_SID_'||(select distinct sid from v$mystat)||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
			to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME2 from v$instance;
			SET ECHO ON
			SET PAGESIZE 200
			ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
			spool &&SRDCSPOOLNAME..txt
			SET ECHO OFF

			SET TERM OFF

	select name,value from v$sesstat a, v$statname b where
         (a.STATISTIC# = b.STATISTIC#) and
         (a.sid) = (select distinct sid from v$mystat) and 
         (name in (
                   'cell physical IO interconnect bytes returned by smart scan',
                   'cell physical IO bytes sent directly to DB node to balance CPU',
                   'physical read requests',
                   'physical read requests optimized',
                   'cell physical IO bytes saved by storage index',
                   'cell physical IO bytes saved by columnar cache',
                   'cell physical IO bytes eligible for predicate offload',
                   'cell num smart IO sessions using passthru mode due to cellsrv',
                   'cell num smart IO sessions using passthru mode due to user',
                   'cell smart IO session cache lookups',
                   'cell smart IO session cache hits',
                   'cell smart IO session cache soft misses',
                   'cell smart IO session cache hard misses',
                   'cell smart IO session cache hwm',
                   'cell flash cache read hits',
                   'cell CUs sent uncompressed',
                   'cell CUs sent compressed',
                   'cell CUs sent head piece',
                   'cell CUs processed for uncompressed',
                   'cell CUs processed for compressed',
                   'db block gets',
                   'db block gets from cache',
                   'db block gets from cache (fastpath)',
                   'db block gets direct',
                   'cell blocks processed by cache layer',
                   'cell blocks processed by txn layer',
                   'cell blocks processed by data layer',
                   'cell blocks processed by index layer',
                   'filtered blocks failed block check',
                   'chained rows skipped by cell',
                   'chained rows processed by cell',
                   'chained rows rejected by cell',
                   'sage send block by cell'
                  )) order by name;	

	/

	select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual;

	spool off
	set term on
	set echo off
	set verify on
/
/

@?/rdbms/admin/sqlsessend.sql
