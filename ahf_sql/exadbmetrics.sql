Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/exadbmetrics.sql /main/5 2023/09/19 02:39:44 bvongray Exp $
Rem
Rem exadbmetrics.sql
Rem
Rem Copyright (c) 2022, 2023, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      exadbmetrics.sql - collects exadatata DB Metrics
Rem
Rem    DESCRIPTION
Rem     Author: tmanfe
Rem     Exadata metrics tables:
Rem
Rem     docs.oracle.com/en/engineered-systems/exadata-database-machine/sagug/exadata-db-dictionary-views.html#GUID-C7AA7FF7-EEAF-4F7D-9D22-01FE7516F7D4
Rem
Rem     * DBA_HIST_CELL_CONFIG_DETAIL:  contains IORM plan
Rem     * DBA_HIST_CELL_DISK_SUMMARY:   contains info about disk avg utilization
Rem     * DBA_HIST_CELL_GLOBAL_SUMMARY: contains info about CPU usage
Rem
Rem     select metric_name from DBA_HIST_CELL_METRIC_DESC where metric_name like '%usa%';
Rem     METRIC_NAME
Rem     -----------------------
Rem     CPU usage
Rem     User CPU usage
Rem     System CPU usage
Rem
Rem    NOTES
Rem     Note: a disk with a name starting with PM is a pmem (persistente memory) disk that should not be considerd for storage-IO stat
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bvongray    09/12/23 - Bug 35731357
Rem    bvongray    05/30/23 - Bug 35425412
Rem    tmanfe      05/24/23 - Handling ORA-01403 NO_DATA_FOUND exceptions
Rem    tmanfe      05/24/23 - Selecting wrong data for cell single block physical read from flash
Rem    tmanfe      04/13/22 - Compatibility with rdbms 19.5 and above: 'cell single block physical read' event no longer includes
Rem                           I/O from Smart Flash Cache or I/O using RDMA. Need to consider event subcategories specific
Rem			      to flash cache, RDMA and pmem cache
Rem    tmanfe      03/13/22 - Check the db-role is primary. If not exit
Rem    tmanfe      12/11/22 - Fix for bug 34871974 - EXADBMETRICS.SQL FAILS WITH ORA-01843 WHEN NLS_TERRITORY IS NOT AMERICA
Rem    bvongray    06/23/22 - Created
Rem
@@?/rdbms/admin/sqlsessstart.sql
set serveroutput on format wrapped;
set lines 100;
set termout off;
set echo off;
set verify off;
set feedback off;
spool exadbmetrics.txt;

declare
  fromArg       varchar2(25);
  toArg         varchar2(25);
  dbrole        varchar2(16);
  theDBID       number;
  theCONID      number;
  theInstance   number;
  theDbVersion  varchar2(100):='';
  bSnapID       integer;
  begTStamp     timestamp;
  bTimeWaitedMS number;
  eSnapID       integer;
  endTStamp     timestamp;
  snapInterval  interval day to second;
  snapIntrSec   number;
  diff          number;
  tStamp        timestamp;
  eTimeWaitedMS number;
  bTotalWaits   number;
  eTotalWaits   number;
  totWaitTimeMS number;
  totWaits      number;
  avgMS         number;
  snapid        integer;
  cpuUsage      number;
  avgCpuUsage   number;
  diskUsage     number;
  avgDiskUsage  number;
  numSamples    integer;

begin

fromArg := replace('&1', 'T', ' ');
toArg   := replace('&2', 'T', ' ');
begTStamp := to_timestamp(fromArg, 'yyyy-mm-dd hh24:mi:ss');
endTStamp := to_timestamp(toArg,   'yyyy-mm-dd hh24:mi:ss');


-- Check if in cdb$root
theDBID  := sys_context('userenv','dbid');
theCONID := sys_context('userenv','con_dbid');

if theDBID != theCONID then

  dbms_output.put_line('  Error: sorry this script must be executed from cdb$root');

