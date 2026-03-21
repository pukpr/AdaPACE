with Pace;
with Pace.Log;
with Hal;
with Hal.Sms;
with Ada.Numerics;

package body Aho.Bottle_Compartment is

   Final_Pos : Boolean := False;

   procedure Input (Obj : in Index_Compartment) is
   begin
      Pace.Log.Trace (Obj);
   end Input;



   procedure Input (Obj : in Index_To_Delivery_Position) is
   begin
      Pace.Log.Wait (4.5);
      Final_Pos := False;
      Pace.Log.Trace (Obj);
   end;

   procedure Input (Obj : in Index_To_Shuttle_Gate) is
   begin
      Pace.Log.Wait (4.5);
      declare
         Msg : Index_Complete;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Final_Pos := True;
      Pace.Log.Trace (Obj);
   end;

   procedure Input (Obj : in Index_To_Final_Position) is
   begin
      if not Final_Pos then
         Pace.Log.Wait (0.5);
		 Pace.Log.Put_Line ("Index To Final Position");
         declare
            Msg : Index_Complete;
         begin
            Pace.Dispatching.Input (Msg);
         end;
      end if;
      Pace.Log.Trace (Obj);
   end;

-- $id: aho-bottle_compartment.adb,v 1.5 12/22/2003 14:17:44 ludwiglj Exp $
end Aho.Bottle_Compartment;
