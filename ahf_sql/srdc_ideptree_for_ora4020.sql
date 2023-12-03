Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_ideptree_for_ora4020.sql /main/1 2020/09/15 00:09:16 dtayade Exp $
Rem
Rem srdc_ideptree_for_ora4020.sql
Rem
Rem Copyright (c) 2020, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_ideptree_for_ora4020.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      Called by ora4020 SRDC
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_ideptree_for_ora4020.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    dtayade     08/18/20 - Called by ora4020 SRDC
Rem    dtayade     08/18/20 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
column "dependent name" format a20 ;
column "dependent owner" format a15;
column "parent owner" format a15;

SELECT d_obj#,
       doa.object_name "dependant name",
       doa.owner "dependant owner",
       doa.status "dep status",
       p_obj#,
       dob.object_name "parent name",
       dob.owner "parent owner"
FROM dba_objects doa,
     dba_objects dob,
     dependency$ dp
WHERE (dp.d_obj#, dp.p_obj#) IN (SELECT dpb.p_obj#, dpb.d_obj#
                                 FROM dependency$ dpb)
AND dp.d_obj#=doa.object_id
AND dp.p_obj#=dob.object_id
AND dob.status = 'INVALID'
/

ALTER Session Set NLS_Date_Format ="DD-MON-YYYY HH24:MI:SS"
/

SELECT    Owner,
          Object_Type,
          Last_DDL_Time,
          Count(*)
FROM DBA_Objects
WHERE Last_DDL_Time > sysdate -2
GROUP BY Owner, Object_Type, Last_DDL_Time
/

SELECT  Owner,
        Object_Type,
        Object_Name    
FROM DBA_Objects
WHERE Status='INVALID'
/
@?/rdbms/admin/sqlsessend.sql
 
