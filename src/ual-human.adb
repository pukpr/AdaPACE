with Pace.Log;
with Pace;
with Ual.Utilities;

package body Ual.Human is

   Animation_Mode : Boolean := "1" = Pace.Getenv ("HAL_SMS", "1");

   use Interrupt_Set_Package;
   use Hal;

   Human_Response_Time : constant Duration := 0.1;

   function "<" (L, R : Interrupt) return Boolean is
   begin
      if L.Priority < R.Priority then
         return True;
      else
         return False;
      end if;
   end "<";

   function "=" (L, R : Interrupt) return Boolean is
      use Pace;
   begin
      if L.To_Do = R.To_Do then
         return True;
      else
         return False;
      end if;
   end "=";

   -- if there are any interrupts in the set then do the one with highest
   --priority
   -- continue until there are no more interrupts
   procedure Check_Interrupt (Person : in out Active_Human) is
   begin
      while not Is_Empty (Person.Interrupt_Set) loop
         declare
            Activity : Interrupt := Element (First (Person.Interrupt_Set));
            To_Do    : Pace.Msg'Class := Pace.To_Msg (Activity.To_Do);
         begin
            Pace.Dispatching.Input (To_Do);
            Delete (Person.Interrupt_Set, Activity);
         end;
      end loop;
   end Check_Interrupt;

   procedure Activity (Person : in out Active_Human; Length : Duration) is
      Time : Duration := 0.0;
   begin
      -- loop until Time is within Human_Response_Time of being done
      while Time < (Length - Human_Response_Time) loop
         Check_Interrupt (Person);
         Pace.Log.Wait (Human_Response_Time);
         Time := Time + Human_Response_Time;
      end loop;
      -- wait the last bit to complete the total Length of time
      Pace.Log.Wait (Length - Time);
   end Activity;

   procedure Interrupt_Activity
     (Person   : in out Active_Human;
      To_Do    : Pace.Channel_Msg;
      Priority : Integer)
   is
      Inter_Activity : Interrupt;
   begin
      Inter_Activity.To_Do    := To_Do;
      Inter_Activity.Priority := Priority;
      Insert (Person.Interrupt_Set, Inter_Activity);
   end Interrupt_Activity;

   procedure Wait_Until_Interrupted (Person : in out Active_Human) is
   begin
      -- waiting here is less than human_response_time.. makes sense in this
      -- case.. if someone is specifically waiting to be interrupted they
      --would respond faster
      -- we don't want an obvious time lapse to occur between when the
      -- human notices that he/she is interrupted
      while Is_Empty (Person.Interrupt_Set) loop
         Pace.Log.Wait (0.02);
      end loop;
      Check_Interrupt (Person);
   end Wait_Until_Interrupted;

   function S (Value : Float) return String is
   begin
      return Ual.Utilities.Float_Put (Value) & " ";
   end S;

   procedure Translation
     (Person  : in out Active_Human;
      Name    : in String;
      Start   : in Position;
      Final   : in out Position;
      Time    : in Duration;
      Stopped : out Boolean)
   is
      Num          : Integer;
      Pos          : Position;
      Dx, Dy, Dz   : Float;
      Current_Time : Duration := Pace.Now;
      D_T          : Duration;
   begin
      if not Animation_Mode then
         Hal.Sms.Log
           ("move " &
            Name &
            " " &
            S (Start.X) &
            S (Start.Y) &
            S (Start.Z) &
            S (Final.X) &
            S (Final.Y) &
            S (Final.Z) &
            S (Float (Time)));
      end if;
      if Time = 0.0 then
         Stopped := False;
         return;
      end if;
      Hal.Sms.Interval_Calculate (Time, Num, D_T);
      Pos := Start;
      Dx  := (Final.X - Start.X) / Float (Num);
      Dy  := (Final.Y - Start.Y) / Float (Num);
      Dz  := (Final.Z - Start.Z) / Float (Num);
      for I in  1 .. Num loop
         Check_Interrupt (Person);
         Hal.Sms.Set (Name, Pos);
         Pace.Log.Wait (D_T);
         Pos.X := Pos.X + Dx;
         Pos.Y := Pos.Y + Dy;
         Pos.Z := Pos.Z + Dz;
      end loop;
      Pos := Final;
      Hal.Sms.Set (Name, Pos);
      Stopped := False;
   exception
      when Hal.Sms.Stop =>
         Pace.Log.Put_Line ("--- Stopping " & Name);
         Final   := Pos;
         Stopped := True;
   end Translation;

   procedure Rotation
     (Person  : in out Active_Human;
      Name    : in String;
      Start   : in Orientation;
      Final   : in out Orientation;
      Time    : in Duration;
      Stopped : out Boolean)
   is
      Num : Integer;
      Da  : Float;
      Db  : Float;
      Dc  : Float;
      Rot : Orientation;
      D_T : Duration;
   begin
      if not Animation_Mode then
         Hal.Sms.Log
           ("spin " &
            Name &
            " " &
            S (Start.A) &
            S (Start.B) &
            S (Start.C) &
            " " &
            S (Final.A) &
            S (Final.B) &
            S (Final.C) &
            S (Float (Time)));
      end if;
      if Time = 0.0 then
         Stopped := False;
         return;
      end if;
      Hal.Sms.Interval_Calculate (Time, Num, D_T);
      Da  := (Final.A - Start.A) / Float (Num);
      Db  := (Final.B - Start.B) / Float (Num);
      Dc  := (Final.C - Start.C) / Float (Num);
      Rot := Start;
      for I in  1 .. Num loop
         Check_Interrupt (Person);
         Hal.Sms.Set (Name, Rot);
         Pace.Log.Wait (D_T);
         Rot.A := Rot.A + Da;
         Rot.B := Rot.B + Db;
         Rot.C := Rot.C + Dc;
      end loop;
      Rot := Final;
      Hal.Sms.Set (Name, Rot);
      Stopped := False;
   exception
      when Hal.Sms.Stop =>
         Pace.Log.Put_Line ("--- Stopping " & Name);
         Final   := Rot;
         Stopped := True;
   end Rotation;

end Ual.Human;
