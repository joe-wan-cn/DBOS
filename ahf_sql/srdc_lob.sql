Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_lob.sql /main/1 2021/07/26 08:55:41 bvongray Exp $
Rem
Rem srdc_lob.sql
Rem
Rem Copyright (c) 2021, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_lob.sql 
Rem
Rem    DESCRIPTION
Rem     cript to collect LOB related diagnostic data
Rem
Rem    NOTES
Rem      * This script collects the data related to the LOB issues
Rem                including the configuration, parameters , statistics etc
Rem                and creates a spool output. Upload it to the Service Request for further troubleshooting.
Rem      * This script contains some checks which might not be relevant for all versions.
Rem      * This script will *not* update any data.
Rem      * This script must be run using SQL*PLUS.
Rem      * You must be connected AS SYSDBA to run this script.
Rem      * Usage: sqlplus / as sysdba @srdc_lob.sql
Rem      * Ensure not to change the file name or the contents of the spool output before uploading
Rem        to the Service Request.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_lob.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    07/22/21 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='DB_LOB'
define v_owner='&1'
define v_table_name='&2'
set long 2000000000
set pagesize 200 verify off term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
set echo off
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select '+----------------------------------------------------+' "HEADER" from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '      ||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
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


set echo off
prompt
prompt ============================================================================================
prompt                     ++ LOB Details ++
prompt ============================================================================================
prompt

prompt ==================================================
prompt Table Definition
prompt ==================================================
prompt
set echo on
select dbms_metadata.get_ddl('TABLE', table_name, owner) table_definition
  from dba_tables where owner=upper('&&v_owner') and table_name=upper('&&v_table_name');

set echo off
prompt ==================================================
prompt List of lob segments in the table
prompt ==================================================
prompt
set echo on

SELECT l.OWNER, l.TABLE_NAME, l.COLUMN_NAME, l.SEGMENT_NAME, l.TABLESPACE_NAME TABLESPACE_NAME_A,
  l.INDEX_NAME,
  l.COMPRESSION,
  l.SECUREFILE,
  p.PARTITION_NAME,
  p.LOB_PARTITION_NAME,
  p.LOB_INDPART_NAME,
  p.TABLESPACE_NAME TABLESPACE_NAME_B,
  sp.SUBPARTITION_NAME,
  sp.LOB_SUBPARTITION_NAME,
  sp.LOB_INDSUBPART_NAME,
  sp.TABLESPACE_NAME  TABLESPACE_NAME_C
FROM DBA_LOBS l
LEFT OUTER JOIN DBA_LOB_PARTITIONS p
  ON l.OWNER=p.TABLE_OWNER
  AND l.TABLE_NAME=p.TABLE_NAME
  AND l.COLUMN_NAME=p.COLUMN_NAME
  AND l.SEGMENT_NAME=p.LOB_NAME
LEFT OUTER JOIN DBA_LOB_SUBPARTITIONS sp
  ON p.TABLE_OWNER=sp.TABLE_OWNER
  AND p.TABLE_NAME=sp.TABLE_NAME
  AND p.COLUMN_NAME=sp.COLUMN_NAME
  AND p.LOB_NAME=sp.LOB_NAME
  AND p.LOB_PARTITION_NAME=sp.LOB_PARTITION_NAME
where l.owner=upper('&&v_owner') and l.table_name=upper('&&v_table_name')
order by
  l.TABLE_NAME,
  l.COLUMN_NAME,
  l.SEGMENT_NAME,
  p.PARTITION_POSITION,
  sp.SUBPARTITION_POSITION;

set echo off
prompt ==================================================
prompt DBA_LOBS
prompt ==================================================
prompt
set echo on

SELECT * FROM DBA_LOBS l
WHERE l.OWNER=UPPER('&v_owner')
  AND l.TABLE_NAME=UPPER('&v_table_name')
ORDER BY l.COLUMN_NAME;

set echo off
prompt ==================================================
prompt DBA_LOB_PARTITIONS
prompt ==================================================
prompt
set echo on

SELECT p.* FROM DBA_LOBS l, DBA_LOB_PARTITIONS p
WHERE l.OWNER=UPPER('&v_owner')
  AND l.TABLE_NAME=UPPER('&v_table_name')
  AND p.TABLE_OWNER=l.OWNER
  AND p.TABLE_NAME=l.TABLE_NAME
  AND p.COLUMN_NAME=l.COLUMN_NAME
ORDER BY p.COLUMN_NAME, p.PARTITION_POSITION;

set echo off
prompt ==================================================
prompt DBA_LOB_SUBPARTITIONS
prompt ==================================================
prompt
set echo on

