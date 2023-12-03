Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_cell_stats_before_test.sql /main/1 2019/03/22 10:15:41 xiaodowu Exp $
Rem
Rem srdc_cell_stats_before_test.sql
Rem
Rem Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_cell_stats_before_test.sql
Rem
Rem    DESCRIPTION
Rem      Collect cell stats before test
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_cell_stats_before_test.sql
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
			define SRDCNAME='CELL_STATS_before_test'
			set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
			COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
			select '/var/tmp/SRDC_'||upper('&&SRDCNAME')||'_SID_'||(select distinct sid from v$mystat)||'_'||upper(instance_name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
			SET ECHO ON
			SET PAGESIZE 200
			ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
			spool &&SRDCSPOOLNAME..txt
                        SET ECHO OFF
                        SET TERM OFF

	set long 50000000
	set pagesize 10000
	select cell_name, statistics_type, xmltype(statistics_value).getclobval(2,2) from v$cell_state where statistics_type='PREDIO';
	select 'Time : ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual;

	spool off
	set term on
	set echo off
	set verify on
/
@?/rdbms/admin/sqlsessend.sql
 
