Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_dbhang_hq.sql /main/2 2021/07/26 03:30:22 cnagur Exp $
Rem
Rem srdc_dbhang_hq.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_dbhang_hq.sql - Hang detection query
Rem
Rem    DESCRIPTION
Rem      Query to detect hang scenarios, the output returned can be used to 
Rem      decide if any mitigation actions need to be taken.
Rem
Rem      Connect using SYS credentials to run the script.
Rem
Rem      The query requires two parameters, the parameters can either be 
Rem      entered manually when prompted, or can be passed when running the 
Rem      script, for example "@pdbcs_hq.sql 5 600"
Rem
Rem      - the first parameter is the minimum number of sessions waiting
Rem      - the second parameter is the minimum wait time for this chain
Rem
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_dbhang_hq.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/20/21 - initial integration into AHF, script version is 3.4
Rem

@@?/rdbms/admin/sqlsessstart.sql
define wtrs = &1
define wtm = &2

alter session set optimizer_ignore_hints=FALSE;

column tm new_value file_time noprint

select to_char(sysdate, 'yyyymmdd:hh24:mi:ss') tm from dual;

spool 'hang_info_&file_time'

set pagesize 1000 lines 400 serverout on verify off feedback off

column INST_ID heading "Waiter|Inst"
column KJZNHMLSIPDBID heading "Waiter|PDB ID"
column KJZNHMLSISID heading "Waiter|SID"
column KJZNHMLSISNO heading "Waiter|Serial#"
column KJZNHMLSIOSPID heading "Waiter|OSPID"
column KJZNHMLSIPRCNM heading "Waiter|Name" format a8
column WAITER_QC heading "Waiter|Is QC" format a8
column WAITER_SLAVE heading "Waiter|Is Slave" format a8
column WAITER_QC_INST_SID heading "Waiters QC|Inst,SID,SER#" format a20
column KJZNHMLSIWTRWTTM heading "Waiter|Wait Tm"
column KJZNHMLSITTLWTRS heading "Number|of Waiters"
column WAITER_QC heading "Waiter|Is QC" format a8
column "Waiter Wait Event Name" format a50
column KJZNHMLSIBLKRINSTNO heading "Blocker|Inst"
column KJZNHMLSIBLKRPDBID heading "Blocker|PDB ID"
column KJZNHMLSIBLKRSID heading "Blocker|SID"
column KJZNHMLSIBLKRSNO heading "Blocker|Serial#"
column KJZNHMLSIBLKRPRCNM heading "Blocker|Name" format a8
column BLOCKER_QC heading "Blocker|Is QC" format a8
column BLOCKER_SLAVE heading "Blocker|Is Slave" format a8
column BLOCKER_QC_INST_SID heading "Blocker QC|Inst,SID,SER#" format a20
column KJZNHMLSIBLKROSPID heading "Blocker|OSPID"
column KJZNHMLSIBLKRWTTM heading "Blocker|Wait Tm"

exec dbms_output.put_line(chr(9));
exec dbms_output.put_line(chr(9));
exec dbms_output.put_line('*** Script will execute looking for wait chains where there are >= '||&wtrs||' sessions waiting, or have been wating >= '||&wtm||' seconds ***');
exec dbms_output.put_line(chr(9));
exec dbms_output.put_line('*** Generating output from original Hang Manager based hang query ***');

set feedback on
WITH
  sesslist
