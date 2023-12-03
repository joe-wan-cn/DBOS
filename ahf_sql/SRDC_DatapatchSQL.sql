Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/SRDC_DatapatchSQL.sql /main/1 2018/12/10 10:41:39 bburton Exp $
Rem
Rem SRDC_DatapatchSQL.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      SRDC_DatapatchSQL.sql
Rem
Rem    DESCRIPTION
Rem      Called by SRDC datapatch collection
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/SRDC_DatapatchSQL.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    11/06/18 - Called by SRDC datapatch collection
Rem    xiaodowu    11/06/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool SRDC_DatapatchSQL.log
            select dbms_sqlpatch.verify_queryable_inventory from dual;
            select * from OPATCH_XML_INV ;
            select owner, directory_name, directory_path from dba_directories where directory_name like 'OPATCH%';
            SELECT COMP_ID,comp_name, status, version as version from dba_server_registry where status != 'VALID';
            select object_name, owner, object_type from dba_objects where status != 'VALID' order by owner;
            set serverout on
            exec dbms_qopatch.get_sqlpatch_status;
            set lines 3000
            select BUNDLE_SERIES B_SER,BUNDLE_ID B_ID,PATCH_ID,FLAGS,ACTION,STATUS,ACTION_TIME,DESCRIPTION from dba_registry_sqlpatch order by ACTION_TIME;
            select job_name,state, start_date from dba_scheduler_jobs where job_name like 'LOAD_OPATCH%';
            set heading off long 50000
            select dbms_metadata.get_ddl('TABLE','OPATCH_XML_INV','SYS') from dual;
            spool off    
@?/rdbms/admin/sqlsessend.sql
