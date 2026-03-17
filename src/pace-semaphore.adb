package body Pace.Semaphore is

   procedure Initialize (Resource : in out Lock) is
   begin
      Resource.M.Wait;
   end Initialize;

   procedure Finalize (Resource : in out Lock) is
   begin
      Resource.M.Release;
   end Finalize;

   protected body Mutex is
      entry Wait when not Claimed is
      begin
         Claimed := True;
      end Wait;

      procedure Release is
      begin
         Claimed := False;
      end Release;
   end Mutex;

   ------------------------------------------------------------------------------
   -- $id: pace-semaphore.adb,v 1.1 09/16/2002 18:18:38 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Semaphore;
