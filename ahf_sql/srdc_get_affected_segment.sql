Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_affected_segment.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_get_affected_segment.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_get_affected_segment.sql 
Rem
Rem    DESCRIPTION
Rem      Query for corrupted segments
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_affected_segment.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/28/18 - Called by srdc_ora1578.xml
Rem    xiaodowu    03/28/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool nologging.log

set echo on

select systimestamp
from dual;

select FILE#,  BLOCK#,  BLOCKS,  to_char(CORRUPTION_CHANGE#, '999999999999999') CORRUPTION_CHANGE#,  CORRUPTION_TYPE   
from V$DATABASE_BLOCK_CORRUPTION
where CORRUPTION_TYPE in ('LOGICAL','NOLOGGING');

set pagesize 2000
set linesize 250

SELECT e.owner, e.segment_type, e.segment_name, e.partition_name, c.file#
     , greatest(e.block_id, c.block#) corr_start_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1)
       - greatest(e.block_id, c.block#) + 1 blocks_corrupted
     , null description
  FROM dba_extents e, v$database_block_corruption c
 WHERE e.file_id = c.file#
   AND e.block_id <= c.block# + c.blocks - 1
   AND e.block_id + e.blocks - 1 >= c.block#
   AND c.corruption_type in ('LOGICAL','NOLOGGING')
UNION
SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
     , greatest(f.block_id, c.block#) corr_start_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
       - greatest(f.block_id, c.block#) + 1 blocks_corrupted
     , 'Free Block' description
  FROM dba_free_space f, v$database_block_corruption c
 WHERE f.file_id = c.file#
   AND f.block_id <= c.block# + c.blocks - 1
   AND f.block_id + f.blocks - 1 >= c.block#
   AND c.corruption_type in ('LOGICAL','NOLOGGING')
order by file#, corr_start_block#;

spool off

@?/rdbms/admin/sqlsessend.sql
