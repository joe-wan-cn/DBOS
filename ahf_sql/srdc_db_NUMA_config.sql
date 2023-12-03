Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_NUMA_config.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_NUMA_config.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_NUMA_config.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_NUMA_config.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     07/14/17 - Gather information about DB Nume configuration
Rem    bburton     07/14/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool DB_NUMA_CONFIG.txt
select a.inst_id, a.ksppinm "Parameter",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value"
from x$ksppi a, x$ksppcv b, x$ksppsv c
where a.indx = b.indx and a.indx = c.indx
and a.inst_id=b.inst_id and b.inst_id=c.inst_id
and a.ksppinm in ('_enable_NUMA_support', '_enable_NUMA_optimization') order by 2;
spool off;
@?/rdbms/admin/sqlsessend.sql
 
