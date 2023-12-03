Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_extrace_aq_spid.sql /main/1 2020/02/14 06:21:55 xiaodowu Exp $
Rem
Rem srdc_extrace_aq_spid.sql
Rem
Rem Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_extrace_aq_spid.sql
Rem
Rem    DESCRIPTION
Rem      Called by SRDC dbemon
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_extrace_aq_spid.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    02/12/20 - Used by SRDC dbemon
Rem    xiaodowu    02/12/20 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
set echo off;
set heading off;
set feedback off;
select spid||'|'|| pname from v$process where pname like 'E%'
union
select spid||'|'|| pname from v$process where pname='AQPC'
union
select spid||'|'|| pname from v$process where pname like 'Q%';
@?/rdbms/admin/sqlsessend.sql
 
