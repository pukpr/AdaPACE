with Pace.Log;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Pace.Xml;
with Pace.Strings;

package body Uio.Joystick_Control is

   use Pace.Strings;

   -- nothing is on by default.... must call set_mode to turn a joystick on
   -- type Mode_Type is (None, Steering, Sighting);

   -- maps joystick ids to modes
   Modes : array (Joystick_Range) of Mode_Type := (others => Mode_Type'First);

--    procedure Turn_Off (Joy_Id : Integer) is
--    begin
--       if Modes (Joy_Id) /= None then
--          if Modes(Joy_Id) = Steering then
--             Acu.Vehicle.Joystick_Off;
--          elsif Modes(Joy_Id) = Sighting then
--             Dar.Joystick.Off;
--          end if;
--       end if;
--    end Turn_Off;

--    procedure Turn_On (New_Mode : Mode_Type; Joy_Id : Integer) is
--    begin
--       if New_Mode = Steering then
--          Acu.Vehicle.Joystick_On (Joy_Id);
--       elsif New_Mode = Sighting then
--          Dar.Joystick.On (Joy_Id);
--       end if;
--       Modes (Joy_Id) := New_Mode;
--    end Turn_On;

--    procedure Swap_Joysticks is
--       -- switch them, so new_steering_id is the previous sighting id, etc.
--       New_Steering_Id : Integer := Dar.Joystick.Get_Unique_Id;
--       New_Sighting_Id : Integer := Acu.Vehicle.Get_Joystick_Unique_Id;
--    begin
--       Acu.Vehicle.Set_Joystick_Unique_Id (New_Steering_Id);
--       Modes (New_Steering_Id) := Steering;
--       Dar.Joystick.Set_Unique_Id (New_Sighting_Id);
--       Modes (New_Sighting_Id) := Sighting;
--    end Swap_Joysticks;

   procedure Set_Joystick_Mode (Joy_Id : Joystick_Range; New_Mode : Mode_Type) is
   begin
      if Modes (Joy_Id) /= New_Mode then
         Switch (Joy_Id, New_Mode);
         Modes (Joy_Id) := New_Mode;
--          Turn_Off (Joy_Id);
--          Turn_On (New_Mode, Joy_Id);
--          if New_Mode = Sighting then
--             declare
--                Msg : Dar.Defensive_Mount.Start;
--             begin
--                Pace.Dispatching.Input(Msg);
--             end;
--          end if;
      end if;
   end Set_Joystick_Mode;

   type Set_Mode is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Set_Mode);
   procedure Inout (Obj : in out Set_Mode) is
      S : constant String := U2s(Obj.Set);
      use Pace.Xml;
      Joy_Id : Integer := Integer'Value (Search_Xml (S, "id", "1"));
      New_Mode : Mode_Type := Mode_Type'Value (Search_Xml (S, "mode", "NONE"));
   begin
      Set_Joystick_Mode (Joystick_Range(Joy_Id), New_Mode);
   exception
      when E : others =>
         Pace.Log.Ex (E, "Expecting cgi parameter set=<joystick><id>1</id><mode>STEERING</mode></joystick>");
   end Inout;

   use Pace.Server.Dispatch;

   type Get_Modes is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Modes);
   procedure Inout (Obj : in out Get_Modes) is
      use Pace.Server.Xml;
      Default_Stylesheet : String := "/eng/joystick/joystick_config.xsl";
   begin
      Put_Content (Default_Stylesheet);
      Obj.Set := S2u("");
      for I in Modes'Range loop
         Append (Obj, Item ("joystick", Item ("id", Pace.Strings.Trim (Joystick_Range'Image (I))) &
                                Item ("mode", Mode_Type'Image (Modes (I)))));
      end loop;
      Obj.Set := Item (S2u("joystick_config"), Obj.Set);
      Pace.Server.Put_Data (U2s(Obj.Set));
   end Inout;


begin
   Save_Action (Set_Mode'(Pace.Msg with Set => Default));
   Save_Action (Get_Modes'(Pace.Msg with Set => Default));
end Uio.Joystick_Control;
