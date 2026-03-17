with Pace.Log;
with Unchecked_Conversion;
with C;
with Pace.Server.Dispatch;
with Pace.Socket;
with System;
with C.Lv3;  -- Binding to flybox control
with Hal.Joystick.Dispatcher;
with Pace.Strings;

package body Hal.Joystick.Flybox is

   use Pace.Strings;

   function Id is new Pace.Log.Unit_Id;

   use Hal.Joystick.Dispatcher;

   -- These are the 'raw' values
   subtype Output_Type is Standard.C.Lv3.Bglv;

   Started : Boolean := False;
   Monitor_Delay : Duration := 0.1;

   Tolerance : constant Float := 0.01;

   -- unique id of joystick in the event there is more than one joystick sending out data
   Joy_Id : Integer := Pace.Getenv ("JOYSTICK_ID", 1);

   task Monitor is
      --entry Start;
   end Monitor;

   -- Calibration values for stick
   Calibration : Joystick_Axes;

   Output, Old_Output : Joy_Data;

   procedure Get_Raw (Output : out Output_Type) is
   begin
      Standard.C.Lv3.Get_Lv_Buffer (Output);
   end Get_Raw;

   type Discrete_Type is array (0 .. 31) of Boolean;
   pragma Pack (Discrete_Type);

   function To_Discrete is new Unchecked_Conversion
                                 (Standard.C.Signed_Int, Discrete_Type);

   procedure Get_Flybox_Data is
      T : Output_Type;

      Discretes : Discrete_Type;
      Bumps : Discrete_Type;

      function Filter (Val, Old_Val : in Float) return Float is
      begin
         if abs Val > Tolerance then
            if abs (Val - Old_Val) > Tolerance then
               return Val;
            else
               return Old_Val;
            end if;
         else
            return 0.0;
         end if;
      end Filter;

      function Bit_Ordering (Position : in Integer) return Integer;
      pragma Inline (Bit_Ordering);

      function Bit_Ordering (Position : in Integer) return Integer is
         use type System.Bit_Order;
      begin
         if System.Default_Bit_Order = System.High_Order_First then
            return 31 - Position;
         else
            return Position;
         end if;
      end Bit_Ordering;

   begin
      Get_Raw (T);

      for I in 0 .. 4 loop
         Output.Axes(I) := Filter (Float (T.Ain (I)) - Calibration (I), Old_Output.Axes(I));
      end loop;

      Discretes := To_Discrete (T.Din (0));
      for I in 0 .. 7 loop
         Output.Buttons (I) := Discretes (Bit_Ordering (I));
      end loop;

      Bumps := To_Discrete (T.Din (1));
      for I in 0 .. 6  loop
         Output.Buttons (I+8) := Bumps (Bit_Ordering (I));
      end loop;

   end Get_Flybox_Data;

   task body Monitor is
      Calibration_Loops : constant := 5.0;
      T, E, R : Float := 0.0;
   begin
      Pace.Log.Agent_Id (Id);
      -- if FBPORT doesn't exist then use sdl joystick
      if Pace.Getenv ("FBPORT", "") /= "" then
         Standard.C.Lv3.Setup_Lv;
         Pace.Log.Put_Line ("Flybox initialized at rate " &
                            Duration'Image (Monitor_Delay));

         for I in 1 .. Integer (Calibration_Loops) loop
            delay 0.2;
            Get_Flybox_Data;
            for I in Calibration'Range loop
               Calibration (I) := Calibration (I) + Output.Axes (I) / Calibration_Loops;
            end loop;
         end loop;

         Pace.Log.Put_Line ("Flybox calibration complete");

         loop
            delay Monitor_Delay;
            Get_Flybox_Data;
            if Output /= Old_Output then
               declare
                  Msg : Hal.Joystick.Dispatcher.Device_Update;
               begin
                  Msg.Joy_Id := Joy_Id;
                  Msg.Data := Output;
                  Pace.Socket.Send (Msg);
               end;
               Old_Output := Output;
            end if;
         end loop;
      end if;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Monitor;

   procedure Set_Hz (Rate : in Float) is
   begin
      Monitor_Delay := Duration (1.0 / Rate);
   end Set_Hz;

   type Set_Rate is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Set_Rate);

   procedure Inout (Obj : in out Set_Rate) is
      use Pace.Server.Dispatch;
   begin
      Set_Hz (Float'Value (U2s (Obj.Set)));
      Pace.Log.Put_Line ("Setting Flybox polling rate to " & U2s (Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Set_Rate'(Pace.Msg with Set => S2u ("10.0")));
end Hal.Joystick.Flybox;
