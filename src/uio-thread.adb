with Pace.Log;

package body Uio.Thread is

   procedure Initialize (Resource : in out Lock) is
      Id : Ati.Task_Id;
      use type Ati.Task_Id;
   begin
      if Resource.M.Safe then
         Id := Ati.Current_Task;
         Resource.M.Safe_Wait (Id);
         if Id = Ati.Null_Task_Id then
            Resource.Release := False;
         end if;
      else
         Id := Ati.Null_Task_Id;
         Resource.M.Wait (Id);
      end if;
   end Initialize;

   procedure Finalize (Resource : in out Lock) is
   begin
      if Resource.Release then
         Resource.M.Release;
      else
         Pace.Log.Put_Line ("Nested exit from locked thread. ");
         --  Model.Get_Agent_Id);
      end if;
   end Finalize;

   protected body Mutex is
      entry Wait (Id : in out Ati.Task_Id) when not Claimed is
      begin
         Current := Id;
         Claimed := True;
      end Wait;

      procedure Release is
      begin
         Current := Ati.Null_Task_Id;
         Claimed := False;
      end Release;

      entry Safe_Wait (Id : in out Ati.Task_Id) when True is
         use type Ati.Task_Id;
      begin
         if Id = Current then
            Id := Ati.Null_Task_Id;
         else
            requeue Wait;
         end if;
      end Safe_Wait;
   end Mutex;

------------------------------------------------------------------------------
-- $id: uio-thread.adb,v 1.2 02/03/2003 16:54:01 pukitepa Exp $
------------------------------------------------------------------------------
end Uio.Thread;

