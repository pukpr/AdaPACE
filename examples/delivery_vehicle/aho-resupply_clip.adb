with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal;
with Hal.Sms;
with Ada.Numerics;

package body Aho.Resupply_Clip is

   function Id is new Pace.Log.Unit_Id;

   Spin_Rate : constant Float := Hal.Rads (300.0);
   Rotate_Degree : constant Float := 53.0;
   Current_Orn : Hal.Orientation := (0.0, 0.0, 0.0);
   Cell_Index : constant array (1 .. 8) of Float := 
      (0.0, 53.0, 91.0, 145.0, 182.0, 235.0, 272.0, 326.0); 
   Index : Integer := 1;
   
 procedure Input (Obj : in Next_Cell) is
 begin
   Index := Obj.Cell;
   declare
     Msg : Rotate_Clip;
   begin
     Msg.Axis := 'Z';
	 Msg.Speed := Spin_Rate;
	 Msg.Final := (0.0, 0.0, Cell_Index(Index));
     Pace.Dispatching.Input (Msg);
   end;
   if Index < 9 then
     Index := Index +1;
   else 
     Index := 1;
   end if;
   Pace.Log.Trace (Obj);
 end Input;

 procedure Input (Obj : in Rotate_Clip) is
    Stopped : Boolean;
    End_Orn : Hal.Orientation;
    Rate : Hal.Rate;
 begin
    if Obj.Axis = 'Z' or else Obj.Axis = 'z' then
       End_Orn := (0.0, 0.0, Hal.Rads (Obj.Final.C));
       Rate.Units := Obj.Speed;
       Hal.Sms.Rotation ("clip_rotate", (0.0, 0.0, Hal.Rads (Current_Orn.C)),
                           End_Orn, Rate, Stopped, 0.0, 0.0);
       Current_Orn.C := Obj.Final.C;
    end if;
    Pace.Log.Trace (Obj);
   end Input;

end Aho.Resupply_Clip;
