with Ada.Finalization;

package Pace.Semaphore is
   ---------------------------------------------------------
   -- SEMAPHORE -- Binary semaphore with auto scope release
   ---------------------------------------------------------
   -- Instancing LOCK provides a "wait/release" binary semaphore.
   --
   --  My_Mutex : aliased Mutex;
   --
   --  declare
   --     My_Lock : Lock (My_Mutex'Access);
   --  begin
   pragma Elaborate_Body;

   type Mutex is limited private;
   type Lock (M : access Mutex) is new
     Ada.Finalization.Limited_Controlled with private;

   procedure Initialize (Resource : in out Lock);
   procedure Finalize (Resource : in out Lock);

private

   protected type Mutex is
      entry Wait;
      procedure Release;
   private
      Claimed : Boolean := False;
   end Mutex;

   type Lock (M : access Mutex) is new
     Ada.Finalization.Limited_Controlled with null record;

   ------------------------------------------------------------------------------
   -- $id: pace-semaphore.ads,v 1.1 09/16/2002 18:18:38 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Semaphore;
