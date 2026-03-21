with Pace;
with Pace.Log;
with Pace.Surrogates;
with Hal.Sms;
with Hal.Audio.Mixer;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Pace.Strings; use Pace.Strings;

with Aho.Door;
with Aho.Bottle_Shuttle;
with Aho.Box_Shuttle;
with Aho.Inventory_Job_Grippers;
with Aho.Actuator;
with Ahd.Job_Order_Status;
with Vkb.Db;

package body Aho.Inventory_Job is

   function Id is new Pace.Log.Unit_Id;

   package Morph is
      type Raise_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Raise_Loader);

      type Lower_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Lower_Loader);
   end Morph;
   package body Morph is separate;

   package Jack_Track is
      type Raise_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Raise_Loader);
      type Lower_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Lower_Loader);
   end Jack_Track;
   package body Jack_Track is separate;

   package Demonstrator is
      type Raise_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Raise_Loader);
      type Lower_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Lower_Loader);
   end Demonstrator;
   package body Demonstrator is separate;

   package Linkage is
      type Raise_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Raise_Loader);
      type Lower_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Lower_Loader);
   end Linkage;
   package body Linkage is separate;

   package Four_Bar is
      type Raise_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Raise_Loader);
      type Lower_Loader is new Pace.Msg with
         record
            Elevation : Float;
         end record;
      procedure Input (Obj : in Lower_Loader);
   end Four_Bar;
   package body Four_Bar is separate;

   -- this is set by quering the kbase at elaboration time below
--   Which_Loader : Loader_Type;

   Standoff_Orientation : Hal.Orientation := (0.0, 0.0, 0.0);

   Current_Orn : Hal.Orientation := Standoff_Orientation;

   Elevation : Float := 0.0;
   Azimuth : Float := 0.0;
   Current_Item : Integer := 0;
   Tot_Items : Integer;
   Delivery_Delay : Boolean := True;

   Swingtray_Settle_Time : constant Duration := 0.1065;
   -- the following swingtray data does not apply to the
   -- counter-rotation... when counter-rotating the drive
   -- operates at less than max values
   Swingtray_Ramp_Up : constant Duration := 0.1775;
   Swingtray_Ramp_Down : constant Duration := 0.1775;
   Swingtray_Max_Velocity : constant Float := 200.53;

   Lower_Settle_Time : constant Duration := 0.0856;
   Raise_Settle_Time : constant Duration := 0.1606;

   Retainer_Ramp_Up : constant Duration := 0.1094;
   Retainer_Ramp_Down : constant Duration := 0.1094;
   Retainer_Settle_Time : constant Duration := 0.0656;
   Retainer_Total_Time : constant Duration := 0.3;

   task Agent is
      entry Input (Obj : in Initialize);
      entry Input (Obj : in Load_Drone);
      entry Input (Obj : in Ack_Load_Drone_Complete);
      entry Input (Obj : in Stow_Equipment);
      entry Input (Obj : in Raise_Loader_For_Rearm);
      entry Input (Obj : in Lower_Loader_For_Rearm);
   end Agent;

