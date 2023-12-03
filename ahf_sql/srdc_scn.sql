Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_scn.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_scn.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_scn.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_scn.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    02/27/18 - XbranchMerge xiaodowu_addxmls from
Rem                           st_tfa_12.2.1.3.1
Rem    xiaodowu    01/26/18 - Use new script provided by Susan on 1/10/2018
Rem    recornej    12/05/17 - Adjustments to the sql
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    11/27/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
Rem srdc_scn_test.sql
Rem
Rem Copyright (c) 2006, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_scn.sql- script to collect SCN related diagnostic data
Rem
Rem    NOTES
Rem      * This script collects the data related to the high SCN issues
Rem		   including the configuration parameters and historic SCN rates
Rem		   and creates a spool output. Upload it to the Service Request
Rem      * This script contains some checks which might not be relevant for
Rem        all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem
Rem
Rem
Rem    rsnowden   01/10/18 - modified the script as per AT requirements
Rem    slabraha   01/02/18 - modified the script to include checks for AT
Rem    slabraha   11/22/17 - modified the script to include checks from AWR
Rem    slabraha   11/15/17 - created the script
Rem
Rem
Rem
Rem
define SRDCNAME='DB_SCN'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_TEST_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name' "DIAGNOSTIC_NAME", '&&SRDCNAME' "REPORT_INFO" from dual
union all
select 'Time' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine' , host_name from v$instance
union all
select 'Version',version from v$instance
union all
select 'DBName',name from v$database
union all
select 'Instance',instance_name from v$instance
/
set echo on
set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'
/
--===========================================================================================================================================
--                                Checking the current SCN, database version and the run time
--===========================================================================================================================================
select sysdate from dual
/
select * from v$version
/
COLUMN current_scn FORMAT 999,999,999,999,999,999,999;
SELECT 'Current_SCN' "CHECK_NAME" ,current_scn FROM v$database
/

--===========================================================================================================================================
--                                Checking the parameters and flags (11.2.0.2 and 11.2.0.3 only) related to SCN
--===========================================================================================================================================
SELECT 'Parameters' "CHECK_NAME" ,KSPPINM PARAMETER_NAME, KSPFTCTXVL PARAMETER_VALUE FROM   
X$KSPPI X, X$KSPPCV2 Y WHERE  (X.INDX+1) = KSPFTCTXPN AND KSPPINM LIKE '%_scn_%' order by 1
/
select '11202_11203_scn_rate' "CHECK_NAME" ,decode(bitand(DI2FLAG,65536),65536,'Y','N') using16  from x$kccdi2
/
set echo off
--===========================================================================================================================================
--                                The following check is relevant from 11.2.0.3.15 and above only
--===========================================================================================================================================
PROMPT
PROMPT
PROMPT =============================================================
PROMPT "Compatibility Output - only for 11.2.0.3.9 and above"
PROMPT =============================================================
PROMPT
set markup html off
declare
rsl number;
headroom_in_scn number;
headroom_in_sec number;
cur_scn_compat number;
max_scn_compat number;
begin
dbms_scn.GetCurrentSCNParams(rsl,headroom_in_scn,headroom_in_sec,cur_scn_compat,max_scn_compat);
dbms_output.put_line('<table border=''1'' width=''90%'' align=''center'' summary=''Curr SCN params''>');
dbms_output.put_line('<tr>');
dbms_output.put_line('<th>');
dbms_output.put_line('CHECK_NAME');
dbms_output.put_line('</th>');
dbms_output.put_line('<th>');
dbms_output.put_line('RSL');
dbms_output.put_line('</th>');
dbms_output.put_line('<th>');
dbms_output.put_line('HEADROOM IN SCN');
dbms_output.put_line('</th>');
dbms_output.put_line('<th>');
dbms_output.put_line('HEADROOM IN SEC');
dbms_output.put_line('<th>');
dbms_output.put_line('CURR SCN');
dbms_output.put_line('</th>');
dbms_output.put_line('<th>');
dbms_output.put_line('MAX SCN');
dbms_output.put_line('</th>');
dbms_output.put_line('</tr>');
dbms_output.put_line('<tr>');
dbms_output.put_line('<td>');
dbms_output.put_line('CURR_SCN_PARAMS');
dbms_output.put_line('</td>');
dbms_output.put_line('<td>');
dbms_output.put_line(rsl);
dbms_output.put_line('</td>');
dbms_output.put_line('<td>');
dbms_output.put_line(headroom_in_scn);
dbms_output.put_line('</td>');
dbms_output.put_line('<td>');
dbms_output.put_line(headroom_in_sec);
dbms_output.put_line('<td>');
dbms_output.put_line(cur_scn_compat);
dbms_output.put_line('</td>');
dbms_output.put_line('<td>');
dbms_output.put_line(max_scn_compat);
dbms_output.put_line('</td>');
dbms_output.put_line('</tr>');
dbms_output.put_line('</table>');
dbms_output.put_line('<p>');
dbms_output.put_line('<br>');
end;
/
set markup html on