AS
(
SELECT a.INST_ID, a.KJZNHMLSIPDBID, a.KJZNHMLSISID, a.KJZNHMLSISNO, a.KJZNHMLSIOSPID, a.KJZNHMLSIPRCNM,
       a.KJZNHMLSITTLWTRS, a.KJZNHMLSIWTRWTTM, c.name,
       a.KJZNHMLSIBLKRINSTNO, b.KJZNHMLSIBLKRPDBID, a.KJZNHMLSIBLKRSID, a.KJZNHMLSIBLKRSNO,
       b.KJZNHMLSIBLKRPRCNM, b.KJZNHMLSIBLKROSPID, a.KJZNHMLSIBLKRWTTM
  FROM table(sys.gv$(cursor(SELECT inst_id, KJZNHMLSIPDBID, KJZNHMLSISID, KJZNHMLSISNO, KJZNHMLSIOSPID, 
                                   KJZNHMLSITTLWTRS, KJZNHMLSIWTRWTTM, KJZNHMLSIBLKRSID, KJZNHMLSIBLKRINSTNO, 
                                   KJZNHMLSIBLKRSNO, KJZNHMLSIPRCNM, KJZNHMLSIWTEVT, KJZNHMLSIBLKRWTTM 
                              FROM X$kjznhmlsi))) a,
       table(sys.gv$(cursor(SELECT inst_id, KJZNHMLSIPDBID "KJZNHMLSIBLKRPDBID", KJZNHMLSISID, KJZNHMLSISNO, 
                                   KJZNHMLSITTLWTRS, KJZNHMLSIPRCNM "KJZNHMLSIBLKRPRCNM", 
                                   KJZNHMLSIOSPID "KJZNHMLSIBLKROSPID" 
                              FROM x$kjznhmlsi))) b,
       v$event_name c
 WHERE a.KJZNHMLSISNO > 0
   and c.event# > 0
   and a.KJZNHMLSITTLWTRS >= &wtrs
   and (a.KJZNHMLSIWTRWTTM > &wtm OR a.KJZNHMLSIBLKRWTTM > &wtm)
   and a.KJZNHMLSIBLKRSID > 0 
   and a.KJZNHMLSIBLKRINSTNO > 0
   and a.KJZNHMLSIBLKRINSTNO = b.INST_ID
   and a.KJZNHMLSIBLKRSID = b.KJZNHMLSISID
   and a.KJZNHMLSIBLKRSNO = b.KJZNHMLSISNO
   and a.KJZNHMLSIWTEVT = c.event#
)
,  qclist
AS
(
SELECT /*+ CARDINALITY(ps 5000) CARDINALITY(s 10000) CARDINALITY(p 10000) */ ps.inst_id, ps.sid, ps.serial#, p.spid
  FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                         AND ps.saddr = s.saddr
                        JOIN gv$process p ON s.paddr = p.addr
                                         AND s.inst_id = p.inst_id
 WHERE ps.sid = ps.qcsid
 ORDER BY 1,2
)
, slavelist
AS
(
SELECT /*+ CARDINALITY(ps 5000) CARDINALITY(s 10000) CARDINALITY(p 10000) */ ps.inst_id, ps.sid, ps.serial#, ps.qcinst_id, ps.qcsid, ps.qcserial#, p.spid
  FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                         AND ps.saddr = s.saddr
                        JOIN gv$process p ON s.paddr = p.addr
                                         AND s.inst_id = p.inst_id
 WHERE ps.sid != ps.qcsid
 ORDER BY 4, 5, 1, 2
)
SELECT se.INST_ID, KJZNHMLSIPDBID, KJZNHMLSISID, KJZNHMLSISNO, KJZNHMLSIOSPID, KJZNHMLSIPRCNM,
       to_char(CASE WHEN KJZNHMLSIOSPID = q.spid
                     AND se.INST_ID = q.inst_id
                    THEN 'YES'
                    ELSE 'NO'
               END) WAITER_QC,
       to_char(CASE WHEN KJZNHMLSIOSPID = sl.spid
                     AND se.INST_ID = sl.inst_id
                    THEN 'YES'
                    ELSE 'NO'
               END) WAITER_SLAVE,
       to_char(CASE WHEN KJZNHMLSIOSPID = sl.spid
                     AND se.INST_ID = sl.inst_id
                    THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                    ELSE NULL
               END) WAITER_QC_INST_SID,
       KJZNHMLSITTLWTRS, KJZNHMLSIWTRWTTM,
       name "Waiter Wait Event Name",
       KJZNHMLSIBLKRINSTNO, KJZNHMLSIBLKRPDBID, KJZNHMLSIBLKRSID, KJZNHMLSIBLKRSNO, 
       KJZNHMLSIBLKROSPID, KJZNHMLSIBLKRPRCNM,
       to_char(CASE WHEN KJZNHMLSIBLKROSPID = q.spid
                     AND se.INST_ID = q.inst_id
                    THEN 'YES'
                    ELSE 'NO'
               END) BLOCKER_QC,
       to_char(CASE WHEN KJZNHMLSIBLKROSPID = sl.spid
                     AND se.INST_ID = sl.inst_id
                    THEN 'YES'
                    ELSE 'NO'
               END) BLOCKER_SLAVE,
       to_char(CASE WHEN KJZNHMLSIBLKROSPID = sl.spid
                     AND se.INST_ID = sl.inst_id
                    THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                    ELSE NULL
               END) BLOCKER_QC_INST_SID,
       KJZNHMLSIBLKRWTTM
  FROM sesslist se
  LEFT JOIN qclist q ON (se.inst_id = q.inst_id AND (KJZNHMLSIOSPID = q.spid OR KJZNHMLSIBLKROSPID = q.spid))
  LEFT JOIN slavelist sl ON (se.inst_id = sl.inst_id AND (KJZNHMLSIOSPID = sl.spid OR KJZNHMLSIBLKROSPID = sl.spid))