--     function Get_Which_Loader return Loader_Type is
--     begin
--        return Which_Loader;
--     end Get_Which_Loader;

   procedure Load_Inventory is
   begin
      Pace.Log.Put_Line ("loading inventory");
      declare
         use Aho.Actuator;
         Msg : Place_Box;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         use Ahd.Job_Order_Status;
         Msg : Modify_Box;
      begin
         Msg.Index := Current_Item;
         Msg.Status := Placed;
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Aho.Actuator.Retract_Actuator;
      begin
         Msg.Unloaded := False;
         Pace.Dispatching.Input (Msg);
      end;
      Aho.Actuator.Reset_Box;
      declare
         Msg : Swing_Tray_To_Bottle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         Msg : Aho.Actuator.Place_Bottle;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      Aho.Actuator.Reset_Bottle;
      declare
         Msg : Aho.Actuator.Retract_Actuator;
      begin
         Msg.Unloaded := True;
         Pace.Surrogates.Input (Msg);
      end;
      -- loader lowers .25 seconds after actuator begins retracting!  synchronization unnecessary here.
      Pace.Log.Wait (0.25);
   end Load_Inventory;

   procedure Transfer_Inventory_To_Loader is
   begin

      declare
         use Aho.Bottle_Shuttle;
         Msg : Transfer_Bottle_To_Loader;
      begin
         -- returns immediately
         Pace.Dispatching.Input (Msg);
      end;

      declare
         use Aho.Box_Shuttle;
         Msg : Transfer_Box_To_Loader;
      begin
         -- returns immediately
         Pace.Dispatching.Input (Msg);
      end;

      declare
         use Aho.Bottle_Shuttle;
         Msg : Await_Bottle_Transfer;
      begin
         Pace.Dispatching.Input (Msg);
      end;

      declare
         use Aho.Box_Shuttle;
         Msg : Await_Box_Transfer;
      begin
         Pace.Dispatching.Input (Msg);
      end;

      -- Closes Both Doors
      declare
         Msg : Close_Loader_Retainer;
      begin
         Pace.Dispatching.Input (Msg);
      end;
