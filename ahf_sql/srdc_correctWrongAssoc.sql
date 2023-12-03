Rem      srdc_correctWrongAssoc.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_correctWrongAssoc.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    manuegar    03/02/22 - Created
Rem

SET ECHO OFF
SET FEEDBACK OFF
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET PAGESIZE 100
SET SERVEROUTPUT ON
SET VERIFY OFF
SET LINESIZE 150
SET PAGESIZE 100
SET LONG 5000
define targetName="&1"
define correct="&2"
DECLARE
  
  ptarget_name VARCHAR2(200) := '&targetName';
  pcorrect_relationship VARCHAR2(3) := '&correct';
  p_change_list SYSMAN.GC$DERIV_ASSOC_CHANGE_LIST;
  p_is_assoc_deleted_out BOOLEAN;
  p_old_oh_guid VARCHAR(200);
  

   PROCEDURE recreate_fix_assoc 
   IS
      CURSOR job_cur
      IS
      WITH targs AS (
          SELECT tgts.TARGET_GUID, tgts.TARGET_NAME, tgts.HOST_NAME, prop.PROPERTY_NAME, prop.PROPERTY_VALUE, tgts.TARGET_TYPE 
          FROM MGMT_TARGETS tgts JOIN MGMT$TARGET_PROPERTIES prop ON tgts.TARGET_GUID = prop.TARGET_GUID
          WHERE tgts.TARGET_TYPE in ('oracle_database', 'oracle_listener', 'cluster', 'osm_instance', 'has', 'rac_database','osm_cluster','osm_proxy')
          AND tgts.TARGET_NAME like '%' || ptarget_name || '%' 
          AND prop.PROPERTY_NAME LIKE 'OracleHome' 
          AND  tgts.TARGET_GUID NOT IN ( 
            SELECT DISTINCT ASSOC.SOURCE_ME_GUID FROM GC$ASSOC_INSTANCES ASSOC WHERE ASSOC_TYPE = 'installed_at'
          )
        )SELECT DISTINCT targs.TARGET_NAME as targ , targs.TARGET_GUID as targguid, prop.TARGET_NAME as oracle_home , prop.TARGET_GUID as oracle_home_guid, prop.PROPERTY_NAME, targs.TARGET_TYPE as tgtype
         FROM targs JOIN MGMT_TARGETS tgt ON targs.HOST_NAME = tgt.HOST_NAME AND tgt.TARGET_TYPE = 'oracle_home'   
         JOIN MGMT$TARGET_PROPERTIES prop ON prop.TARGET_GUID = tgt.TARGET_GUID 
         WHERE prop.PROPERTY_NAME = 'INSTALL_LOCATION'
         AND UPPER(RTRIM(prop.PROPERTY_VALUE,'\/')) = UPPER(RTRIM(targs.PROPERTY_VALUE,'\/'));
        
        
      CURSOR target_cur
      IS
        SELECT T.HOST_NAME HOST, T.TARGET_NAME TARGET, T.TARGET_TYPE, T.TARGET_GUID GUID , A.ASSOC_TARGET_NAME ORACLE_HOME, P.PROPERTY_VALUE TARGET_OH_LOCATION , P1.PROPERTY_VALUE OH_CONFIGURED, P.TARGET_GUID OH_GUID
        FROM SYSMAN.MGMT_TARGETS T 
          LEFT JOIN SYSMAN.MGMT$TARGET_ASSOCIATIONS A ON A.SOURCE_TARGET_NAME = T.TARGET_NAME AND A.ASSOCIATION_TYPE = 'installed_at' 
          LEFT JOIN SYSMAN.MGMT$TARGET_PROPERTIES P ON P.TARGET_NAME = A.ASSOC_TARGET_NAME AND P.PROPERTY_NAME = 'INSTALL_LOCATION'
          JOIN SYSMAN.MGMT$TARGET_PROPERTIES P1 ON P1.TARGET_NAME = T.TARGET_NAME AND P1.PROPERTY_NAME = 'OracleHome'
        WHERE T.TARGET_TYPE in ('oracle_database', 'oracle_listener', 'cluster', 'osm_instance', 'has', 'rac_database','osm_cluster','osm_proxy')
          AND (A.ASSOC_TARGET_TYPE = 'oracle_home' OR A.ASSOC_TARGET_TYPE IS NULL)
          AND T.TARGET_NAME like '%' || ptarget_name || '%'  
          AND (UPPER(RTRIM(P.PROPERTY_VALUE,'\/')) !=  UPPER(RTRIM(P1.PROPERTY_VALUE,'\/')) OR P.TARGET_GUID IS NULL);
        
    BEGIN
       FOR job_rec IN job_cur
       LOOP
      
        DBMS_OUTPUT.PUT_LINE('#############################################################');
        DBMS_OUTPUT.PUT_LINE('Source Target Name: ' || job_rec.targ);
		DBMS_OUTPUT.PUT_LINE('Source Target Type: ' || job_rec.tgtype);
        DBMS_OUTPUT.PUT_LINE('Source Target GUID: ' || job_rec.targguid);
        DBMS_OUTPUT.PUT_LINE('Target Target Name: ' || job_rec.oracle_home);
        DBMS_OUTPUT.PUT_LINE('Target Target GUID: ' || job_rec.oracle_home_guid);
    
        IF(pcorrect_relationship='Yes') THEN
          DBMS_OUTPUT.PUT_LINE('Recreating EM_ASSOC_NG.CREATE_ASSOC_INSTANCE(p_assoc_type => ''installed_at'', p_source_target_name => ' || job_rec.targ || ', p_source_target_type => ' || job_rec.tgtype || ' , p_dest_target_name => ' || job_rec.oracle_home || ',  p_dest_target_type => ''oracle_home'', p_ignore_dup => 1)');
          EM_ASSOC_NG.CREATE_ASSOC_INSTANCE(p_assoc_type => 'installed_at', p_source_target_name => job_rec.targ, p_source_target_type => job_rec.tgtype , p_dest_target_name => job_rec.oracle_home,  p_dest_target_type => 'oracle_home', p_ignore_dup => 1);
        END IF;
    
        DBMS_OUTPUT.PUT_LINE('#############################################################');
        DBMS_OUTPUT.PUT_LINE('								   ');
    
       END LOOP;
       
       FOR targ_rec IN target_cur
        LOOP
          DBMS_OUTPUT.PUT_LINE('#############################################################');
            DBMS_OUTPUT.PUT_LINE('Source Target Name: ' || targ_rec.target);
            DBMS_OUTPUT.PUT_LINE('Source Target GUID: ' || targ_rec.guid);
			DBMS_OUTPUT.PUT_LINE('Source Target Type: ' || targ_rec.TARGET_TYPE);
            DBMS_OUTPUT.PUT_LINE('OH Target Name: ' || targ_rec.oracle_home);
            DBMS_OUTPUT.PUT_LINE('OH Target GUID: ' || targ_rec.oh_guid);
            DBMS_OUTPUT.PUT_LINE('OH Location: ' || targ_rec.TARGET_OH_LOCATION);
            DBMS_OUTPUT.PUT_LINE('OH Configured: ' || targ_rec.OH_CONFIGURED);
            
            IF (pcorrect_relationship = 'Yes') THEN
              DBMS_OUTPUT.PUT_LINE('Correcting association');
              SYSMAN.GC$ECM_CONFIG.run_assoc_deriv_rule(targ_rec.guid, 'target_installed_at_oracle_home','S',p_change_list);
              DBMS_OUTPUT.PUT_LINE('Removing any association with ' || targ_rec.target || ' and ' || targ_rec.oracle_home );
              DBMS_OUTPUT.PUT_LINE('Removing any association with ' || targ_rec.guid || ' and ' || targ_rec.oh_guid );
              SYSMAN.EM_ASSOC_NG.delete_assoc_instance('installed_at',targ_rec.guid,targ_rec.oh_guid);
            END IF;
            DBMS_OUTPUT.PUT_LINE('#############################################################');
            DBMS_OUTPUT.PUT_LINE('								   ');
        
        END LOOP;
    END;

BEGIN
  recreate_fix_assoc;
  COMMIT;
EXCEPTION
   WHEN no_data_found THEN 
      DBMS_OUTPUT.PUT_LINE('No such targets!!!'); 
   WHEN others THEN 
      DBMS_OUTPUT.PUT_LINE('Error rolling back!'); 
      ROLLBACK;  
    
END;
/

