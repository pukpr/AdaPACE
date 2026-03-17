with Pace.Server.Dispatch;
with Ada.Tags;
with Pace.Log;
with HLA.Kb;

package Hla.Rx is
   pragma Elaborate_Body;

   type Init_Incoming is new Pace.Server.Dispatch.Action with 
      record
         Handle : Gateway := Null_Gateway;
      end record;
   procedure Inout (Obj : in out Init_Incoming);

   -------------------------------------------
   -- Dispatching to hla
   -------------------------------------------
   -- "Name" inputs look like "CC.OBJ.OP"

   Not_Registered : exception;
   Tag_Error : exception renames Ada.Tags.Tag_Error;

   type Action is abstract tagged null record;
   procedure Input (Obj : in Action; Parameter, Data : in String;
                    Counter : in Long_Integer) is abstract;
   -- use the Factory below to instantiate

   procedure Dispatch_To_Action (Name, Parameter, Data : in String;
                                 Counter : in Long_Integer);

   generic
      with procedure Process (Parameter, Data, Identifier : in String;
                              Counter : in Long_Integer);
   package Factory is
      --function Id is new Pace.Log.Unit_Id;
      Id : constant String := Hla.KB.Class_Name;
      function Name return String;
      function Name return Ada.Strings.Unbounded.Unbounded_String;
   private
      type A is new Action with null record;
      procedure Input (Obj : in A; Parameter, Data : in String;
                       Counter : in Long_Integer);
   end Factory;

   procedure Save_Action (Obj : in Action'Class);

   -- $Id: hla-rx.ads,v 1.8 2004/09/08 15:15:44 pukitepa Exp $
end Hla.Rx;