;

set pagesize 1000 lines 400
column chain_id heading "Chain|ID" format 9999999
column chain_signature heading "Signature" format a160
column instance heading "Waiter|Inst" format 99
column pdb_id heading "Waiter|PDBID"
column pdb_name heading "Waiter|PDB Name" format a50
column pid heading "Waiter|PID" format 99999999
column sid heading "Waiter|SID" format 99999999
column sess_serial# heading "Waiter|Serial#"
column osid heading "Waiter|OSPID" format a10
column waiter heading "Waiter|Name" format a8
column WAITER_QC heading "Waiter|Is QC" format a8
column WAITER_SLAVE heading "Waiter|Is Slave" format a8
column WAITER_QC_INST_SID heading "Waiters QC|Inst,SID,SER#" format a20
column wait_event_text heading "Waiter Wait|Event Name" format a30
column in_wait_secs heading "Wait Time|Secs"
column blocker_instance heading "Blocker|Inst" format 99
column blocker_pdb_id heading "Blocker|PDBID"
column blocker_pdb_name heading "Blocker|PDB Name" format a50
column blocker_pid heading "Blocker|PID" format 99999999
column blocker_sid heading "Blocker|SID" format 99999999
column blocker_sess_serial# heading "Blocker|Serial#"
column blocker_osid heading "Blocker|OSPID" format a10
column blocker heading "Blocker|Name" format a8
column BLOCKER_QC heading "Blocker|Is QC" format a8
column BLOCKER_SLAVE heading "Blocker|Is Slave" format a8
column BLOCKER_QC_INST_SID heading "Blocker QC|Inst,SID,SER#" format a20
column blocker_event heading "Blocker Wait|Event Name" format a30
column module heading "Blocker|Module" format a40
column num_waiters heading "Number|of Waiters" format 999999
column longest heading "Longest|Waiter Secs" 
column waiting_on heading "Blocker Wait|Event Name" format a50

set feedback off
DECLARE
  c_count NUMBER;
  cycles  NUMBER;
  cycles_rc sys_refcursor;
