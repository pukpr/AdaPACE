with Pace;
with Pace.Log;
with Pace.Surrogates;
with Ada.Strings.Unbounded;
with Ada.Numerics.Elementary_Functions;
with Hal.Sms;

separate (Aho.Inventory_Job)
package body Four_Bar is

   package Asu renames Ada.Strings.Unbounded;
   use Asu;

   type Assembly_Pair is
      record
         Name : Asu.Unbounded_String;
         Current_Amount : Float; -- in degrees if orientation, meters if position
      end record;

   Phi : Assembly_Pair := (Asu.To_Unbounded_String ("axis_loader"), 0.0);
   Omega : Assembly_Pair := (Asu.To_Unbounded_String ("load_link2"), 0.0);
   Gamma : Assembly_Pair := (Asu.To_Unbounded_String ("load_link3"), 0.0);
   Ro : Assembly_Pair := (Asu.To_Unbounded_String ("load_tray"), 0.0);
   Z : Assembly_Pair := (Asu.To_Unbounded_String ("loader_slide"), 0.0);

   -- important constants..
   D1 : constant Float := 0.175;
   D2 : constant Float := 0.5497;
   D3 : constant Float := 0.347;
   D4 : constant Float := 0.600;
   A1Y : constant Float := 0.2;

   -- the overall time it takes the loader to rise or lower
   Time_To_Raise : constant Float := 1.4;

   function Check_Range (Value : Float) return Float is
      Result : Float := Value;
   begin
      if Result > 1.0 then
         Pace.Log.Put_Line ("changing value from " &
                            Float'Image (Result) & " to 1.0");
         Result := 1.0;
      elsif Result < 0.0 then
         Pace.Log.Put_Line ("changing value from " &
                            Float'Image (Result) & " to 0.0");
         Result := 0.0;
      end if;
      return Result;
   end Check_Range;

   function Get_Phi (Theta : Float) return Float is
   begin
      return -1.0 * (6.0 / 5.0 * Theta + 48.0);
   end Get_Phi;

   function Get_A3Y (Theta : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return 1.0 * D1 * Sin (Hal.Rads (Theta)) +
               (D2 * Cos (Hal.Rads (-1.0 * Get_Phi (Theta))) - A1Y);
   end Get_A3Y;

   function Get_A3X (Theta : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return D1 * Cos (Hal.Rads (Theta)) +
               D2 * Sin (Hal.Rads (-1.0 * Get_Phi (Theta)));
   end Get_A3X;

   function Get_D5 (Theta : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return Sqrt (Get_A3X (Theta) ** 2 + (A1Y - Get_A3Y (Theta)) ** 2);
   end Get_D5;

   function Get_Gamma (Theta : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return Hal.Degs (Arccos (Check_Range ((Get_D5 (Theta) ** 2 -
                                             D3 ** 2 - D4 ** 2) /
                                            (-2.0 * D4 * D3))));
--      return 0.85 * Get_Omega (Theta);
   end Get_Gamma;

   function Get_Omega (Theta : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return
        Hal.Degs
          (Arcsin
             (Check_Range
                (D4 / Get_D5 (Theta) * Sin (Hal.Rads (Get_Gamma (Theta)))))) -
        55.0;
      --return -1.0 * Get_Phi (Theta);
   end Get_Omega;

   function Get_Ro (Theta : Float) return Float is
   begin
      return 138.0 + 1.0 / 5.0 * Theta;
   end Get_Ro;

   function Get_Z (Theta : Float) return Float is
   begin
      return 0.45 - 1.0 / 350.0 * Theta;
   end Get_Z;


   type Rotate_Assembly is new Pace.Msg with
      record
         Destination : Float;  -- on the A axis
         Assembly : Assembly_Pair;
         Speed : Float;
      end record;
   procedure Input (Obj : in Rotate_Assembly);

   type Translate_Assembly is new Pace.Msg with
      record
         Destination : Float;  -- on the A axis
         Assembly : Assembly_Pair;
         Speed : Float;
      end record;
   procedure Input (Obj : in Translate_Assembly);

   procedure Input (Obj : in Raise_Loader) is
      Theta : Float := Obj.Elevation;  -- for renaming purposes
   begin

      -- all 5 pieces should move simultaneously
      declare
         Msg : Rotate_Assembly;
      begin
         Msg.Assembly := Phi;
         Msg.Destination := Get_Phi (Theta);
         Pace.Surrogates.Input (Msg);
      end;

      --     declare
--          Msg : Rotate_Assembly;
--       begin
--          Msg.Assembly := Omega;
--          Msg.Destination := Get_Omega (Theta);
--          Pace.Surrogates.Input (Msg);
--       end;

--       declare
--          Msg : Rotate_Assembly;
--       begin
--          Msg.Assembly := Gamma;
--          Msg.Destination := Get_Gamma (Theta);
--          Pace.Surrogates.Input (Msg);
--       end;

      declare
         Msg : Rotate_Assembly;
      begin
         Msg.Assembly := Ro;
         Msg.Destination := Get_Ro (Theta);
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Translate_Assembly;
      begin
         Msg.Assembly := Z;
         Msg.Destination := Get_Z (Theta);
         Pace.Dispatching.Input (Msg);
      end;

      -- due to silly complications, must update current values of assemblies
      -- like so. all 5 threads above should have utilized current_amount
      -- by now, so it is okay (not ideal) to update them here. ideally..
      -- would have to set up 5 separate tasks.
--      Pace.Log.Wait (1.4);
      Phi.Current_Amount := Get_Phi (Theta);
      --Omega.Current_Amount := Get_Omega (Theta);
      --Gamma.Current_Amount := Get_Gamma (Theta);
      Ro.Current_Amount := Get_Ro (Theta);
      Z.Current_Amount := Get_Z (Theta);

      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Lower_Loader) is
   begin

      -- all 5 pieces should move simultaneously
      declare
         Msg : Rotate_Assembly;
      begin
         Msg.Assembly := Phi;
         Msg.Destination := 0.0;
         Pace.Surrogates.Input (Msg);
      end;

      --      declare
--          Msg : Rotate_Assembly;
--       begin
--          Msg.Assembly := Omega;
--          Msg.Destination := 0.0;
--          Pace.Surrogates.Input (Msg);
--       end;

--       declare
--          Msg : Rotate_Assembly;
--       begin
--          Msg.Assembly := Gamma;
--          Msg.Destination := 0.0;
--          Pace.Surrogates.Input (Msg);
--       end;

      declare
         Msg : Rotate_Assembly;
      begin
         Msg.Assembly := Ro;
         Msg.Destination := 0.0;
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Translate_Assembly;
      begin
         Msg.Assembly := Z;
         Msg.Destination := 0.0;
         Pace.Dispatching.Input (Msg);
      end;

      -- due to silly complications, must update current values of assemblies
      -- like so. all 5 threads above should have utilized current_amount
      -- by now, so it is okay (not ideal) to update them here. ideally..
      -- would have to set up 5 separate tasks.
      Phi.Current_Amount := 0.0;
      Omega.Current_Amount := 0.0;
      Gamma.Current_Amount := 0.0;
      Ro.Current_Amount := 0.0;
      Z.Current_Amount := 0.0;

      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Rotate_Assembly) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation := (Hal.Rads (Obj.Destination), 0.0, 0.0);
      Rate : Hal.Rate;
   begin
      Rate.Units := Hal.Rads
                      (abs (Obj.Destination - Obj.Assembly.Current_Amount) /
                       Time_To_Raise);
      Hal.Sms.Rotation (Asu.To_String (Obj.Assembly.Name),
                        (Hal.Rads (Obj.Assembly.Current_Amount), 0.0, 0.0),
                        End_Orn, Rate, Stopped);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Translate_Assembly) is
      Stopped : Boolean;
      End_Pos : Hal.Position := (0.0, 0.0, Obj.Destination);
      Rate : Hal.Rate;
   begin
      Rate.Units := abs (Obj.Destination - Obj.Assembly.Current_Amount) /
                      Time_To_Raise;
      Hal.Sms.Translation (Asu.To_String (Obj.Assembly.Name),
                           (0.0, 0.0, Obj.Assembly.Current_Amount),
                           End_Pos, Rate, Stopped);
      Pace.Log.Trace (Obj);
   end Input;

end Four_Bar;
