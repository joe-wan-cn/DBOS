Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/db_feature_usage.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem db_feature_usage.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      db_feature_usage.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/db_feature_usage.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     05/08/18 - Gather information on DB feature usage
Rem    bburton     05/08/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
set echo off;
set feedback off;
set heading off;
set pagesize 5000;
set long 8000;
set linesize 32767;
set trimspool on;
column myout format a9000
select '{"dbid":"'||dbid||'","name":"'||name||'","version":"'||version||'","detected_usages":"'||detected_usages||
       '","total_samples":"'||total_samples||'","currently_used":"'||currently_used||'","first_usage_date":"'||first_usage_date||
       '","last_usage_date":"'||last_usage_date||'","aux_count":"'||aux_count||'","feature_info":"'||feature_info||
       '","last_sample_date":"'||last_sample_date||'","last_sample_period":"'||last_sample_period||'","sample_interval":"'||sample_interval||
       '","description":"'||description||'"}' myout from dba_feature_usage_statistics;
@?/rdbms/admin/sqlsessend.sql