--===========================================================================================================================================
--                                              12.2 specific check
--===========================================================================================================================================
PROMPT
PROMPT
PROMPT =============================================================
PROMPT "DBA_EXTERNAL_SCN_ACTIVITY Output - only for 12.2 Databases"
PROMPT =============================================================
PROMPT
COLUMN EXTERNAL_SCN FORMAT 999,999,999,999,999,999,999;
COLUMN SCN_ADJUSTMENT FORMAT 999,999,999,999,999,999,999;
(
	SELECT 'Extrinsic_SCN' "CHECK_NAME", RESULT, OPERATION_TIMESTAMP, EXTERNAL_SCN, SCN_ADJUSTMENT, HOST_NAME, DB_NAME, SESSION_ID, SESSION_SERIAL# 
	FROM 
		DBA_EXTERNAL_SCN_ACTIVITY a, DBA_DB_LINK_SOURCES s 
	WHERE 
		a.INBOUND_DB_LINK_SOURCE_ID = s.SOURCE_ID
)
UNION
(
	SELECT 'Extrinsic_SCN' "CHECK_NAME", RESULT, OPERATION_TIMESTAMP, EXTERNAL_SCN, SCN_ADJUSTMENT, dbms_tns.resolve_tnsname(HOST) HOST_NAME, NULL DB_NAME, SESSION_ID, SESSION_SERIAL# 
	FROM 
		DBA_EXTERNAL_SCN_ACTIVITY a, DBA_DB_LINKS o
	WHERE 
		a.OUTBOUND_DB_LINK_NAME = o.DB_LINK 
		AND a.OUTBOUND_DB_LINK_OWNER = o.OWNER
)
UNION
(
	SELECT 'Extrinsic_SCN' "CHECK_NAME", RESULT, OPERATION_TIMESTAMP, EXTERNAL_SCN, SCN_ADJUSTMENT, s.MACHINE HOST_NAME, NULL DB_NAME, SESSION_ID, SESSION_SERIAL# 
	FROM 
		DBA_EXTERNAL_SCN_ACTIVITY a, V$SESSION s 
	WHERE 
		a.SESSION_ID = s.SID 
		AND a.SESSION_SERIAL#=s.SERIAL# 
		AND INBOUND_DB_LINK_SOURCE_ID IS NULL 
		AND OUTBOUND_DB_LINK_NAME IS NULL 
		AND OUTBOUND_DB_LINK_OWNER IS NULL
)
/
PROMPT
PROMPT
PROMPT
select * from DBA_EXTERNAL_SCN_ACTIVITY
/
--===========================================================================================================================================
--                                Checking the historical SCN rate and headroom information - archivelog mode
--===========================================================================================================================================
PROMPT
PROMPT
PROMPT =================================================
PROMPT "SCN Rate - For Archivelog Mode"
PROMPT =================================================
COLUMN gscn FORMAT 999,999,999,999,999,999,999;
SELECT 'SCN_Rate-Archivelog' "CHECK_NAME",tim, gscn, 
  round(rate),
  round((chk16kscn - gscn)/24/3600/16/1024,1) "Headroom"
