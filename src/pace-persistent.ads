package Pace.Persistent is
   ------------------------------------------------------------
   -- PERSISTENT -- Stores command messages to persistent store
   ------------------------------------------------------------
   pragma Elaborate_Body;

   procedure Put (Obj : in Msg'Class);
   -- Raises exception if not successful in storing object

   procedure Get (Obj : in out Msg'Class);
   -- If not successfull then the IN value is returned

------------------------------------------------------------------------------
-- $id: pace-persistent.ads,v 1.2 11/19/2002 14:16:02 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Persistent;