--      Pace.Log.Put_Line ("***  CLEARING DRONE TO DELIVERY  ***");
      Pace.Log.Put_Line ("+++ Current Item : " & Integer'Image(Current_Item)
                               & " +++");
      if Delivery_Delay = False then
         declare
            Msg : Clear_To_Delivery;
         begin
            Pace.Surrogates.Input(Msg);
         end;
      Pace.Log.Put_Line ("***  CLEARING DRONE TO DELIVERY  ***");
      end if;

      -- Ack Doors are closed
       Pace.Log.Put_Line ("***  DRONE CLEARED, ACK BOTTLE TRANSFER  ***");
     declare
         use Aho.Bottle_Shuttle;
         Msg : Ack_Bottle_Transfer;
      begin
         Pace.Dispatching.Input (Msg);
      end;
       Pace.Log.Put_Line ("***  ACK BOX TRANSFER  ***");

      declare
         use Aho.Box_Shuttle;
         Msg : Ack_Box_Transfer;
      begin
         Pace.Dispatching.Input (Msg);
      end;
       Pace.Log.Put_Line ("***  SHUTTLES CLEARED  ***");

      declare
         use Aho.Bottle_Shuttle;
         Msg : Bottle_Shuttle_Clear;
      begin
         Pace.Dispatching.Input (Msg);
      end;
      declare
         use Aho.Box_Shuttle;
         Msg : Box_Shuttle_Clear;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Transfer_Inventory_To_Loader;

   type Scan is new Pace.Msg with null record;
   procedure Input (Obj : Scan);
   procedure Input (Obj : Scan) is
   begin
      Pace.Log.Wait (0.05);
      Pace.Log.Trace (Obj);
   end Input;

   type Laser_Range is new Pace.Msg with null record;
   procedure Input (Obj : Laser_Range);
   procedure Input (Obj : Laser_Range) is
   begin
      Pace.Log.Wait (1.0);
      Pace.Log.Trace (Obj);
   end Input;

   type Camera is new Pace.Msg with null record;
   procedure Input (Obj : Camera);
   procedure Input (Obj : Camera) is
   begin
      Pace.Log.Wait (1.5);
      Pace.Log.Trace (Obj);
   end Input;

   type Extinguish is new Pace.Msg with null record;
   procedure Input (Obj : Extinguish);
   procedure Input (Obj : Extinguish) is
   begin
      Pace.Log.Wait (0.25);
      Pace.Log.Trace (Obj);
   end Input;

   type Chamber_Cooling is new Pace.Msg with null record;
   procedure Input (Obj : Chamber_Cooling);
   procedure Input (Obj : Chamber_Cooling) is
   begin
      Pace.Log.Wait (1.5);
      Pace.Log.Trace (Obj);
   end Input;

   type Clean is new Pace.Msg with null record;
   procedure Input (Obj : Clean);
   procedure Input (Obj : Clean) is
   begin
      declare
         Msg : Scan;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      if Current_Item /= 1 then
         declare
            Msg : Extinguish;
         begin
            Pace.Surrogates.Input (Msg);
         end;
                 declare
                    Msg : Chamber_Cooling;
                 begin
                    Pace.Surrogates.Input (Msg);
                 end;
         declare
            Msg : Camera;
         begin
            Pace.Surrogates.Input (Msg);
         end;
      end if;
      Pace.Log.Wait (0.05);
      declare
         Msg : Laser_Range;
      begin
         Pace.Surrogates.Input (Msg);
      end;
   end Input;

   -- door closes 0.5 seconds after loader begins to lower...
   -- simpler to put a timer in then a synchronization
   type Wait_And_Close_Door is new Pace.Msg with null record;
   procedure Input (Obj : Wait_And_Close_Door);
   procedure Input (Obj : Wait_And_Close_Door) is
   begin
      Pace.Log.Wait (0.5);
      declare
         Msg : Aho.Door.Close_Door_Door;
      begin
         Pace.Surrogates.Input (Msg);
      end;
      -- bottle retainer is retracted 0.1 seconds after door door begins to close
      Pace.Log.Wait (0.1);
      declare
         Msg : Aho.Actuator.Retract_Bottle_Retainer;
      begin
         Pace.Dispatching.Input (Msg);
      end;
   end Input;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         select
            accept Input (Obj : in Initialize) do
               Pace.Log.Trace (Obj);
               Current_Item := 1;
               Tot_Items := Obj.Total_Items;
            end Input;
            -- Opens both doors
            declare
               Msg : Open_Loader_Retainer;
            begin
               Pace.Surrogates.Input (Msg);
            end;

            Transfer_Inventory_To_Loader;
            Pace.Log.Put_Line ("done transfering inventory");
         or
            accept Input (Obj : in Load_Drone) do
               Current_Item := Obj.Item_Index;
               --                Azimuth := Obj.Azimuth;
               Elevation := Obj.Elevation;
            end Input;
            declare
               Msg : Aho.Bottle_Shuttle.Index_Compartment;
            begin
               Pace.Surrogates.Input (Msg);
            end;
            declare
               Msg : Aho.Box_Shuttle.Index_Compartment;
            begin
               Pace.Surrogates.Input (Msg);
            end;
            declare
               Msg : Raise_Loader;
            begin
               null; --  Pace.Dispatching.Input (Msg);
            end;

            declare
               Msg : Clean;
            begin
               Pace.Surrogates.Input (Msg);
            end;

            Load_Inventory;

            declare
               Msg : Wait_And_Close_Door;
            begin
               Pace.Surrogates.Input (Msg);
            end;
            declare
               Msg : Lower_Loader;
            begin
               null; --Pace.Dispatching.Input (Msg);
            end;
            accept Input (Obj : in Ack_Load_Drone_Complete) do
               Pace.Log.Trace (Obj);
            end Input;
            Delivery_Delay := False;
            if Current_Item /= Tot_Items then
               Transfer_Inventory_To_Loader;
            end if;
            --  Tell Drone Okay to Delivery;
            if Current_Item = Tot_Items then
  	    		declare
  				  Msg : Clear_To_Delivery;
  	    		begin
  				  Pace.Dispatching.Input(Msg);
  	    		end;
				Delivery_Delay := True;
	    	end if;

         or
            accept Input (Obj : in Stow_Equipment) do
               Pace.Log.Trace (Obj);
            end Input;
            declare
               use Aho.Box_Shuttle;
               Msg : Stow;
            begin
               Pace.Dispatching.Input (Msg);
            end;
         or
            accept Input (Obj : in Raise_Loader_For_Rearm) do
               Pace.Log.Trace (Obj);
            end Input;
            declare
               Msg : Raise_Loader;
            begin
               Pace.Dispatching.Input (Msg);
            end;
            accept Input (Obj : in Lower_Loader_For_Rearm) do
               Pace.Log.Trace (Obj);
            end Input;
            declare
               Msg : Lower_Loader;
            begin
               Pace.Dispatching.Input (Msg);
            end;

         end select;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : in Initialize) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Load_Drone) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Ack_Load_Drone_Complete) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Stow_Equipment) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Raise_Loader_For_Rearm) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Lower_Loader_For_Rearm) is
   begin
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : in Raise_Loader) is
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("loader");
   begin
      declare
         use Aho.Door;
         Msg : Open_Door_Door;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      declare
         Msg : Swing_Tray_To_Box;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      -- starting sound
      Pace.Dispatching.Inout (Audio_Msg);

      -- Jack Loader
      declare
         Msg : Aho.Inventory_Job.Jack_Track.Raise_Loader;
      begin
         Msg.Elevation := Hal.Rads (Elevation);
         Pace.Dispatching.Input (Msg);
      end;
      -- stopping sound
      Pace.Dispatching.Inout (Audio_Msg);

      Pace.Log.Wait (Raise_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   type Wait_And_Align_Loader is new Pace.Msg with null record;
   procedure Input (Obj : Wait_And_Align_Loader);
   procedure Input (Obj : Wait_And_Align_Loader) is
   begin
      Pace.Log.Wait (0.25);

      declare
         Msg : Rotate_Loader;
      begin
         Msg.Total_Time := 0.4;
         Msg.Final := (0.0, Azimuth, 0.0);
         Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
           ("axis_swingtray");
         Input (Msg);
      end;

      Pace.Log.Wait (Swingtray_Settle_Time);
      Pace.Log.Trace (Obj);

      -- Opens both doors
      declare
         Msg : Open_Loader_Retainer;
      begin
         Input (Msg);
      end;
   end Input;

   procedure Input (Obj : in Lower_Loader) is
      Audio_Msg : Hal.Audio.Mixer.Play_Mix := Make_Audio ("loader");
   begin
      declare
         Msg : Wait_And_Align_Loader;
      begin
         Pace.Surrogates.Input (Msg);
      end;

      -- starting sound
      Pace.Dispatching.Inout (Audio_Msg);

      -- Jack Loader
      declare
         Msg : Aho.Inventory_Job.Jack_Track.Lower_Loader;
      begin
         Msg.Elevation := Hal.Rads (Elevation);
         Pace.Dispatching.Input (Msg);
      end;

      Pace.Dispatching.Inout (Audio_Msg);

      Pace.Log.Wait (Lower_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Swing_Tray_To_Bottle) is
   begin
      declare
         Msg : Rotate_Loader;
      begin
         Msg.Total_Time := 0.6;
         Msg.Final := (0.0, 33.65, 0.0);
         Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                           ("axis_swingtray");
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Swingtray_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Swing_Tray_To_Box) is
   begin
      declare
         Msg : Rotate_Loader;
      begin
         Msg.Total_Time := 0.5;
         Msg.Final := (0.0, -33.65, 0.0);
         Msg.Assembly := Ada.Strings.Unbounded.To_Unbounded_String
                           ("axis_swingtray");
         Pace.Dispatching.Input (Msg);
      end;
      Pace.Log.Wait (Swingtray_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;


   type Rotate_Retainer is new Pace.Msg with
      record
         Name : Ada.Strings.Unbounded.Unbounded_String;
         Begin_Ori : Hal.Orientation;
         Final_Ori : Hal.Orientation;
      end record;
   procedure Input (Obj : Rotate_Retainer);
   procedure Input (Obj : Rotate_Retainer) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation := Obj.Final_Ori;
   begin
      Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Name),
                        Obj.Begin_Ori, End_Orn,
                        Retainer_Total_Time - Retainer_Settle_Time, Stopped,
                        Retainer_Ramp_Up, Retainer_Ramp_Down);
   end Input;

   Box_Retainer_Close_Ori : Hal.Orientation := (0.0, Hal.Rads(-13.5), 0.0);
   Bottle_Retainer_Close_Ori : Hal.Orientation := (0.0, Hal.Rads (13.5), 0.0);
   Bottle_Retainer_Open_Ori : Hal.Orientation := (0.0, 0.0, 0.0);
   Box_Retainer_Open_Ori : Hal.Orientation := (0.0, 0.0, 0.0);

   -- open at same time
   procedure Input (Obj : in Open_Loader_Retainer) is
   begin
      declare
         Msg : Rotate_Retainer;
      begin
         Msg.Name := Ada.Strings.Unbounded.To_Unbounded_String
                       ("BottleShutter");
         Msg.Begin_Ori := Bottle_Retainer_Close_Ori;
         Msg.Final_Ori := Bottle_Retainer_Open_Ori;
         Pace.Surrogates.Input (Msg);
      end;
      declare
         Msg : Rotate_Retainer;
      begin
         Msg.Name := Ada.Strings.Unbounded.To_Unbounded_String
                       ("BoxShutter");
         Msg.Begin_Ori := Box_Retainer_Close_Ori;
         Msg.Final_Ori := Box_Retainer_Open_Ori;
         Input (Msg);
      end;
      Pace.Log.Wait (Retainer_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   -- close at same time
   procedure Input (Obj : in Close_Loader_Retainer) is
   begin
      declare
         Msg : Rotate_Retainer;
      begin
         Msg.Name := Ada.Strings.Unbounded.To_Unbounded_String
                       ("BottleShutter");
         Msg.Final_Ori := Bottle_Retainer_Close_Ori;
         Msg.Begin_Ori := Bottle_Retainer_Open_Ori;
         Pace.Surrogates.Input (Msg);
      end;
      declare
         Msg : Rotate_Retainer;
      begin
         Msg.Name := Ada.Strings.Unbounded.To_Unbounded_String
                       ("BoxShutter");
         Msg.Final_Ori := Box_Retainer_Close_Ori;
         Msg.Begin_Ori := Box_Retainer_Open_Ori;
         Input (Msg);
      end;
      Pace.Log.Wait (Retainer_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Swing_Bottle_Tray_Door_Open) is
   begin
      Hal.Sms.Set ("BottleShutter", "open", 0.25);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Swing_Bottle_Tray_Door_Close) is
   begin
      Hal.Sms.Set ("BottleShutter", "close", 0.5);
      Pace.Log.Trace (Obj);
   end Input;

   procedure Input (Obj : in Counter_Rotate) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation := (0.0, Hal.Rads (Obj.Offset),0.0 );
      Rate : Hal.Rate;
   begin
      Azimuth := Obj.Offset;
      -- needs to use speed rotation (instead of time) in order to match pivot
      Rate.Units := Obj.Max_Velocity;
      Hal.Sms.Rotation ("axis_swingtray",
                        (0.0,  Hal.Rads (Current_Orn.B), 0.0), End_Orn,
                        Rate, Stopped,
                        Obj.Ramp_Up, Obj.Ramp_Down);
      Current_Orn.B := Hal.Degs (End_Orn.B);
      Pace.Log.Wait (Swingtray_Settle_Time);
      Pace.Log.Trace (Obj);
   end Input;


   procedure Input (Obj : in Rotate_Loader) is
      Stopped : Boolean;
      End_Orn : Hal.Orientation;
   begin
      End_Orn := (0.0, Hal.Rads (Obj.Final.B), 0.0);
      Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Assembly),
                        (0.0,Hal.Rads (Current_Orn.B), 0.0), End_Orn,
                        Obj.Total_Time - Swingtray_Settle_Time, Stopped,
                        Swingtray_Ramp_Up, Swingtray_Ramp_Down);
      Current_Orn.B := Hal.Degs (End_Orn.B);
   end Input;





--begin

   -- initializing Which_Loader from the kbase
--     declare
--        Loader_Str : String := Vkb.Db.Get ("which_loader");
--     begin
--        Pace.Log.Put_Line ("Loader_Str is " & Loader_Str);
--        Which_Loader := Loader_Type'Value (Loader_Str);
--     end;
--     Pace.Log.Put_Line ("which_loader has been initialized to " &
--                        Loader_Type'Image (Which_Loader));

--  exception
--     when E: others =>
--        Pace.Log.Ex (E);
--        Pace.Log.Put_Line
--          ("Kbase query for which_loader failed.  Assigning loader type to Morph_Loader");
--      Which_Loader := Jack_Loader;
end Aho.Inventory_Job;