BEGIN
  dbms_output.put_line(chr(9));
  dbms_output.put_line('*** Checking to see if there are active waits in the system ***');

  SELECT COUNT(DISTINCT chain_id) INTO c_count
    FROM v$wait_chains WHERE blocker_sid IS NOT NULL;
  IF c_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** Right now, there are no blocked wait chains in the system, rerun this script when waits are active ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are ' || c_count || ' blocked wait chains in the system ***');

    SELECT COUNT(DISTINCT chain_id) INTO cycles
      FROM v$wait_chains 
     WHERE blocker_sid IS NOT NULL
       AND chain_signature LIKE '%(cycle)%';

    IF cycles <> 0 THEN
      dbms_output.put_line(chr(9));
      dbms_output.put_line('*** Of those ' || c_count || ' chains ' || cycles || ' of them are cycles where the waiters and blockers are waiting on each other ***');
      dbms_output.put_line(chr(9));

      open cycles_rc for 
        WITH
          sesslist
        AS
        (
        SELECT chain_id, instance, chain_signature, osid, wc.pid, sid, sess_serial#, a.pname AS waiter,
               pdb_id, pdb_name, blocker_instance, blocker_osid, blocker_pid, blocker_sid,
               blocker_sess_serial#, blocker_pdb_id, blocker_pdb_name, b.pname AS blocker,
               in_wait_secs, num_waiters, wait_event_text, p1, p2
          FROM v$wait_chains wc
          JOIN gv$process a ON (osid = a.spid AND instance = a.inst_id)
          JOIN gv$process b ON (blocker_osid = b.spid AND blocker_instance = b.inst_id)
         WHERE chain_signature LIKE '%(cycle)%'
        )
        ,  qclist
        AS
        (
        SELECT ps.inst_id, ps.sid, ps.serial#, p.spid
          FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                                 AND ps.saddr = s.saddr
                                JOIN gv$process p ON s.paddr = p.addr
                                                 AND s.inst_id = p.inst_id
         WHERE ps.sid = ps.qcsid
         ORDER BY 1,2
        )
        , slavelist
        AS
        (
        SELECT ps.inst_id, ps.sid, ps.serial#, ps.qcinst_id, ps.qcsid, ps.qcserial#, p.spid
          FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                                 AND ps.saddr = s.saddr
                                JOIN gv$process p ON s.paddr = p.addr
                                                 AND s.inst_id = p.inst_id
         WHERE ps.sid != ps.qcsid
         ORDER BY 4, 5, 1, 2
        )
        SELECT chain_id, chain_signature, instance, pdb_id, pdb_name, pid, se.sid, sess_serial#, osid, NVL(waiter, 'FG') waiter,
               to_char(CASE WHEN osid = q.spid
                             AND instance = q.inst_id
                            THEN 'YES'
                            ELSE 'NO'
                       END) WAITER_QC,
               to_char(CASE WHEN osid = sl.spid
                             AND instance = sl.inst_id
                            THEN 'YES'
                            ELSE 'NO'
                       END) WAITER_SLAVE,
               to_char(CASE WHEN osid = sl.spid
                             AND instance = sl.inst_id
                            THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                            ELSE NULL
                       END) WAITER_QC_INST_SID,
               wait_event_text, in_wait_secs,
               blocker_instance, blocker_pdb_id, blocker_pdb_name, blocker_pid, blocker_sid, blocker_sess_serial#,
               blocker_osid, NVL(blocker, 'FG') blocker,
               to_char(CASE WHEN blocker_osid = q.spid
                             AND blocker_instance = q.inst_id
                            THEN 'YES'
                            ELSE 'NO'
                       END) BLOCKER_QC,
               to_char(CASE WHEN blocker_osid = sl.spid
                             AND blocker_instance = sl.inst_id
                            THEN 'YES'
                            ELSE 'NO'
                       END) BLOCKER_SLAVE,
               to_char(CASE WHEN blocker_osid = sl.spid
                             AND se.blocker_instance = sl.inst_id
                            THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                            ELSE NULL
                       END) BLOCKER_QC_INST_SID,
               sw.event AS blocker_event, num_waiters
          FROM sesslist se
          LEFT JOIN qclist q ON ((se.instance = q.inst_id OR se.blocker_instance = q.inst_id) AND
                                 (osid = q.spid OR blocker_osid = q.spid))
          LEFT JOIN slavelist sl ON ((se.instance = sl.inst_id OR se.blocker_instance = q.inst_id) AND
                                     (osid = sl.spid OR blocker_osid = sl.spid))
          LEFT JOIN gv$session_wait sw ON (se.blocker_instance = sw.inst_id AND
                                           se.blocker_sid = sw.sid)
         ORDER BY chain_id, in_wait_secs ASC
        ;

      dbms_sql.return_result(cycles_rc);
    END IF;
  END IF;
