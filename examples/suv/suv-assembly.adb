with Hal.Sms;

package body Suv.Assembly is

   Start : Float := 0.0;
   Rot : Hal.Orientation := (0.0, 0.0, 0.0);

   procedure Inout (Obj : in out Step) is
      Rot2 : Hal.Orientation := Rot;
      Stopped : Boolean;
   begin
      Obj.Last := Rot2.A;
      Rot2.A :=  Rot2.A + 0.1;
      Hal.Sms.Rotation ("Assembly_3", Rot, Rot2, 0.5, Stopped);
      Rot := Rot2;
   end;

   procedure Input (Obj : in Step) is
      Rot2 : Hal.Orientation := Rot;
      Stopped : Boolean;
   begin
      Rot2.A := Obj.Last;   
      Hal.Sms.Rotation ("Assembly_3", Rot, Rot2, 0.5, Stopped);
      Rot := Rot2;
   end;







   Start1 : Float := 0.0;
   Rot1 : Hal.Orientation := (0.0, 0.0, 0.0);

   procedure Inout (Obj : in out Step1) is
      Rot2 : Hal.Orientation := Rot1;
      Stopped : Boolean;
   begin
      Obj.Last := Rot2.A;
      Rot2.A :=  Rot2.A + 0.1;
      Hal.Sms.Rotation ("Assembly_5", Rot1, Rot2, 0.5, Stopped);
      Rot1 := Rot2;
   end;

   procedure Input (Obj : in Step1) is
      Rot2 : Hal.Orientation := Rot1;
      Stopped : Boolean;
   begin
      Rot2.A := Obj.Last;   
      Hal.Sms.Rotation ("Assembly_5", Rot1, Rot2, 0.5, Stopped);
      Rot1 := Rot2;
   end;

end;
