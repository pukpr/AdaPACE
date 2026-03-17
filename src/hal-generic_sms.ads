with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Interfaces.C;
with Pace.Stream;
with Pace.Strings;
with Pace.Notify;
with Ada.Strings.Bounded;
with Ada.Containers.Vectors;
with Hal.Bounded_Assembly;
with Ada.Containers.Indefinite_Vectors;
with System;
with Pace.Server.Dispatch;

generic
   -- primarily a generic for routing purposes
   Route_Tag : in Character := ASCII.NUL;
package Hal.Generic_Sms is
   -------------------------------
   -- Motion Control Interface  --
   -------------------------------
   pragma Elaborate_Body;

   Rewind_Prefix : constant String := "_";

   -- when recording the proxy will send out notifies each time
   -- a collision occurs with this info
   type Collision_Notice is new Pace.Notify.Subscription with
      record
         Assembly1 : Pace.Strings.Bstr.Bounded_String;
         Assembly2 : Pace.Strings.Bstr.Bounded_String;
      end record;

   package Collision_Description_String is
     new Ada.Strings.Bounded.Generic_Bounded_Length (200);

   procedure Log (Txt : in String);

   procedure Interval_Calculate (Time : in Duration;
                                 Number : out Integer;
                                 Delta_Time : out Duration);

   procedure Set (Name : in String; Event : in String; Time_Lapse : Duration; Entity : String := "");
   -- Calls the Named assembly, with an Event
   -- Time_Lapse is how long the event takes.  If Time_Lapse is positive then
   -- the Input will wait this long, if negative it will return immediately.
   -- For instantaneous events use a time_lapse of 0.0, and it will return immediately.

   procedure Set (Name : in String; Pos : in Position; Rot : in Orientation; Entity : in String := "");
   -- Calls the Named assembly with new Pos/Rot coordinates

   procedure Set (Name : in String; Pos : in Position; Entity : in String := "");
   -- Calls the Named assembly with new Pos coordinates

   procedure Set (Name : in String; Rot : in Orientation; Entity : in String := "");
   -- Calls the Named assembly with new Rot coordinates

   procedure Set_Var (Name : in String; Value : in String);
   -- Sets the Named variable with Value

   procedure Set_Spin (Name : in String; Spin_Amount : in Orientation);
   -- Calls the Named assembly with a spin

   procedure Set_Scale (Name : in String; Scaling : in Position; Entity : in String := "");
   -- Calls the Named assembly with a scale

   type Trans_Callback is access procedure (Pos : in Hal.Position);
   procedure Default_Trans (Pos : in Hal.Position);

   procedure Translation (Name : in String;
                          Start : in Position;
                          Final : in out Position;
                          Speed : in Rate;
                          Stopped : out Boolean;
                          Ramp_Up : in Duration := 0.0;
                          Ramp_Down : in Duration := 0.0;
                          Callback : in Trans_Callback := Default_Trans'Access;
                          Entity : in String := "");
   procedure Translation (Name : in String;
                          Start : in Position;
                          Final : in out Position;
                          Time : in Duration;
                          Stopped : out Boolean;
                          Ramp_Up : in Duration := 0.0;
                          Ramp_Down : in Duration := 0.0;
                          Callback : in Trans_Callback := Default_Trans'Access;
                          Entity : in String := "");

   type Motion_Callback is access procedure (Value : in Float);
   procedure Default_Motion (Value : in Float);
   procedure Motion (Name : in String;
                     Start : in Float;
                     Final : in out Float;
                     Axis : in Axes;
                     Max_Velocity : in Float;
                     Accel : in Float;
                     Decel : in Float;
                     Stopped : out Boolean;
                     Callback : in Motion_Callback := Default_Motion'Access;
                     Entity : in String := "";
                     Which_Way : in Direction_To_Rotate := Shortest_Route);

   -- a useful abstraction when you have more than 1 assembly with the same motion
   -- this will move all assemblies in the Names array along the motion specified
   type Names_Array is array (Positive range <>) of Hal.Bounded_Assembly.Bounded_String;
   procedure Motion (Names : in Names_Array;
                     Start : in Float;
                     Final : in out Float;
                     Axis : in Axes;
                     Max_Velocity : in Float;
                     Accel : in Float;
                     Decel : in Float;
                     Stopped : out Boolean;
                     Callback : in Motion_Callback := Default_Motion'Access;
                     Entity : in String := "";
                     Which_Way : in Direction_To_Rotate := Shortest_Route);

   --
   -- ALL ROTATIONS in radians!
   --

   type Rot_Callback is access procedure (Ori : in Hal.Orientation);
   procedure Default_Rot (Ori : in Orientation);

   procedure Rotation (Name : in String;
                       Start : in Orientation;
                       Final : in out Orientation;
                       Speed : in Rate;
                       Stopped : out Boolean;
                       Ramp_Up : in Duration := 0.0;
                       Ramp_Down : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access;
                       Entity : in String := "";
                       Which_Way : in Direction_To_Rotate := Shortest_Route);
   procedure Rotation (Name : in String;
                       Start : in Orientation;
                       Final : in out Orientation;
                       Time : in Duration;
                       Stopped : out Boolean;
                       Ramp_Up : in Duration := 0.0;
                       Ramp_Down : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access;
                       Entity : in String := "";
                       Which_Way : in Direction_To_Rotate := Shortest_Route);


   procedure Renormalize_Shortest_Path (Start : in Float; Final : in out Float);
   -- BOTH Start AND Final shoulde be in Radians!!!!
   -- Use before calling Rotation when you want the rotation to take the
   -- shortest path.  Ex.  Start is at 10 degrees and final is at 350 degrees.
   -- The output would then be start at 10 degrees and final at -10 degrees.

   procedure Coordination (Name : in String;
                           Start_Pos : in Position;
                           Final_Pos : in out Position;
                           Start_Rot : in Orientation;
                           Final_Rot : in out Orientation;
                           Time : in Duration;
                           Stopped : out Boolean;
                           Entity : in String := "");
   -- Calls the Named assembly with new Pos and Rot coordinates

   procedure Trace (Message : in Pace.Msg'Class);
   -- Trace the message without incorporating timing overhead

   procedure Link (Parent : in String; Child : in String; Shared_Entity : in String := "");
   -- Link the Child to the Parent
   -- can only provide one entity, so either use a shared entity or no entity

   procedure Unlink (Assembly : in String);
   -- UnLink the Child

   procedure Spring (Name : in String;
                     Start : in Position;
                     Extent : in Position;
                     Freq : in Rate;
                     Damp : in Rate;
                     Max_Time : in Duration := 0.0;
                     Callback : in Trans_Callback := Default_Trans'Access);
   -- Models a spring along a track
   -- max_time is a way of ending the affect since it tends to go on for awhile
   -- without any visual affect (and doing another while one is still in going
   -- will cause very odd visual affect).. max_time defaults to 0.0 which
   -- means there is no max_time

   procedure Pendulum (Name : in String;
                       Start : in Orientation;
                       Extent : in Orientation;
                       Freq : in Rate;
                       Damp : in Rate;
                       Max_Time : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access);
   -- Models a pendulum along a rotation
   -- max_time is a way of ending the affect since it tends to go on for awhile
   -- without any visual affect (and doing another while one is still in going
   -- will cause very odd visual affect).. max_time defaults to 0.0 which
   -- means there is no max_time

   function S (U : Ada.Strings.Unbounded.Unbounded_String) return String
     renames Ada.Strings.Unbounded.To_String;


   procedure Check;
   -- Suspends the Set operation about to take place.

   procedure Uncheck;
   -- Unsuspends the Set operation about to take place.

   -- stops a rotation, translation, coordination, etc. but does
   -- not propagate the exception onward
   Stop : exception;
   -- stops a rotation, translation, coordination, etc. and propagates the
   -- exception onwards
   Stop_And_Propagate : exception;

   procedure Check_Override;
   -- Allows subsequent Set operations to take place, previous actions Stopped.

   procedure Time_Scale (Scale : in Float);
   -- Sets the time scale (speed of simulation, meaning 2.0 is twice as slow)

   -- Callback to show all division evants available
   type Display is access procedure (Name : in String;
                                     Assembly : in String;
                                     Event : in String);
   procedure Show_All (Proc : in Display);

   procedure Set_Delta (Frequency : in Rate);
   procedure Set_Delta (Tick : in Duration);

   -- active -> if from stub then false, if from ve then true
   procedure Get_Terrain_Elevation (Z_North : in Float; X_East : in Float;
                                    Y_Elevation : out Float; Active : out Boolean);

   -- active -> output boolean.. if from stub then false, if from ve then true
   -- is_absolute -> input boolean.. set to true if want absolute coordinate
   -- also obtains the scale of the assembly
   procedure Get_Coordinate (Assembly : in String; Pos : out Position; Ori : out Orientation; Active : out Boolean; Is_Absolute : in Boolean := False; Scale : out Position; Entity : in String := "");

   procedure Create_Object (Entity : String; Geom_Type : String; Pos : Position; Ori : Orientation; Ground_Clamp : Boolean := False; Is_Instance : Boolean := False);

   procedure Create_Effect (Entity : String; Fx_Type : String; Pos : Position; Ori : Orientation);

   -- switch the state of an .flt file.. such as damages states
   procedure Set_Switch (Entity : String; Switch_Name : String; State : Integer);

   -- use impact and launch to interface to the damage "server"
   procedure Impact (Munition : String; Pos : Position);
   procedure Launch (Munition : String; Entity : String := "");

   procedure Rot_Order (Entity : String; Dof : String; Rot_Order : String);

   -- enable and disable visual plotting of an entity's position.
   procedure StartPlot (Entity : String);
   procedure StopPlot (Entity : String);

   -- play an animation in VE
   procedure Player(Filename : String);

--private

   subtype Name is Interfaces.C.Char_Array (0 .. Hal.Max_Assembly_Name_Length);
   -- Division assemblies limited to constrained length
   function To_Name (Str : in String) return Name;

   Blank : constant Name := (others => ' '); -- To_Name ("");

   package Proxy is

      type Shape is new Pace.Msg with
         record
            Assembly : Name;
            Start : Position;
            Final : Position;
            Speed : Rate;
            Stopped : Boolean;
            Ramp_Up : Duration := 0.0;
            Ramp_Down : Duration := 0.0;
         end record;
      procedure Input (Obj : in Shape);

      type Translate is new Pace.Msg with
         record
            Assembly : Name;
            Pos : Position;
            Entity : Name := Blank;
         end record;
      procedure Input (Obj : Translate);
      -- Translates SMS Assembly

      type Rotate is new Pace.Msg with
         record
            Assembly : Name;
            Rot : Orientation;
            Entity : Name := Blank;
         end record;
      procedure Input (Obj : Rotate);
      -- Rotates SMS Assembly

      type Coordinate is new Pace.Msg with
         record
            Assembly : Name;
            Pos : Position;
            Rot : Orientation;
            Entity : Name := Blank;
         end record;
      procedure Input (Obj : Coordinate);
      -- Translates and Rotates SMS Assembly

      type Set_Event is new Pace.Msg with
         record
            Assembly : Name;
            Event : Name;
            Entity : Name := Blank;
         end record;
      procedure Input (Obj : Set_Event);
      -- Sets event on SMS Assembly

      type Set_Link is new Pace.Msg with
         record
            Parent : Name;
            Child : Name;
            Shared_Entity : Name := Blank;
         end record;
      procedure Input (Obj : Set_Link);

      type Set_Unlink is new Pace.Msg with
         record
            Assembly : Name;
            Dummy : Name;
         end record;
      procedure Input (Obj : Set_Unlink);

      type Set_Variable is new Pace.Msg with
         record
            Object : Name;
            Variable : Name;
         end record;
      procedure Input (Obj : Set_Variable);
      -- Sets SMS variable

      type Scale is new Pace.Msg with
         record
            Assembly : Name;
            Mag : Position;
            Entity : Name := Blank;
         end record;
      procedure Input (Obj : Scale);
      -- Scales SMS Assembly

      type Spin is new Pace.Msg with
         record
            Assembly : Name;
            Rot : Orientation;
         end record;
      procedure Input (Obj : Spin);
      -- Spins SMS Assembly

      type Pos_Record is
         record
            Assembly : Name;
            Pos : Position;
            Entity : Name := Blank;
         end record;
      package Pos_Data is new Pace.Stream.Binary_Array (Pos_Record);

      type Translate_Array (Size : Integer) is new Pace.Msg with
         record
            List : Pos_Data.Buffer (1 .. Size);
         end record;
      procedure Input (Obj : Translate_Array);
      -- Array of Translate assemblies

      type Rot_Record is
         record
            Assembly : Name;
            Rot : Orientation;
            Entity : Name := Blank;
         end record;
      package Rot_Data is new Pace.Stream.Binary_Array (Rot_Record);

      type Rotate_Array (Size : Integer) is new Pace.Msg with
         record
            List : Rot_Data.Buffer (1 .. Size);
         end record;
      procedure Input (Obj : Rotate_Array);
      -- Array of Rotate assemblies

      type Coord_Record is
         record
            Assembly : Name;
            Pos : Position;
            Rot : Orientation;
            Entity : Name := Blank;
         end record;
      package Coord_Data is new Pace.Stream.Binary_Array (Coord_Record);

      type Coordinate_Array (Size : Integer) is new Pace.Msg with
         record
            List : Coord_Data.Buffer (1 .. Size);
         end record;
      procedure Input (Obj : Coordinate_Array);
      -- Array of Coordinate assemblies

      type Coord_Records is array (Integer range <>) of Coord_Record;
      type Coordinate_Array_Safe (Size : Integer) is new Pace.Msg with
         record
            List : Coord_Records (1 .. Size);
         end record;
      procedure Input (Obj : Coordinate_Array_Safe);
      -- Array of Coordinate assemblies

      package Coord_Vec is new Ada.Containers.Indefinite_Vectors
                                          (Index_Type => Positive,
                                           Element_Type => Coord_Record,
                                           "=" => "=");

      type Coordinate_Vector is new Pace.Msg with
         record
            V : Coord_Vec.Vector;
         end record;
      procedure Input (Obj : Coordinate_Vector);
      -- Vector of Coordinate assemblies


      type Query_Terrain_Elevation is new Pace.Msg with
         record
            Z_North : Float;  -- input
            X_East : Float;  -- input
            Y_Elevation : Float;  -- output
            Active : Boolean; -- output .. if from stub then false, if from ve then true
         end record;
      procedure Inout (Obj : in out Query_Terrain_Elevation);

      -- the obj.slot representing the PACE_NODE is coming as in input and so here we use
      -- an inout instead of output... subtle
      type Query_Coordinate is new Pace.Msg with
         record
            Assembly : Name; -- input
            Entity : Name; -- input
            Is_Absolute : Boolean; -- input
            Pos : Position; -- output
            Ori : Orientation;  -- output
            Active : Boolean; -- output .. if from stub then false, if from ve then true
            Scale : Position; -- output
         end record;
      procedure Inout (Obj : in out Query_Coordinate);

      type Init_Object is new Pace.Msg with
         record
            Entity : Name;
            Geom_Type : Name;
            Pos : Position;
            Ori : Orientation;
            Ground_Clamp : Boolean := False;
            Is_Instance : Boolean := False;
         end record;
      procedure Input (Obj : in Init_Object);

      type Init_Effect is new Pace.Msg with
         record
            Entity : Name;
            Fx_Type : Name;
            Pos : Position;
            Ori : Orientation;
         end record;
      procedure Input (Obj : in Init_Effect);

      type Set_Switch is new Pace.Msg with
          record
             Entity : Name;
             Switch_Name : Name;
             State : Integer;
          end record;
      procedure Input (Obj : in Set_Switch);

      type Set_Impact is new Pace.Msg with
         record
            Munition : Name;
            Pos : Position;
         end record;
      procedure Input (Obj : in Set_Impact);

      type Set_Launch is new Pace.Msg with
         record
            Munition : Name;
            Entity : Name;
         end record;
      procedure Input (Obj : in Set_Launch);

      type Set_Rot_Order is new Pace.Msg with
         record
            Entity : Name;
            Dof : Name;
            Rot_Order : Name;
         end record;
      procedure Input (Obj : in Set_Rot_Order);

      type Set_Start_Plot is new Pace.Msg with
         record
            Entity : Name;
         end record;
      procedure Input (Obj : in Set_Start_Plot);

      type Set_Stop_Plot is new Pace.Msg with
         record
            Entity : Name;
         end record;
      procedure Input (Obj : in Set_Stop_Plot);

      type Set_Player is new Pace.Msg with
         record
            Filename : Name;
         end record;
      procedure Input (Obj : in Set_Player);

      type Msg_Range is new Integer;

      type Dvs_Record is
         record
            Msg_Type : Msg_Range;
            Assembly : Name;
            Event : Name;
            Pos : Position;
            Rot : Orientation;
            Entity : Name := Blank;
            Assembly_Ptr : System.Address := System.Null_Address;
         end record;
      pragma Convention (C, Dvs_Record);

      type Collision_Type is (Unclassified, Interference, Simulation_Error, Connected_Parts, Ignore);

      -- if collision is true then the data is irrelevant and may be null
      type Dvs_Stored_Record is
         record
            Data : Dvs_Record;
            Timestamp : Duration;
            Instantaneous_Event : Boolean := False;
            Collision : Boolean := False;
            Collision_Description :
              Collision_Description_String.Bounded_String :=
              Collision_Description_String.To_Bounded_String ("");
            Collision_Classification : Collision_Type := Unclassified;
         end record;

      function "<" (L, R : Dvs_Stored_Record) return Boolean;

      -- we aren't doing dispatching, so turn off warnings here
      pragma Warnings (Off);
      package Dvs_Record_Vector is new Ada.Containers.Vectors (Natural,
                                                               Dvs_Stored_Record,
                                                               "=");
      pragma Warnings (On);

      package Sort is new Dvs_Record_Vector.Generic_Sorting (Proxy."<");

      Event_Const : constant Msg_Range := 1;
      Variable_Const : constant Msg_Range := 2;
      Coord_Const : constant Msg_Range := 3;
      Scale_Const : constant Msg_Range := 4;
      Position_Const : constant Msg_Range := 5;
      Orientation_Const : constant Msg_Range := 6;
      Link_Const : constant Msg_Range := 7;
      Unlink_Const : constant Msg_Range := 8;
      -- the rest are experimental
      Texture1D_Const : constant Msg_Range := 9;
      Spin_Const : constant Msg_Range := 10;
      Texture2D_Const : constant Msg_Range := 11;

      -- Puts a DVS message on the queue
      procedure Playback_Put (Msg : Dvs_Record);

      -- puts a DVS message to the queue for normal processing
      procedure Put (Data : Dvs_Record;
                     Instantaneous_Event : Boolean := False;
                     Collision : Boolean := False;
                     Collision_Description : Collision_Description_String.Bounded_String :=
                       Collision_Description_String.To_Bounded_String (""));

      -- Indicates whether Real is on for child packages
      function Is_On return Boolean;

      -- Sends a 6DOF to the internal rendering engine
      procedure Render (Part       : in Dvs_Record;
                        X, Y, Z    : in Float;
                        W, A, B, C : in Float);

   end Proxy;

private
   type Dvs is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Dvs);

   type Dead_Reckoning is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Dead_Reckoning);

------------------------------------------------------------------------------
-- $version: 8 $
-- $history: Common $
-- $view: /prog/shared/modsim/ctd/sim.ss/work/int.wrk $
------------------------------------------------------------------------------
end Hal.Generic_Sms;