END;
/

column wait_event_text heading "Blocker Wait|Event Name" format a30
DECLARE
  w_count NUMBER;
  blockers_rc sys_refcursor;
  waiters_rc sys_refcursor;
BEGIN
  SELECT COUNT(DISTINCT chain_id) INTO w_count
    FROM v$wait_chains WHERE num_waiters >= &wtrs;
  IF w_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are no wait chains with sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are ' || w_count || ' wait chains with sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line('*** The chains (max 10) with most waiters are as follows ***');
    dbms_output.put_line(chr(9));

    open blockers_rc for
      SELECT chain_id, chain_signature, instance, osid, wc.pid, sid, sess_serial#, 
             NVL(a.pname, 'FG') blocker, pdb_id, pdb_name, num_waiters, in_wait_secs, 
             wait_event_text
        FROM v$wait_chains wc
             JOIN gv$process a ON (osid = a.spid AND instance = a.inst_id)
       WHERE num_waiters >= &wtrs
       ORDER BY num_waiters DESC
       FETCH FIRST 10 ROWS ONLY;

     dbms_sql.return_result(blockers_rc);
  END IF;
END;
/

DECLARE
  b_count NUMBER;
  blockers_rc sys_refcursor;
BEGIN
  SELECT COUNT(*) INTO b_count
    FROM (SELECT DISTINCT instance, sid
            FROM v$wait_chains
           WHERE num_waiters >= &wtrs);
  IF b_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are no sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are ' || b_count || ' sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line('*** The highest (max 10 blockers) of those are as follows ***');
    dbms_output.put_line(chr(9));

    open blockers_rc for
      SELECT instance blocker_instance, sid blocker_sid, osid blocker_osid, NVL(a.pname, 'FG') blocker, num_waiters
        FROM v$wait_chains wc
             JOIN gv$process a ON (osid = a.spid AND instance = a.inst_id)
       WHERE num_waiters >= &wtrs
       ORDER BY num_waiters DESC
       FETCH FIRST 10 ROWS ONLY;

     dbms_sql.return_result(blockers_rc);
  END IF;
END;
/

DECLARE
  w_count NUMBER;
  chains_rc sys_refcursor;
BEGIN
  SELECT COUNT(DISTINCT chain_id) INTO w_count
    FROM v$wait_chains WHERE in_wait_secs >= &wtm;
  IF w_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are no wait chains involving sessions waiting ' || &wtm || ' or more seconds ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are ' || w_count || ' wait chains that contain sessions waiting ' || &wtm || ' or more seconds ***');
    dbms_output.put_line('*** The longest (max 10 chains) of those are as follows ***');
    dbms_output.put_line(chr(9));

    open chains_rc for
      SELECT DISTINCT chain_id, chain_signature, max(in_wait_secs) longest
        FROM v$wait_chains wc
             JOIN gv$process a ON (osid = a.spid AND instance = a.inst_id)
       WHERE in_wait_secs >= &wtm
         AND blocker_is_valid = 'TRUE'
       GROUP BY chain_id, chain_signature
       ORDER BY longest DESC
       FETCH FIRST 10 ROWS ONLY;

     dbms_sql.return_result(chains_rc);
  END IF;
END;
/

DECLARE
  b_count NUMBER;
  blockers_rc sys_refcursor;
