generic
   type Index_Type is (<>); -- range of values
package Pace.Resource is
   -------------------------------------------
   -- RESOURCE -- Pick a task-safe resource
   -------------------------------------------
   pragma Elaborate_Body;

   function Get (Oldest : Boolean := False) return Index_Type;
   --
   -- If Index not found immediately, queued until available.
   -- Once used, must be Free'd to reuse.

   procedure Free (Index : in Index_Type);
   --
   -- Make Index available for reuse.

   function Is_Available return Boolean;
   --
   -- Are resources available?

   Resource_Error : exception;
   --
   -- Raised if Get fails

   ------------------------------------------------------------------------------
   -- $id: pace-resource.ads,v 1.1 09/16/2002 18:18:37 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Resource;
