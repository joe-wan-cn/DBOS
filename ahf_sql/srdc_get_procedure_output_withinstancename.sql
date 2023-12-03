Rem
Rem srdc_get_procedure_output_withinstancename.sql
Rem
Rem Copyright (c) 2022, Oracle and/or its affiliates. 
Rem
Rem    NAME
Rem      srdc_get_procedure_output_withinstancename.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_procedure_output_withinstancename.sql
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
SET TAB OFF
SET PAGESIZE 100
SET SERVEROUTPUT ON SIZE 1000000 
SET VERIFY OFF
SET LINESIZE 150
SET PAGESIZE 100
SET LONG 5000

col step_id for 99999999
col step_name for a32
col stat      for 9999
COLUMN OUTPUT FORMAT a150
COLUMN ERROR  FORMAT a150
define instname="&1"

DECLARE
   buffer    	 	       CLOB;
   amt        		       BINARY_INTEGER := 16384;
   offset     		       INTEGER     := 1;
   l_length   		       NUMBER;
   tobe_ignored_steps CONSTANT VARCHAR2(300) := 'createStageDirectory,setupAndTransfer,transferComponent,transferDirective,setParams,stageOmsFileEntry,cleanUpSetup,StepSetCleanComponent,cleanDirective,checkOperModeOms,createSrcPathsForNonHost,cleanComponent,StepSetTxrComponent,createSrcPathsCheck,prepareSource,prepareDestination';

   PROCEDURE dump_inst_data 
   IS
      CURSOR job_cur
      IS
	SELECT
       		job.job_name         AS Job_Name,
       		jobsteps.step_name   AS Step_Name,
       		jobsteps.step_status AS Step_Status,
       		jobsteps.start_time  AS Start_Time,
       		jobsteps.end_time    AS End_Time,
			jobsteps.timezone_region AS Timezone_Region,
       		o.output             AS Output,
       		e.output             AS Error
	FROM   
		MGMT_JOB instances,
       	       	MGMT_JOB_EXEC_SUMMARY dpexecs,
       	       	EM_PAF_STATES states,
               	MGMT_JOB job,
               	MGMT_JOB_EXEC_SUMMARY jobexecs,
               	MGMT_JOB_HISTORY jobsteps,
               	MGMT_JOB_OUTPUT o,
               	MGMT_JOB_OUTPUT e
	WHERE  
		instances.job_name = '&instname' AND
		instances.job_id = dpexecs.job_id    AND
		states.execution_guid = dpexecs.execution_id AND
    		job.job_id = jobexecs.job_id 	     AND
		jobexecs.execution_id = states.exec_id AND    
		jobsteps.execution_id = jobexecs.execution_id AND    
		(jobsteps.error_id IS NOT NULL OR jobsteps.output_id IS NOT NULL)  AND   
	 	o.output_id (+) = jobsteps.output_id  AND    
		e.output_id (+) = jobsteps.error_id
	ORDER BY 
		jobexecs.start_time, jobsteps.start_time, jobsteps.end_time;
BEGIN
   FOR job_rec IN job_cur
   LOOP
	IF INSTR(',' || tobe_ignored_steps || ',',',' || job_rec.Step_Name || ',') > 0 THEN
		goto FOO; 
	END IF;
	DBMS_OUTPUT.PUT_LINE('#############################################################');
	DBMS_OUTPUT.PUT_LINE('Job Name: ' || job_rec.Job_Name);
        DBMS_OUTPUT.PUT_LINE('Step Name: ' || job_rec.Step_Name);
	IF (job_rec.Step_Status = 4) THEN
        	DBMS_OUTPUT.PUT_LINE('Step Status: Failed');
	ELSIF (job_rec.Step_Status = 5) THEN
		DBMS_OUTPUT.PUT_LINE('Step Status: Succeeded');
	ELSIF (job_rec.Step_Status = 3) THEN
		DBMS_OUTPUT.PUT_LINE('Step Status: Error');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Step Status: ' || job_rec.Step_Status );
	END IF;
		DBMS_OUTPUT.PUT_LINE('Start Time: ' || to_char(from_tz(cast (job_rec.Start_Time as timestamp), 'UTC') at time zone job_rec.Timezone_Region, 'dd/mm/yyyy hh24:mi:ss'));
        DBMS_OUTPUT.PUT_LINE('Start Time: ' || to_char(from_tz(cast (job_rec.End_Time as timestamp), 'UTC') at time zone job_rec.Timezone_Region, 'dd/mm/yyyy hh24:mi:ss'));

	l_length := nvl(dbms_lob.getlength(job_rec.Output),0);
	IF (l_length > 0) THEN
		DBMS_OUTPUT.PUT_LINE('Job OutPut: ' );
		offset := 1;
		amt := 32670;
		while (offset < l_length)
		LOOP
			DBMS_LOB.READ(job_rec.OUTPUT,amt,offset,buffer);
			DBMS_OUTPUT.PUT_LINE(buffer);
			offset := offset + amt;
		END LOOP;
	END IF;

	l_length := nvl(dbms_lob.getlength(job_rec.Error),0);
	IF (l_length > 0) THEN
		DBMS_OUTPUT.PUT_LINE('Job Error: ' );
		offset := 1;
        	amt := 32670;
        	while (offset < l_length)
        	LOOP
                	DBMS_LOB.READ(job_rec.Error,amt,offset,buffer);
                	DBMS_OUTPUT.PUT_LINE(buffer);
                	offset := offset + amt;
        	END LOOP;
	END IF;

        DBMS_OUTPUT.PUT_LINE('#############################################################');
	DBMS_OUTPUT.PUT_LINE('								   ');
	<<FOO>> null; 
   END LOOP;
END;

BEGIN
	dump_inst_data;
END;
/


