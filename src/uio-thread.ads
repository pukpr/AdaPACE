with Ada.Finalization;
with Ada.Task_Identification;

package Uio.Thread is
   pragma Elaborate_Body;
   --
   -- Critical section control for UIO
   --

   type Control is tagged limited private;

private

   package Ati renames Ada.Task_Identification;

   protected type Mutex (Safe : Boolean := False) is
      entry Wait (Id : in out Ati.Task_Id);
      procedure Release;
      entry Safe_Wait (Id : in out Ati.Task_Id);
   private
      Claimed : Boolean := False;
      Current : Ati.Task_Id := Ati.Null_Task_Id;
   end Mutex;

   type Lock (M : access Mutex) is new Ada.Finalization.Limited_Controlled with
      record
         Release : Boolean := True;
      end record;

   procedure Initialize (Resource : in out Lock);  -- Create 
   procedure Finalize (Resource : in out Lock);    -- Destroy

   --
   -- Publish on Display -- Singleton Mutex
   --

   Display : aliased Mutex (Safe => True);
   type Control is new Lock (Display'Access) with null record;

------------------------------------------------------------------------------
-- $id: uio-thread.ads,v 1.3 02/03/2003 16:54:04 pukitepa Exp $
------------------------------------------------------------------------------
end Uio.Thread;