SELECT sp.* FROM DBA_LOBS l, DBA_LOB_PARTITIONS p, DBA_LOB_SUBPARTITIONS sp
WHERE l.OWNER=UPPER('&v_owner')
  AND l.TABLE_NAME=UPPER('&v_table_name')
  AND p.TABLE_OWNER=l.OWNER
  AND p.TABLE_NAME=l.TABLE_NAME
  AND p.COLUMN_NAME=l.COLUMN_NAME
  AND sp.TABLE_OWNER=p.TABLE_OWNER
  AND sp.TABLE_NAME=p.TABLE_NAME
  AND sp.COLUMN_NAME=p.COLUMN_NAME
  AND sp.LOB_NAME=p.LOB_NAME
  AND sp.LOB_PARTITION_NAME=p.LOB_PARTITION_NAME
ORDER BY sp.COLUMN_NAME, p.PARTITION_POSITION, sp.SUBPARTITION_POSITION;

set echo off
prompt ==================================================
prompt LOB usage obtained from dbms_space.space_usage
prompt ==================================================
prompt
set echo on
CREATE OR REPLACE TYPE srdc_lob_usage_t AS OBJECT
(
  -- Securefile and Basicfile
  segment_owner       VARCHAR2(256),
  segment_name        VARCHAR2(256),
  segment_type        VARCHAR2(256),
  partition_name      VARCHAR2(256),
  -- Securefile
  segment_size_blocks NUMBER,
  segment_size_bytes  NUMBER,
  used_blocks         NUMBER,
  used_bytes          NUMBER,
  expired_blocks      NUMBER,
  expired_bytes       NUMBER,
  unexpired_blocks    NUMBER,
  unexpired_bytes     NUMBER,
  -- Basicfile
  unformatted_blocks  NUMBER,
  unformatted_bytes   NUMBER,
  fs1_blocks          NUMBER,
  fs1_bytes           NUMBER,
  fs2_blocks          NUMBER,
  fs2_bytes           NUMBER,
  fs3_blocks          NUMBER,
  fs3_bytes           NUMBER,
  fs4_blocks          NUMBER,
  fs4_bytes           NUMBER,
  full_blocks         NUMBER,
  full_bytes          NUMBER
);
/

CREATE OR REPLACE TYPE srdc_lob_usage_rec
  AS TABLE OF srdc_lob_usage_t;
/

CREATE OR REPLACE FUNCTION srdc_lob_usage(
  owner VARCHAR2,
  table_name VARCHAR2
)
RETURN srdc_lob_usage_rec PIPELINED
IS
  CURSOR lob_cur(v_owner VARCHAR2, v_table_name VARCHAR2) IS
    SELECT
      l.OWNER,
      l.SEGMENT_NAME,
      DECODE(sp.LOB_SUBPARTITION_NAME,
             NULL, decode(p.LOB_PARTITION_NAME,
                          NULL, NULL, p.LOB_PARTITION_NAME),
             sp.LOB_SUBPARTITION_NAME) partition_name,
      DECODE(sp.LOB_SUBPARTITION_NAME,
             NULL, decode(p.LOB_PARTITION_NAME,
                          NULL, 'LOB', 'LOB PARTITION'),
             'LOB SUBPARTITION') segment_type,
      l.SECUREFILE
    FROM DBA_LOBS l
    LEFT OUTER JOIN DBA_LOB_PARTITIONS p
      ON l.OWNER=p.TABLE_OWNER
      AND l.TABLE_NAME=p.TABLE_NAME
      AND l.COLUMN_NAME=p.COLUMN_NAME
      AND l.SEGMENT_NAME=p.LOB_NAME
    LEFT OUTER JOIN DBA_LOB_SUBPARTITIONS sp
      ON p.TABLE_OWNER=sp.TABLE_OWNER
      AND p.TABLE_NAME=sp.TABLE_NAME
      AND p.COLUMN_NAME=sp.COLUMN_NAME
      AND p.LOB_NAME=sp.LOB_NAME
      AND p.LOB_PARTITION_NAME=sp.LOB_PARTITION_NAME
    WHERE l.OWNER=UPPER(v_owner) and l.TABLE_NAME=UPPER(v_table_name)
    ORDER BY
      l.TABLE_NAME,
      l.COLUMN_NAME,
      l.SEGMENT_NAME,
      p.PARTITION_POSITION,
      sp.SUBPARTITION_POSITION;

  lob_rec sys.DBA_LOBS%ROWTYPE;

  -- Securefile and Basicfile
  segment_owner       VARCHAR2(256);
  segment_name        VARCHAR2(256);
  segment_type        VARCHAR2(256);
  partition_name      VARCHAR2(256);
  -- Securefile
  segment_size_blocks NUMBER;
  segment_size_bytes  NUMBER;
  used_blocks         NUMBER;
  used_bytes          NUMBER;
  expired_blocks      NUMBER;
  expired_bytes       NUMBER;
  unexpired_blocks    NUMBER;
  unexpired_bytes     NUMBER;
  -- Basicfile
  unformatted_blocks  NUMBER;
  unformatted_bytes   NUMBER;
  fs1_blocks          NUMBER;
  fs1_bytes           NUMBER;
  fs2_blocks          NUMBER;
  fs2_bytes           NUMBER;
  fs3_blocks          NUMBER;
  fs3_bytes           NUMBER;
  fs4_blocks          NUMBER;
  fs4_bytes           NUMBER;
  full_blocks         NUMBER;
  full_bytes          NUMBER;