BEGIN
  SELECT COUNT(*) INTO b_count
    FROM (SELECT DISTINCT blocker_instance, blocker_sid
            FROM v$wait_chains
           WHERE in_wait_secs >= &wtm
             AND blocker_is_valid='TRUE');
  IF b_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are no blocking sessions with waiters waiting ' || &wtm || ' or more seconds ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** There are ' || b_count || ' blocking sessions blocking sessions waiting ' || &wtm || ' or more seconds ***');
    dbms_output.put_line('*** The longest (max 10 blockers) of those are as follows ***');
    dbms_output.put_line(chr(9));

    open blockers_rc for
      WITH time_blockers AS
      (
        SELECT DISTINCT blocker_instance, blocker_sid
          FROM v$wait_chains wc
         WHERE in_wait_secs >= &wtm
         ORDER BY in_wait_secs DESC
         FETCH FIRST 10 ROWS ONLY
      )
      SELECT DISTINCT blocker_instance, blocker_sid, blocker_osid, NVL(a.pname, 'FG') blocker, 
                      max(in_wait_secs) longest
        FROM v$wait_chains wc
             JOIN gv$process a ON (blocker_osid = a.spid AND blocker_instance = a.inst_id)
       WHERE (blocker_instance, blocker_sid) IN (SELECT * from time_blockers)
       GROUP BY blocker_instance, blocker_sid, blocker_osid, NVL(a.pname, 'FG')
       ORDER BY longest DESC;

     dbms_sql.return_result(blockers_rc);
  END IF;
END;
/

column blocker_instance heading "Blocker|Inst" format 99
column blocker_sid heading "Blocker|SID" format 99999999
column num_waiters heading "Number|of Waiters" format 999999

DECLARE
  t_count NUMBER;
  w_count NUMBER;
  l_count NUMBER;
  blockers_rc1 sys_refcursor;
  blockers_rc2 sys_refcursor;