FROM  
(
 select tim, gscn, rate,
  ((
  ((to_number(to_char(tim,'YYYY'))-1988)*12*31*24*60*60) +
  ((to_number(to_char(tim,'MM'))-1)*31*24*60*60) +
  (((to_number(to_char(tim,'DD'))-1))*24*60*60) +
  (to_number(to_char(tim,'HH24'))*60*60) +
  (to_number(to_char(tim,'MI'))*60) +
  (to_number(to_char(tim,'SS')))
  ) * (16*1024)) chk16kscn
 from 
 ( 
   select FIRST_TIME tim , FIRST_CHANGE# gscn,
          ((NEXT_CHANGE#-FIRST_CHANGE#)/
           ((NEXT_TIME-FIRST_TIME)*24*60*60)) rate
     from v$archived_log
    where (next_time > first_time) 
 )
)
order by 1,2
/

--===========================================================================================================================================
--                                Checking the historical SCN rate and headroom information - non archivelog mode
--===========================================================================================================================================
PROMPT
PROMPT
PROMPT =================================================
PROMPT "SCN Rate - For NoArchivelog Mode"
PROMPT =================================================
PROMPT
COLUMN gscn FORMAT 999,999,999,999,999,999,999;
SELECT 'SCN_Rate-NoArchivelog' "CHECK_NAME",tim, gscn, 
        round(rate), 
        round((chk16kscn - gscn)/24/3600/16/1024,1) "Headroom" 
      FROM   
      ( 
       select tim, gscn, rate, 
        (( 
        ((to_number(to_char(tim,'YYYY'))-1988)*12*31*24*60*60) + 
        ((to_number(to_char(tim,'MM'))-1)*31*24*60*60) + 
        (((to_number(to_char(tim,'DD'))-1))*24*60*60) + 
        (to_number(to_char(tim,'HH24'))*60*60) + 
        (to_number(to_char(tim,'MI'))*60) + 
        (to_number(to_char(tim,'SS'))) 
        ) * (16*1024)) chk16kscn 
       from 
       ( 
         select FIRST_TIME tim , FIRST_CHANGE# gscn, 
                ((NEXT_CHANGE#-FIRST_CHANGE#)/ 
                 ((NEXT_TIME-FIRST_TIME)*24*60*60)) rate 
           from (select first_time, lead(first_time, 1) over (order by first_time) as next_time,
                        FIRST_CHANGE#, NEXT_CHANGE#
                   from v$log_history
                  where thread#=1
                    and first_time > trunc(sysdate-4))
          where (next_time > first_time) 
       ) 
      ) 
order by 1,2 
/
--===========================================================================================================================================
--                                Historial values for SCN spike from the AWR Repository - modified
--===========================================================================================================================================
set pages 1000
PROMPT
PROMPT
PROMPT =========================================================
PROMPT "Check for Intrinsic SCN spike - 1 month data"
PROMPT "This report checks for global report in RAC Database"
PROMPT =========================================================
PROMPT
column End_Snap_ID format 999999
column end_interval_time heading 'Snap Started' format a18 just c;
column dbid heading 'DB Id' format a12 just c;
column instance_number heading 'Inst_Num' format 99999;
column elapsed heading 'Elapsed' format 999999;
column SCN_RATE format 999999999999
column PER_SEC format 999999999999
SELECT 'Intrinsic_SCN_Rate' "CHECK_NAME",snap_id End_Snap_ID,
       To_char(dbid) DBID,
       elapsed,
       To_char(end_interval_time, 'dd Mon YYYY HH24:mi') END_INTERVAL_TIME,
       ( CASE
           WHEN stat_value > 0 THEN stat_value
           ELSE 0
         END ) SCN_GROWTH,
		round (stat_value / (elapsed),0) PER_SEC
FROM   (SELECT snap_id,
               dbid,
               elapsed,
               end_interval_time,
               stat_name,
               ( stat_value - Lag (stat_value, 1, stat_value)
                                over (
								   PARTITION BY dbid 
                                  ORDER BY snap_id) ) AS STAT_VALUE
								  -- stat_value: change in the statistic during each snapshot period
        FROM   (SELECT snap_id,
                       dbid,
                       elapsed,
                       end_interval_time,
                       stat_name,
                       SUM(stat_value) AS STAT_VALUE
                FROM   (SELECT X.snap_id,
                               X.dbid,
                               Trunc(SN.end_interval_time, 'mi') END_INTERVAL_TIME,
                               X.stat_name,
                               Trunc(( Cast(SN.end_interval_time AS DATE) -
                                       Cast(SN.begin_interval_time AS DATE) ) *
                                     86400)                      ELAPSED,
                               X.value STAT_VALUE
                        FROM   dba_hist_sysstat X,
                               dba_hist_snapshot SN,
							      (SELECT 
                                       Min(startup_time) STARTUP_TIME
                                FROM   dba_hist_snapshot
                                WHERE  BEGIN_INTERVAL_TIME > sysdate - 30
								) MS
                        WHERE  X.snap_id = sn.snap_id
                               AND X.dbid = sn.dbid
                               AND x.dbid in (select dbid from v$database)
                               AND x.snap_id in (select snap_id from dba_hist_snapshot where BEGIN_INTERVAL_TIME > sysdate - 30)
                               AND SN.startup_time = MS.startup_time
                               AND X.stat_name = 'calls to kcmgas'
                        )
                GROUP  BY snap_id,
                          dbid,
                          elapsed,
                          end_interval_time,
                          stat_name
				)
		)
		WHERE stat_value > (elapsed * 2) 
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

@?/rdbms/admin/sqlsessend.sql
