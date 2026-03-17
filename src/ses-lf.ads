with Ada.Finalization;
with Ada.Tags;

package Ses.Lf is

   -------------------------------------------
   -- H -- This will only work with GNAT !
   -------------------------------------------
   -- "Text" inputs look like the following:
   --     CC.OBJ.OP set 1

   pragma Elaborate_Body;  -- Elaboration before anyone else registers

   Not_Registered : exception;
   End_Processing : exception;
   Tag_Error : exception renames Ada.Tags.Tag_Error;

   type Action is abstract new Ada.Finalization.Controlled with null record;
   procedure Input (Obj : in Action; Command : in String) is abstract;
   procedure Initialize (Obj : in out Action);

   procedure Dispatch_To_Action (Text : in String; Quit : out Boolean);

   generic
      with procedure Process (Cmd : in String; Quit : out Boolean);
   package Factory is
      private 
         type A is new Ses.Lf.Action with null record;
         procedure Input (Obj : in A; Cmd : in String);
   end Factory;

------------------------------------------------------------------------------
-- $id: ses-lf.ads,v 1.1 05/19/2003 12:54:29 pukitepa Exp $
------------------------------------------------------------------------------
end Ses.Lf;