else

  -- In cdb$root

  -- Check if role is primary
  select v$database.database_role
  into dbrole
  from v$database;

  if dbrole != 'PRIMARY' then

    dbms_output.put_line('  Error: sorry this script must be executed against a primary database');

  else

    $IF DBMS_DB_VERSION.VERSION >= 19
    $THEN
    select version_full into theDbVersion from product_component_version;
    dbms_output.put_line('Info: database version ' || theDbVersion);
    $END

    select instance_number into theInstance from v$instance;

    -- Selecting snaphosts from timestamps
    $IF DBMS_DB_VERSION.VERSION < 18 $THEN
      $ERROR 'Error: Oracle Databse 18 or higher required.' $END
    $ELSIF DBMS_DB_VERSION.VERSION < 19 $THEN
    select snap_interval into snapInterval from dba_hist_wr_control;
    $ELSE
    -- version 19 and above
    select snap_interval into snapInterval from dba_hist_wr_control where src_dbname='CDB$ROOT';
    $END

    snapIntrSec := (  extract( second from snapInterval )
                    + extract( minute from snapInterval ) * 60
                    + extract( hour   from snapInterval ) * 60 * 60
                    + extract( day    from snapInterval ) * 60 * 60 * 24);

    --dbms_output.put_line('snap_interval: ' || snapInterval);
    dbms_output.put_line('snapInterSec: ' || snapIntrSec);

    for snap_curs in ( select distinct snap_id, end_interval_time,
                   lead (snap_id,1) over (order by snap_id) as next_snapid
                   from dba_hist_snapshot
                   where end_interval_time >= begTStamp - snapInterval
                   and   end_interval_time <= endTStamp + snapInterval
                   and   instance_number = theInstance
                   and   con_id = '0'
                   order by snap_id)
    loop
      tStamp := to_timestamp(snap_curs.end_interval_time);
      dbms_output.put_line(snap_curs.snap_id || ' ' || to_char(tStamp, 'YYYY/MM/DD HH24:MI:SS'));
    end loop;

    -- Looking for the closest snapshot to begTStamp
    for snap_curs in ( select distinct snap_id, end_interval_time,
                   lead (snap_id,1) over (order by snap_id) as next_snapid
                   from dba_hist_snapshot
                   where end_interval_time >= begTStamp - snapInterval
                   and   end_interval_time <= endTStamp + snapInterval
                   and   instance_number = theInstance
                   and   con_id = '0'
                   order by snap_id)
    loop

      diff := (  extract( second from begTStamp - snap_curs.end_interval_time)
               + extract( minute from begTStamp - snap_curs.end_interval_time) * 60
               + extract( hour   from begTStamp - snap_curs.end_interval_time) * 60 * 60
               + extract( day    from begTStamp - snap_curs.end_interval_time) * 60 * 60 * 24);

      if diff < snapIntrSec/2 then

        bSnapID := snap_curs.snap_id;

      else

        -- If the first snaphost is not the closest to the beginning of the target period,
        -- it is the next one.
        bSnapID := snap_curs.next_snapid;

      end if;

      exit;

    end loop;

    -- Looking for the closest snapshot to endTStamp (so listing snapshots in descending order)
    for snap_curs in ( select distinct snap_id, end_interval_time,
                   lead (snap_id,1) over (order by snap_id desc) as next_snapid
                   from dba_hist_snapshot
                   where end_interval_time >= begTStamp - snapInterval
                   and   end_interval_time <= endTStamp + snapInterval
                   and   instance_number = theInstance
                   order by snap_id desc)
    loop

      diff := (  extract( second from snap_curs.end_interval_time - endTStamp)
               + extract( minute from snap_curs.end_interval_time - endTStamp) * 60
               + extract( hour   from snap_curs.end_interval_time - endTStamp) * 60 * 60
               + extract( day    from snap_curs.end_interval_time - endTStamp) * 60 * 60 * 24);

      if diff < snapIntrSec/2 then

        eSnapID := snap_curs.snap_id;

      else

        -- If the last snaphost is not the closest to the end of the target period,
        -- it is the previous one.
        eSnapID := snap_curs.next_snapid;

      end if;

      exit;

    end loop;


    if bSnapID = eSnapID then

     dbms_output.put_line('  Error: cannot find matching AWR snapshots because the target period is too small.');

    else

     dbms_output.put_line('From snapshot: ' || bSnapID || ' ; to snapshot: ' || eSnapID );

    end if;

    -- Collecting wait time for single block physical reads. Four events are considered:
    --  * cell single block physical read
    --  * cell single block physical read: flash cache
    --  * cell single block physical read: pmem cache
    --  * cell single block physical read: RMDA

    begin

    select time_waited_micro/1000, total_waits into bTimeWaitedMS, bTotalWaits 
    from dba_hist_system_event 
    where snap_id = bSnapID and instance_number = theInstance and event_name like '%cell single block physical read';

    select time_waited_micro/1000, total_waits into eTimeWaitedMS, eTotalWaits 
    from dba_hist_system_event 
    where snap_id = eSnapID and instance_number = theInstance and event_name like '%cell single block physical read';

    totWaits := eTotalWaits - bTotalWaits;

    if totWaits > 0 then

      totWaitTimeMS := (eTimeWaitedMS - bTimeWaitedMS);
      avgMS := round(totWaitTimeMS/totWaits,4);
  
      dbms_output.put_line('cellSglBlkPhysRead total wait time: ' || round(totWaitTimeMS/1000,0) || ' sec');
      dbms_output.put_line('cellSglBlkPhysRead total waits:     ' || totWaits);
      dbms_output.put_line('cellSglBlkPhysRead avg time:        ' || avgMS || ' millisec');

    else

      dbms_output.put_line('Info: no cellSglBlkPhysRead detected');

    end if;

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no cellSglBlkPhysRead detected');

    end;

    begin

    select time_waited_micro/1000, total_waits into bTimeWaitedMS, bTotalWaits
    from dba_hist_system_event
    where snap_id = bSnapID and instance_number = theInstance and event_name like '%cell single block physical read%flash%';

    select time_waited_micro/1000, total_waits into eTimeWaitedMS, eTotalWaits
    from dba_hist_system_event
    where snap_id = eSnapID and instance_number = theInstance and event_name like '%cell single block physical read%flash%';

    totWaits := eTotalWaits - bTotalWaits;

    if totWaits > 0 then

      totWaitTimeMS := (eTimeWaitedMS - bTimeWaitedMS);
      avgMS := round(totWaitTimeMS/totWaits,4);
  
      dbms_output.put_line('cellSglBlkPhysRead flash cache total wait time: ' || round(totWaitTimeMS/1000,0) || ' sec');
      dbms_output.put_line('cellSglBlkPhysRead flash cache total waits:     ' || totWaits);
      dbms_output.put_line('cellSglBlkPhysRead flash cache avg time:        ' || avgMS || ' millisec');

    else

      dbms_output.put_line('Info: no cellSglBlkPhysRead flash cache detected');

    end if;

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no cellSglBlkPhysRead flash cache detected');

    end;

    begin

    select time_waited_micro/1000, total_waits into bTimeWaitedMS, bTotalWaits
    from dba_hist_system_event
    where snap_id = bSnapID and instance_number = theInstance and event_name like '%cell single block physical read%pmem%';

    select time_waited_micro/1000, total_waits into eTimeWaitedMS, eTotalWaits
    from dba_hist_system_event
    where snap_id = eSnapID and instance_number = theInstance and event_name like '%cell single block physical read%pmem%';

    totWaits := eTotalWaits - bTotalWaits;

    if totWaits > 0 then

      totWaitTimeMS := (eTimeWaitedMS - bTimeWaitedMS);
      avgMS := round(totWaitTimeMS/totWaits,4);

      dbms_output.put_line('cellSglBlkPhysRead pmem cache total wait time: ' || round(totWaitTimeMS/1000,0) || ' sec');
      dbms_output.put_line('cellSglBlkPhysRead pmem cache total waits:     ' || totWaits);
      dbms_output.put_line('cellSglBlkPhysRead pmem cache avg time:        ' || avgMS || ' millisec');

    else

      dbms_output.put_line('Info: no cellSglBlkPhysRead pmem cache detected');

    end if;

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no cellSglBlkPhysRead pmem cache detected');

    end;

    begin

    select time_waited_micro/1000, total_waits into bTimeWaitedMS, bTotalWaits
    from dba_hist_system_event
    where snap_id = bSnapID and instance_number = theInstance and event_name like '%cell single block physical read%RDMA%';

    select time_waited_micro/1000, total_waits into eTimeWaitedMS, eTotalWaits
    from dba_hist_system_event
    where snap_id = eSnapID and instance_number = theInstance and event_name like '%cell single block physical read%RDMA%';

    totWaits := eTotalWaits - bTotalWaits;

    if totWaits > 0 then

      totWaitTimeMS := (eTimeWaitedMS - bTimeWaitedMS);
      avgMS := round(totWaitTimeMS/totWaits,4);

      dbms_output.put_line('cellSglBlkPhysRead RDMA total wait time: ' || round(totWaitTimeMS/1000,0) || ' sec');
      dbms_output.put_line('cellSglBlkPhysRead RDMA total waits:     ' || totWaits);
      dbms_output.put_line('cellSglBlkPhysRead RDMA avg time:        ' || avgMS || ' millisec');

    else

      dbms_output.put_line('Info: no cellSglBlkPhysRead RDMA detected');

    end if;

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no cellSglBlkPhysRead RDMA detected');

    end;

    -- Collecting storage cells CPU utilization (looping on cells)

    begin

    for r_cell in (select cell_hash, cell_name from DBA_HIST_CELL_NAME where snap_id = bSnapID and con_id = '0')
    loop

      -- Compute avg usage by looping on snaphosts between bSnapID and eSnapID

      numSamples := 0;

      for snapid in bSnapID+1 .. eSnapID
      loop

        select cpu.cpu_usage_avg into cpuUsage 
        from DBA_HIST_CELL_GLOBAL_SUMMARY cpu where cpu.snap_id = snapid and cpu.cell_hash = r_cell.cell_hash;

        if numSamples = 0 then

          avgCpuUsage := cpuUsage;

        else

          avgCpuUsage := ((avgCpuUsage * numSamples) + cpuUsage) / (numSamples + 1);

        end if;

        numSamples := numSamples + 1;

      end loop;

      dbms_output.put_line('cpu_usage ' || r_cell.cell_name || ': ' || round(avgCpuUsage,2) || ' %');

    end loop;

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no data for cpu utilization');

    end;

    -- Collecting storage cell disks utilization (looping on cells and disks)

    begin

    for r_cell in (select cell_hash, cell_name from DBA_HIST_CELL_NAME where snap_id = bSnapID)
    loop

      -- For each cell...

      for r_disk in (select disk_id, disk_name,disk from DBA_HIST_CELL_DISK_NAME where snap_id = bSnapID and r_cell.cell_hash = cell_hash and disk not like '%PMEM%')
      loop

        -- For each disk of the cell, compute avg usage by looping on snaphosts between bSnapID and eSnapID

        numSamples := 0;

        for snapid in bSnapID+1 .. eSnapID
        loop

          select disk_utilization_avg into diskUsage
          from DBA_HIST_CELL_DISK_SUMMARY disk where r_disk.disk_id = disk.disk_id and snapid = disk.snap_id;

          if numSamples = 0 then
    
            avgDiskUsage := diskUsage;
    
          else
    
            avgDiskUsage := ((avgDiskUsage * numSamples) + diskUsage) / (numSamples + 1);
    
          end if;
    
          numSamples := numSamples + 1;

        end loop; -- on snapshots

        dbms_output.put_line('disk_usage ' || r_cell.cell_name || ' ' || r_disk.disk_name || ' ' || r_disk.disk || ': '|| round(avgDiskUsage,2) || ' %');

      end loop; -- on disks

    end loop; -- on cells

    exception
        when NO_DATA_FOUND then
          dbms_output.put_line('Info: no data for disk utilization');

    end;


  end if; -- on dbrole != PRIMARY

end if;  -- theDBID != theCONID

end;
/
exit 0
@?/rdbms/admin/sqlsessend.sql
 