BEGIN
  FOR lob_rec IN lob_cur(owner,table_name) LOOP
    /* for debug */
    dbms_output.put_line('lob_rec.owner          : ' || lob_rec.owner);
    dbms_output.put_line('lob_rec.segment_name   : ' || lob_rec.segment_name);
    dbms_output.put_line('lob_rec.segment_type   : ' || lob_rec.segment_type);
    dbms_output.put_line('lob_rec.partition_name : ' || lob_rec.partition_name);
    dbms_output.put_line('lob_rec.securefile     : ' || lob_rec.securefile);

    -- Securefile and Basicfile
    segment_owner       := lob_rec.owner;
    segment_name        := lob_rec.segment_name;
    segment_type        := lob_rec.segment_type;
    partition_name      := lob_rec.partition_name;
    -- Securefile
    segment_size_blocks := NULL;
    segment_size_bytes  := NULL;
    used_blocks         := NULL;
    used_bytes          := NULL;
    expired_blocks      := NULL;
    expired_bytes       := NULL;
    unexpired_blocks    := NULL;
    unexpired_bytes     := NULL;
    -- Basicfile
    unformatted_blocks  := NULL;
    unformatted_bytes   := NULL;
    fs1_blocks          := NULL;
    fs1_bytes           := NULL;
    fs2_blocks          := NULL;
    fs2_bytes           := NULL;
    fs3_blocks          := NULL;
    fs3_bytes           := NULL;
    fs4_blocks          := NULL;
    fs4_bytes           := NULL;
    full_blocks         := NULL;
    full_bytes          := NULL;

    BEGIN
      IF lob_rec.securefile = 'YES' THEN
        -- Securefile
        DBMS_SPACE.SPACE_USAGE(
          segment_owner       => segment_owner,
          segment_name        => segment_name,
          segment_type        => segment_type,
          segment_size_blocks => segment_size_blocks,
          segment_size_bytes  => segment_size_bytes,
          used_blocks         => used_blocks,
          used_bytes          => used_bytes,
          expired_blocks      => expired_blocks,
          expired_bytes       => expired_bytes,
          unexpired_blocks    => unexpired_blocks,
          unexpired_bytes     => unexpired_bytes,
          partition_name      => partition_name
        );
      ELSE
        -- Basicfile
        DBMS_SPACE.SPACE_USAGE(
          segment_owner       => segment_owner,
          segment_name        => segment_name,
          segment_type        => segment_type,
          unformatted_blocks  => unformatted_blocks,
          unformatted_bytes   => unformatted_bytes,
          fs1_blocks          => fs1_blocks,
          fs1_bytes           => fs1_bytes,
          fs2_blocks          => fs2_blocks,
          fs2_bytes           => fs2_bytes,
          fs3_blocks          => fs3_blocks,
          fs3_bytes           => fs3_bytes,
          fs4_blocks          => fs4_blocks,
          fs4_bytes           => fs4_bytes,
          full_blocks         => full_blocks,
          full_bytes          => full_bytes,
          partition_name      => partition_name
        );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        /* for debug */
        dbms_output.put_line('  SRDC:' || sqlerrm);
    END;

    PIPE ROW(
      srdc_lob_usage_t(
        segment_owner,
        segment_name,
        segment_type,
        partition_name,
        segment_size_blocks,
        segment_size_bytes,
        used_blocks,
        used_bytes,
        expired_blocks,
        expired_bytes,
        unexpired_blocks,
        unexpired_bytes,
        unformatted_blocks,
        unformatted_bytes,
        fs1_blocks,
        fs1_bytes,
        fs2_blocks,
        fs2_bytes,
        fs3_blocks,
        fs3_bytes,
        fs4_blocks,
        fs4_bytes,
        full_blocks,
        full_bytes
      )
    );
  END LOOP;
  RETURN;
END;
/
--show error

set serveroutput off
set echo on
select * from table(srdc_lob_usage('&v_owner','&v_table_name'));
set echo off
set serveroutput off
-- Note: The basicfile information is not displayed properly.

set echo off
prompt
prompt ============================================================================================
prompt            +++++++++++++++++++++End of SRDC Data Collection+++++++++++++ 
prompt ============================================================================================
prompt
spool off

set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT======================================================================================================================================
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem======================================================================================================================================
@?/rdbms/admin/sqlsessend.sql
exit;
