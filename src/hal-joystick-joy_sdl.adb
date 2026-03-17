with Ada.Exceptions;
with Interfaces.C.Strings;
with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Socket;
with Sdl.Joystick;
with Sdl.Types;
with Sdl.Linkage;
with Hal.Joystick.Dispatcher;
with Pace.Strings;

package body Hal.Joystick.Joy_Sdl is

   use Pace.Strings;

   function Id is new Pace.Log.Unit_Id;

   use Hal.Joystick.Dispatcher;

   Started       : Boolean  := False;
   Monitor_Delay : Duration := 0.1;

   Device : Interfaces.C.int := Interfaces.C.int (Pace.Getenv ("DEVICE", 0));

   -- unique id of joystick in the event there is more than one joystick
   --sending out data
   Joy_Id : Integer := Pace.Getenv ("JOYSTICK_ID", 1);

   task Monitor is
      --  entry Start;
   end Monitor;

   Tolerance : constant Float := 0.05;

   task body Monitor is
      Output, Old_Output : Joy_Data;

      use Sdl.Joystick, Interfaces.C;
      Jp : Joystick_Ptr;

      procedure Get_Sdl_Data is

         function Filter (Val, Old_Val : in Float) return Float is
         begin
            pragma Debug (Pace.Log.Put_Line ("F:" & Val'Img & Old_Val'Img));
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

         Normalize : constant Float := 1.0 / Float (Sdl.Types.Sint16'Last);
         function Get_Axis (Axis : Integer) return Float is
            Axis_Value : Sdl.Types.Sint16;
         begin
            Axis_Value := Joystickgetaxis (Jp, Interfaces.C.int (Axis));
            return Float (Axis_Value) * Normalize;
         end Get_Axis;

         function Get_Button (Button : Integer) return Boolean is
         begin
            if Joystickgetbutton (Jp, Interfaces.C.int (Button)) = Pressed then
               return True;
            else
               return False;
            end if;
         end Get_Button;

      begin
         Joystickupdate;

         for I in  Output.Axes'Range loop
            Output.Axes (I) := Filter (Get_Axis (I), Old_Output.Axes (I));
         end loop;

         for I in  Output.Buttons'Range loop
            Output.Buttons (I) := Get_Button (I);
         end loop;

      end Get_Sdl_Data;

   begin
      Pace.Log.Agent_Id (Id);
      -- if FBPORT exists use flybox
      if Pace.Getenv ("FBPORT", "") = "" then
         if Sdl.Init (Sdl.Init_Joystick) < 0 then
            Pace.Log.Put_Line ("no Joystick initialization");
         else
            Pace.Log.Put_Line ("#Joysticks=" &
                               Integer'Image (Integer (Numjoysticks)));
            Pace.Log.Put_Line ("#Joystick" & Device'Img & "=" & Interfaces.C.Strings.Value (Joystickname (Device)));
            Jp := Joystickopen (Device);
            Pace.Log.Put_Line ("#JSButtons=" &
                               Integer'Image (Integer (Joysticknumbuttons (Jp))));
            Pace.Log.Put_Line ("Joystick initialized at rate " &
                               Duration'Image (Monitor_Delay));
         end if;

         loop
            delay Monitor_Delay;
            Get_Sdl_Data;
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
      when E : Interfaces.C.Strings.Dereference_Error =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line (
                            "!!!!!!!!! THE JOYSTICK DEVICE IS NOT WORKING (probably /dev/input/js0)!!!!!!")
           ;
      when E : others =>
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
      Pace.Log.Put_Line ("Setting Joystick polling rate to " & U2s (Obj.Set));
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Set_Rate'(Pace.Msg with Set => S2u ("10.0")));
end Hal.Joystick.Joy_Sdl;
