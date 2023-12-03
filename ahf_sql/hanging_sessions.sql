Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/hanging_sessions.sql /main/2 2023/07/24 23:59:56 migufuen Exp $
Rem
Rem hanging_sessions.sql
Rem
Rem Copyright (c) 2022, 2023, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      hanging_sessions.sql - It gets the hanging sessions in a database
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/hanging_sessions.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    migufuen    07/19/23 - ENH 35616750 - Get real hanging sessions
Rem    migufuen    10/06/22 - Created
Rem

set heading off;
set linesize 10000;
set long 300000;
set longchunksize 30000;
select JSON_OBJECT('data_type' is 'db_hang', 'db_name' value name,
                   'db_unique_name' value db_unique_name,
                   'timestamp' value TO_CHAR(SYSTIMESTAMP,'yyyy-MM-dd"T"HH24:MI:ss.ff3TZH:TZM'),
                   'db_hang' is (WITH blockers AS
            (
                SELECT DISTINCT chain_id, instance, sid, osid, pdb_name
                FROM v$wait_chains wc WHERE num_waiters >= 3
            )
                                             , time_blockers AS
                (
                    SELECT chain_id, blocker_instance, blocker_sid, blocker_osid, pdb_name
                    FROM v$wait_chains wc
                    WHERE in_wait_secs >= 300 AND blocker_is_valid = 'TRUE'
                ), chains AS
                (
                    SELECT DISTINCT b.chain_id, b.pdb_name, b.instance
                    FROM blockers b JOIN time_blockers t
                                         ON (b.instance = t.blocker_instance
                                             AND b.sid = t.blocker_sid AND b.osid = t.blocker_osid
                                             AND b.pdb_name = t.pdb_name)
                )
                                          SELECT JSON_ARRAYAGG(JSON_OBJECT('count' value count(*), 'pdb_name' value
                                                                           pdb_name, 'instance' value instance returning CLOB) returning CLOB)
                                          FROM v$wait_chains JOIN chains USING (chain_id, pdb_name, instance) group by
                                                                                                                  pdb_name, instance) ABSENT ON NULL returning CLOB)
           result from v$database db;