BEGIN
  SELECT COUNT(*) INTO t_count
    FROM (SELECT DISTINCT blocker_instance, blocker_sid
            FROM v$wait_chains
           WHERE in_wait_secs >= &wtm
             AND blocker_is_valid='TRUE');
  SELECT COUNT(*) INTO w_count
    FROM (SELECT DISTINCT instance, sid
            FROM v$wait_chains
           WHERE num_waiters >= &wtrs);

  IF t_count = 0 AND w_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** In summary there are no blocking sessions with waiters waiting ' || &wtm || ' seconds or blocking ' || &wtrs || ' other sessions ***');
    dbms_output.put_line(chr(9));
  ELSIF t_count <> 0 AND w_count = 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** In summary there are no sessions blocking ' || &wtrs || ' other sessions, but there are ' || t_count || ' sessions blocking sessions waiting ' || &wtm || ' or more seconds ***');
    dbms_output.put_line('*** The blocking sessions are as below, ordered by the number of sessions waiting, output is shown twice with a short wait between to eliminate transient sessions ***');
    dbms_output.put_line(chr(9));
  ELSIF t_count = 0 AND w_count <> 0 THEN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** In summary there are no sessions blocking sessions waiting ' || &wtm || ' or more seconds, but there are ' || w_count || ' sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line('*** The blocking sessions are as below, ordered by the number of sessions waiting, output is shown twice with a short wait between to eliminate transient sessions ***');
    dbms_output.put_line(chr(9));
  ELSE
    dbms_output.put_line(chr(9));
    dbms_output.put_line('*** In summary there are ' || t_count || ' sessions blocking sessions waiting ' || &wtm || ' or more seconds, and there are ' || w_count || ' sessions blocking ' || &wtrs || ' or more other sessions ***');
    dbms_output.put_line('*** The blocking sessions are as below, ordered by the number of sessions waiting, output is shown twice with a short wait between to eliminate transient sessions ***');
    dbms_output.put_line(chr(9));
  END IF;

  BEGIN
    open blockers_rc1 for
      WITH blockers AS
      (
      SELECT DISTINCT instance, sid, osid, num_waiters
        FROM v$wait_chains wc
       WHERE num_waiters >= &wtrs
      ORDER BY num_waiters DESC
      FETCH FIRST 10 ROWS ONLY
      )
      , time_blockers AS
      (
        SELECT blocker_instance, blocker_sid, blocker_osid, max(in_wait_secs) longest
          FROM v$wait_chains wc
         WHERE in_wait_secs >= &wtm
           AND blocker_is_valid = 'TRUE'
         GROUP BY blocker_instance, blocker_sid, blocker_osid
         ORDER BY longest DESC
         FETCH FIRST 10 ROWS ONLY
      )
      ,  qclist
      AS
      (
      SELECT ps.inst_id, ps.sid, ps.serial#, p.spid
        FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                               AND ps.saddr = s.saddr
                              JOIN gv$process p ON s.paddr = p.addr
                                               AND s.inst_id = p.inst_id
       WHERE ps.sid = ps.qcsid
       ORDER BY 1,2
      )
      , slavelist
      AS
      (
      SELECT ps.inst_id, ps.sid, ps.serial#, ps.qcinst_id, ps.qcsid, ps.qcserial#, p.spid
        FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                               AND ps.saddr = s.saddr
                              JOIN gv$process p ON s.paddr = p.addr
                                               AND s.inst_id = p.inst_id
       WHERE ps.sid != ps.qcsid
       ORDER BY 4, 5, 1, 2
      ), sesslist
      AS
      (
        SELECT DISTINCT b.instance blocker_instance, b.sid blocker_sid, b.osid blocker_osid, NVL(p.pname, 'FG') blocker, num_waiters, longest
          FROM blockers b
               JOIN gv$process p ON (b.osid = p.spid AND b.instance = p.inst_id)
               LEFT JOIN time_blockers t ON (b.instance = t.blocker_instance AND b.sid = t.blocker_sid)
         UNION ALL
         SELECT t.blocker_instance, t.blocker_sid, t.blocker_osid, NVL(p.pname, 'FG') blocker, wc.num_waiters, longest
           FROM time_blockers t
               JOIN gv$process p ON (t.blocker_osid = p.spid AND t.blocker_instance = p.inst_id)
               JOIN v$wait_chains wc ON (wc.instance = t.blocker_instance AND wc.sid = t.blocker_sid)
       )
       SELECT DISTINCT blocker_instance, blocker_sid, blocker_osid, blocker,
              to_char(CASE WHEN blocker_osid = q.spid
                            AND blocker_instance = q.inst_id
                           THEN 'YES'
                           ELSE 'NO'
                      END) BLOCKER_QC,
              to_char(CASE WHEN blocker_osid = sl.spid
                            AND blocker_instance = sl.inst_id
                           THEN 'YES'
                           ELSE 'NO'
                      END) BLOCKER_SLAVE,
              to_char(CASE WHEN blocker_osid = sl.spid
                            AND se.blocker_instance = sl.inst_id
                           THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                           ELSE NULL
                      END) BLOCKER_QC_INST_SID,
              module, num_waiters, longest, event waiting_on
         FROM sesslist se
         LEFT JOIN gv$session s ON (se.blocker_instance = s.inst_id AND se.blocker_sid = s.sid)
         LEFT JOIN qclist q ON (se.blocker_instance = q.inst_id AND se.blocker_osid = q.spid)
         LEFT JOIN slavelist sl ON (se.blocker_instance = sl.inst_id AND se.blocker_osid = sl.spid)
       ORDER BY num_waiters DESC, longest DESC;

     dbms_sql.return_result(blockers_rc1);
  END;

  BEGIN
    dbms_lock.sleep(10);
    open blockers_rc2 for
      WITH blockers AS
      (
      SELECT DISTINCT instance, sid, osid, num_waiters
        FROM v$wait_chains wc
       WHERE num_waiters >= &wtrs
      ORDER BY num_waiters DESC
      FETCH FIRST 10 ROWS ONLY
      )
      , time_blockers AS
      (
        SELECT blocker_instance, blocker_sid, blocker_osid, max(in_wait_secs) longest
          FROM v$wait_chains wc
         WHERE in_wait_secs >= &wtm
           AND blocker_is_valid = 'TRUE'
         GROUP BY blocker_instance, blocker_sid, blocker_osid
         ORDER BY longest DESC
         FETCH FIRST 10 ROWS ONLY
      )
      ,  qclist
      AS
      (
      SELECT ps.inst_id, ps.sid, ps.serial#, p.spid
        FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                               AND ps.saddr = s.saddr
                              JOIN gv$process p ON s.paddr = p.addr
                                               AND s.inst_id = p.inst_id
       WHERE ps.sid = ps.qcsid
       ORDER BY 1,2
      )
      , slavelist
      AS
      (
      SELECT ps.inst_id, ps.sid, ps.serial#, ps.qcinst_id, ps.qcsid, ps.qcserial#, p.spid
        FROM gv$px_session ps JOIN gv$session s ON ps.inst_id = s.inst_id
                                               AND ps.saddr = s.saddr
                              JOIN gv$process p ON s.paddr = p.addr
                                               AND s.inst_id = p.inst_id
       WHERE ps.sid != ps.qcsid
       ORDER BY 4, 5, 1, 2
      ), sesslist
      AS
      (
        SELECT DISTINCT b.instance blocker_instance, b.sid blocker_sid, b.osid blocker_osid, NVL(p.pname, 'FG') blocker, num_waiters, longest
          FROM blockers b
               JOIN gv$process p ON (b.osid = p.spid AND b.instance = p.inst_id)
               LEFT JOIN time_blockers t ON (b.instance = t.blocker_instance AND b.sid = t.blocker_sid)
         UNION ALL
         SELECT t.blocker_instance, t.blocker_sid, t.blocker_osid, NVL(p.pname, 'FG') blocker, wc.num_waiters, longest
           FROM time_blockers t
               JOIN gv$process p ON (t.blocker_osid = p.spid AND t.blocker_instance = p.inst_id)
               JOIN v$wait_chains wc ON (wc.instance = t.blocker_instance AND wc.sid = t.blocker_sid)
       )
       SELECT DISTINCT blocker_instance, blocker_sid, blocker_osid, blocker,
              to_char(CASE WHEN blocker_osid = q.spid
                            AND blocker_instance = q.inst_id
                           THEN 'YES'
                           ELSE 'NO'
                      END) BLOCKER_QC,
              to_char(CASE WHEN blocker_osid = sl.spid
                            AND blocker_instance = sl.inst_id
                           THEN 'YES'
                           ELSE 'NO'
                      END) BLOCKER_SLAVE,
              to_char(CASE WHEN blocker_osid = sl.spid
                            AND se.blocker_instance = sl.inst_id
                           THEN to_char(sl.qcinst_id||','||sl.qcsid||','||sl.qcserial#)
                           ELSE NULL
                      END) BLOCKER_QC_INST_SID,
              module, num_waiters, longest, event waiting_on
         FROM sesslist se
         LEFT JOIN gv$session s ON (se.blocker_instance = s.inst_id AND se.blocker_sid = s.sid)
         LEFT JOIN qclist q ON (se.blocker_instance = q.inst_id AND se.blocker_osid = q.spid)
         LEFT JOIN slavelist sl ON (se.blocker_instance = sl.inst_id AND se.blocker_osid = sl.spid)
       ORDER BY num_waiters DESC, longest DESC;

     dbms_sql.return_result(blockers_rc2);
  END;
END;
/

spool off
@?/rdbms/admin/sqlsessend.sql
exit 
