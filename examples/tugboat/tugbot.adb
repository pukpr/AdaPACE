with Pace.Log;
with Pace.Server;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Pace.Strings; use Pace.Strings;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;

--
--  Ada Singleton Object Pattern
--
package body Tugbot is

   --
   --  Ada Package Identification Pattern
   --
   function Id is new Pace.Log.Unit_Id;

   --
   --  Ada Protected Data Pattern -- thread-safe robot state shared across tasks
   --
   protected State is
      procedure Set_Drive   (D : in Drive_State);
      procedure Set_Gripper (G : in Gripper_State);
      procedure Set_Light   (L : in Boolean);
      procedure Set_Speed   (S : in Long_Float);
      procedure Set_Pose    (X, Y, H : in Long_Float);
      function  Get_Drive   return Drive_State;
      function  Get_Gripper return Gripper_State;
      function  Get_Light   return Boolean;
      function  Get_Speed   return Long_Float;
      function  Get_X       return Long_Float;
      function  Get_Y       return Long_Float;
      function  Get_Heading return Long_Float;
   private
      Current_Drive   : Drive_State   := Stopped;
      Current_Gripper : Gripper_State := Open;
      Light_On        : Boolean       := False;
      Current_Speed   : Long_Float    := 0.0;
      Pos_X           : Long_Float    := 0.0;
      Pos_Y           : Long_Float    := 0.0;
      Current_Heading : Long_Float    := 0.0;
   end State;

   protected body State is
      procedure Set_Drive   (D : in Drive_State)   is begin Current_Drive   := D; end Set_Drive;
      procedure Set_Gripper (G : in Gripper_State) is begin Current_Gripper := G; end Set_Gripper;
      procedure Set_Light   (L : in Boolean)       is begin Light_On        := L; end Set_Light;
      procedure Set_Speed   (S : in Long_Float)    is begin Current_Speed   := S; end Set_Speed;
      procedure Set_Pose (X, Y, H : in Long_Float) is
      begin
         Pos_X := X; Pos_Y := Y; Current_Heading := H;
      end Set_Pose;
      function Get_Drive   return Drive_State   is (Current_Drive);
      function Get_Gripper return Gripper_State is (Current_Gripper);
      function Get_Light   return Boolean       is (Light_On);
      function Get_Speed   return Long_Float    is (Current_Speed);
      function Get_X       return Long_Float    is (Pos_X);
      function Get_Y       return Long_Float    is (Pos_Y);
      function Get_Heading return Long_Float    is (Current_Heading);
   end State;

   --
   --  Physical constants (realistic tugbot dimensions)
   --
   use Ada.Numerics.Long_Elementary_Functions;
   use Ada.Numerics;

   dT           : constant Long_Float := 0.05;   -- simulation step  (s)
   Wheel_Radius : constant Long_Float := 0.10;   -- drive wheel radius (m)
   Track_Width  : constant Long_Float := 0.40;   -- left-to-right drive wheel spacing (m)
   Max_Omega    : constant Long_Float := 10.0;   -- max wheel angular speed (rad/s)
   Light_Rate   : constant Long_Float := 3.0;    -- warning beacon spin speed (rad/s)

   --  Gripper joint limits (radians)
   Gripper_Open   : constant Long_Float := 0.0;
   Gripper_Closed : constant Long_Float := 1.2;
   Hand_Open      : constant Long_Float := 0.0;
   Hand_Closed    : constant Long_Float := 0.8;

   -------------------------------------------------------------------------
   --  DRIVE TASK
   --  Computes differential-drive kinematics, updates odometry, and commands
   --  the drive wheel joints and chassis pose in Gazebo.
   --  Pattern: HumanRobot Gait_Controller / Panda Control_Task
   -------------------------------------------------------------------------
   task Drive_Task;
   task body Drive_Task is
      function ID is new Pace.Log.Unit_ID;

      Spd     : Long_Float := 0.0;
      Drive   : Drive_State := Stopped;
      L_Omega : Long_Float := 0.0;   -- left  wheel rad/s
      R_Omega : Long_Float := 0.0;   -- right wheel rad/s
      V       : Long_Float := 0.0;   -- chassis linear  speed (m/s)
      W       : Long_Float := 0.0;   -- chassis angular speed (rad/s)
      X       : Long_Float := 0.0;
      Y       : Long_Float := 0.0;
      H       : Long_Float := 0.0;   -- heading (rad)
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Tugbot Drive_Task started.");

      loop
         Spd   := State.Get_Speed;
         Drive := State.Get_Drive;

         --  Differential-drive wheel velocities
         case Drive is
            when Moving_Forward  =>
               L_Omega :=  Spd * Max_Omega;
               R_Omega :=  Spd * Max_Omega;
            when Moving_Backward =>
               L_Omega := -Spd * Max_Omega;
               R_Omega := -Spd * Max_Omega;
            when Turning_Left    =>
               L_Omega := -Spd * Max_Omega * 0.5;
               R_Omega :=  Spd * Max_Omega * 0.5;
            when Turning_Right   =>
               L_Omega :=  Spd * Max_Omega * 0.5;
               R_Omega := -Spd * Max_Omega * 0.5;
            when Stopped         =>
               L_Omega := 0.0;
               R_Omega := 0.0;
         end case;

         --  Dead-reckoning odometry integration
         V := (L_Omega + R_Omega) * Wheel_Radius * 0.5;
         W := (R_Omega - L_Omega) * Wheel_Radius / Track_Width;
         H := H + W * dT;
         X := X + V * cos (H) * dT;
         Y := Y + V * sin (H) * dT;
         State.Set_Pose (X, Y, H);

         --  Command chassis pose via link (Set_Pose -> Pose component)
         Gz_Links.Set_Pose (base_link, X => X, Y => Y, Yaw => H);

         --  Command drive wheel angular velocity via link (Set_Rot -> SetAngularVelocity)
         Gz_Links.Set_Rot (wheel_left,  Yaw => L_Omega);
         Gz_Links.Set_Rot (wheel_right, Yaw => R_Omega);

         --  Command drive wheel joint positions (for visual fidelity)
         Gz_Joints.Set_Pose (wheel_left_joint,  Roll => L_Omega);
         Gz_Joints.Set_Pose (wheel_right_joint, Roll => R_Omega);

         --  Caster wheels: propagate chassis heading
         Gz_Links.Set_Pose (wheel_front, Yaw => H);
         Gz_Links.Set_Pose (wheel_back,  Yaw => H);

         --  IMU link tracks chassis heading (fixed joint, orientation update)
         Gz_Links.Set_Pose (imu_link, Yaw => H);

         Pace.Log.Wait (duration(dT));
      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E, "Tugbot Drive_Task error");
   end Drive_Task;

   -------------------------------------------------------------------------
   --  SENSOR TASK
   --  Keeps sensor links (cameras, scanners) co-located with the chassis.
   --  Fixed-joint sensors inherit pose from base_link in Gazebo physics, but
   --  explicit updates allow the shared-memory plugin to reflect their pose
   --  for any external consumer reading the shared table.
   -------------------------------------------------------------------------
   task Sensor_Task;
   task body Sensor_Task is
      function ID is new Pace.Log.Unit_ID;
      X : Long_Float;
      Y : Long_Float;
      H : Long_Float;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Tugbot Sensor_Task started.");

      loop
         X := State.Get_X;
         Y := State.Get_Y;
         H := State.Get_Heading;

         Gz_Links.Set_Pose (camera_front, X => X, Y => Y, Yaw => H);
         Gz_Links.Set_Pose (camera_back,  X => X, Y => Y, Yaw => H + Pi);
         Gz_Links.Set_Pose (scan_front,   X => X, Y => Y, Yaw => H);
         Gz_Links.Set_Pose (scan_back,    X => X, Y => Y, Yaw => H + Pi);
         Gz_Links.Set_Pose (scan_omni,    X => X, Y => Y, Yaw => H);

         Pace.Log.Wait (duration(dT * 2.0));   -- sensors update at half the drive rate
      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E, "Tugbot Sensor_Task error");
   end Sensor_Task;

   -------------------------------------------------------------------------
   --  LIGHT TASK
   --  Spins the warning beacon (revolute joint) when enabled.
   --  Pattern: HumanRobot Arm_Controller / gazebo_3d Wobble task
   -------------------------------------------------------------------------
   task Light_Task;
   task body Light_Task is
      function ID is new Pace.Log.Unit_ID;
      Angle : Long_Float := 0.0;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Tugbot Light_Task started.");

      loop
         if State.Get_Light then
            Angle := Angle + Light_Rate * dT;
            --  Set_Pose on a revolute joint -> JointPosition (Roll = joint angle)
            Gz_Joints.Set_Pose (warnign_light_joint, Roll => Angle);
         end if;
         Pace.Log.Wait (duration(dT));
      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E, "Tugbot Light_Task error");
   end Light_Task;

   -------------------------------------------------------------------------
   --  GRIPPER TASK
   --  Servos gripper_joint and gripper_hand_joint toward the commanded target
   --  using a first-order low-pass filter (lerp) to smooth motion.
   --  Pattern: HumanRobot Posture_Controller
   -------------------------------------------------------------------------
   task Gripper_Task;
   task body Gripper_Task is
      function ID is new Pace.Log.Unit_ID;
      Cur_Arm  : Long_Float := 0.0;
      Cur_Hand : Long_Float := 0.0;
      Tgt_Arm  : Long_Float := 0.0;
      Tgt_Hand : Long_Float := 0.0;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Tugbot Gripper_Task started.");

      loop
         case State.Get_Gripper is
            when Open   => Tgt_Arm := Gripper_Open;   Tgt_Hand := Hand_Open;
            when Closed => Tgt_Arm := Gripper_Closed;  Tgt_Hand := Hand_Closed;
         end case;

         --  First-order filter toward target (10% step per cycle = smooth servo)
         Cur_Arm  := Cur_Arm  + (Tgt_Arm  - Cur_Arm)  * 0.1;
         Cur_Hand := Cur_Hand + (Tgt_Hand - Cur_Hand) * 0.1;

         --  Set_Pose on revolute joint -> JointPosition in Gazebo
         Gz_Joints.Set_Pose (gripper_joint,      Roll => Cur_Arm);
         Gz_Joints.Set_Pose (gripper_hand_joint, Roll => Cur_Hand);

         --  Also update gripper link poses for external consumers
         Gz_Links.Set_Pose (gripper,      Roll => Cur_Arm);
         Gz_Links.Set_Pose (gripper_hand, Roll => Cur_Hand);

         Pace.Log.Wait (duration(dT));
      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E, "Tugbot Gripper_Task error");
   end Gripper_Task;

   --
   --  Internal simulation start message body
   --
   procedure Input (Obj : in Start) is
   begin
      Pace.Log.Put_Line ("Tugbot Start -- simulation tasks running.");
      Pace.Log.Trace (Obj);
   end Input;

   -------------------------------------------------------------------------
   --  WMI (Woman-Machine Interface) web dispatch action bodies
   --
   --  Following delivery_vehicle / uio-dbw.adb patterns:
   --    - use Pace.Server.Dispatch  (Action, Save_Action, Xml_Set, Default)
   --    - use Pace.Server.Xml       (Item, Put_Content) inside each body
   --    - use Pace.Strings          (+Obj.Set for String<->Unbounded_String)
   --    - Drive_State'Value(+Obj.Set) for enum from URL set= parameter
   --    - Pace.Server.Keys.Value("key", default) for multi-param CGI style
   -------------------------------------------------------------------------

   use Pace.Server.Dispatch;

   -------------------------------------------------------------------------
   --  Navigate: direction command via set= parameter
   --  e.g. TUGBOT.NAVIGATE?set=MOVING_FORWARD
   --  Like delivery_vehicle Gear?set=FORWARD using Drive_State'Value
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Navigate) is
      use Pace.Server.Xml;
      Dir_Str : constant String := +Obj.Set;
   begin
      State.Set_Drive (Drive_State'Value (Dir_Str));
      Pace.Server.Put_Data (Item ("direction", Dir_Str));
      Pace.Log.Trace (Obj);
   exception
      when Constraint_Error =>
         Pace.Server.Put_Data
           (Item ("error", "invalid direction: " & Dir_Str &
                  " -- use STOPPED|MOVING_FORWARD|MOVING_BACKWARD|TURNING_LEFT|TURNING_RIGHT"));
   end Inout;

   -------------------------------------------------------------------------
   --  Set_Speed: normalized speed via set= parameter
   --  e.g. TUGBOT.SET_SPEED?set=0.8
   --  Like delivery_vehicle Accelerate?set=1.0 using Float'Value
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Set_Speed) is
      use Pace.Server.Xml;
      Spd : constant Long_Float := Long_Float (Float'Value (+Obj.Set));
   begin
      State.Set_Speed (Spd);
      Pace.Server.Put_Data (Item ("speed", Float (Spd)));
      Pace.Log.Trace (Obj);
   exception
      when Constraint_Error =>
         Pace.Server.Put_Data
           (Item ("error", "invalid speed: " & (+Obj.Set) & " -- expected 0.0..1.0"));
   end Inout;

   -------------------------------------------------------------------------
   --  Drive: joystick-style multi-param command
   --  e.g. TUGBOT.DRIVE?direction=MOVING_FORWARD&speed=0.8
   --  Like delivery_vehicle Joystick?x=0.5&y=0.8 using Pace.Server.Keys.Value
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Drive) is
      use Pace.Server.Xml;
      Dir_Str : constant String     := Pace.Server.Keys.Value ("direction", "STOPPED");
      Spd     : constant Long_Float := Long_Float (Pace.Server.Keys.Value ("speed", 1.0));
   begin
      State.Set_Drive (Drive_State'Value (Dir_Str));
      State.Set_Speed (Spd);
      Pace.Server.Put_Data (Item ("direction", Dir_Str) &
                            Item ("speed",     Float (Spd)));
      Pace.Log.Trace (Obj);
   exception
      when Constraint_Error =>
         Pace.Server.Put_Data (Item ("error", "invalid drive params: " & Dir_Str));
   end Inout;

   -------------------------------------------------------------------------
   --  Gripper_Action: open/close end-effector via set= parameter
   --  e.g. TUGBOT.GRIPPER?set=CLOSED
   --  Like delivery_vehicle Gear?set=FORWARD using Gripper_State'Value
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Gripper_Action) is
      use Pace.Server.Xml;
      Grp_Str : constant String := +Obj.Set;
   begin
      State.Set_Gripper (Gripper_State'Value (Grp_Str));
      Pace.Server.Put_Data (Item ("gripper", Grp_Str));
      Pace.Log.Trace (Obj);
   exception
      when Constraint_Error =>
         Pace.Server.Put_Data (Item ("error", "invalid gripper: " & Grp_Str &
                               " -- use OPEN|CLOSED"));
   end Inout;

   -------------------------------------------------------------------------
   --  Light: enable/disable warning beacon via set= parameter
   --  e.g. TUGBOT.LIGHT?set=TRUE
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Light) is
      use Pace.Server.Xml;
      Enabled : constant Boolean := +Obj.Set = "TRUE";
   begin
      State.Set_Light (Enabled);
      Pace.Server.Put_Data (Item ("light", Enabled));
      Pace.Log.Trace (Obj);
   end Inout;

   -------------------------------------------------------------------------
   --  Get_Status: XML snapshot of full robot state
   --  e.g. TUGBOT.GET_STATUS
   --  Like delivery_vehicle Get_All_Gauges / Get_Move_Status
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Get_Status) is
      use Pace.Server.Xml;
   begin
      Put_Content ("");   -- sets content-type: application/xml
      Obj.Set := +(Item ("status",
                         Item ("drive",   Drive_State'Image   (State.Get_Drive))   &
                         Item ("gripper", Gripper_State'Image (State.Get_Gripper)) &
                         Item ("light",   State.Get_Light)                          &
                         Item ("x",       Float (State.Get_X))                      &
                         Item ("y",       Float (State.Get_Y))                      &
                         Item ("heading", Float (State.Get_Heading))));
      Pace.Server.Put_Data (+Obj.Set);
      Pace.Log.Trace (Obj);
   end Inout;

   -------------------------------------------------------------------------
   --  Heading_Monitor: server-push live heading stream
   --  e.g. TUGBOT.HEADING_MONITOR  (keep-alive, streams heading updates)
   --  Like delivery_vehicle Compass using Pace.Server.Push_Content + loop
   -------------------------------------------------------------------------
   procedure Inout (Obj : in out Heading_Monitor) is
      use Pace.Server.Xml;
   begin
      Pace.Server.Push_Content;
      Pace.Log.Trace (Obj);
      loop
         Pace.Server.Put_Data (Item ("heading", Float (State.Get_Heading)),
                               Raw => True);
         Pace.Log.Wait (0.5);
      end loop;
   end Inout;

begin
   --
   --  Register all WMI web dispatch actions during package elaboration.
   --  Defaults follow delivery_vehicle / uio-dbw.adb Save_Action patterns:
   --    +"value"  -- command default if no set= parameter supplied
   --    Xml_Set   -- marks query as returning XML output
   --    Default   -- no default (multi-param or streaming actions)
   --
   Save_Action (Navigate'      (Pace.Msg with Set => +"STOPPED"));
   Save_Action (Set_Speed'     (Pace.Msg with Set => +"1.0"));
   Save_Action (Drive'         (Pace.Msg with Set => Default));
   Save_Action (Gripper_Action'(Pace.Msg with Set => +"OPEN"));
   Save_Action (Light'         (Pace.Msg with Set => +"FALSE"));
   Save_Action (Get_Status'    (Pace.Msg with Set => Xml_Set));
   Save_Action (Heading_Monitor'(Pace.Msg with Set => Default));

end Tugbot;
