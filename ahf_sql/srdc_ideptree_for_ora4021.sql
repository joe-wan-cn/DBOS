Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_ideptree_for_ora4021.sql /main/1 2020/04/30 05:45:22 xiaodowu Exp $
Rem
Rem srdc_ideptree_for_ora4021.sql
Rem
Rem Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_ideptree_for_ora4021.sql
Rem
Rem    DESCRIPTION
Rem      Called by ora4021 SRDC
Rem
Rem    NOTES
Rem      None
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_ideptree_for_ora4021.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    04/28/20 - Called by ora4021 SRDC
Rem    xiaodowu    04/28/20 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
select /*+ ordered */ w1.sid waiting_session, h1.sid holding_session, w.kgllktype lock_or_pin, w.kgllkhdl address, decode(h.kgllkmod, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', 'Unknown') mode_held, decode(w.kgllkreq, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', 'Unknown') mode_requested
from dba_kgllock w, dba_kgllock h, v$session w1, v$session h1
where
(((h.kgllkmod != 0) and (h.kgllkmod != 1)
and ((h.kgllkreq = 0) or (h.kgllkreq = 1)))
and
(((w.kgllkmod = 0) or (w.kgllkmod= 1))
and ((w.kgllkreq != 0) and (w.kgllkreq != 1))))
and w.kgllktype = h.kgllktype
and w.kgllkhdl = h.kgllkhdl
and w.kgllkuse = w1.saddr
and h.kgllkuse = h1.saddr
/
select distinct to_name object_locked 
from v$object_dependency 
where to_address in ( 
 select w.kgllkhdl address 
 from dba_kgllock w, dba_kgllock h, v$session w1, v$session h1 
 where ((h.kgllkmod != 0) 
 and (h.kgllkmod != 1) 
 and ((h.kgllkreq = 0) 
 or (h.kgllkreq = 1))) 
 and 
 (((w.kgllkmod = 0) 
  or (w.kgllkmod= 1)) 
  and ((w.kgllkreq != 0) 
  and (w.kgllkreq != 1))) 
 and w.kgllktype = h.kgllktype 
 and w.kgllkhdl = h.kgllkhdl 
 and w.kgllkuse = w1.saddr 
 and h.kgllkuse = h1.saddr)
/

@?/rdbms/admin/sqlsessend.sql
 
