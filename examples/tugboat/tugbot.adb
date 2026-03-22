with Pace.Log;
with Pace.Server;
with Pace.Server.Dispatch;
with Pace.Strings;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;
with Ada.Strings.Fixed;

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

         --  Command chassis pose via link (Set_Pose → Pose component)
         Gz_Links.Set_Pose (base_link, X => X, Y => Y, Yaw => H);

         --  Command drive wheel angular velocity via link (Set_Rot → SetAngularVelocity)
         --  Yaw axis aligns with the wheel's spin axis in the SDF
         Gz_Links.Set_Rot (wheel_left,  Yaw => L_Omega);
         Gz_Links.Set_Rot (wheel_right, Yaw => R_Omega);

         --  Command drive wheel joint positions (integrating angle for visual fidelity)
         Gz_Joints.Set_Pose (wheel_left_joint,  Roll => L_Omega);
         Gz_Joints.Set_Pose (wheel_right_joint, Roll => R_Omega);

         --  Caster wheels (ball joints): propagate chassis heading for visual alignment
         Gz_Links.Set_Pose (wheel_front, Yaw => H);
         Gz_Links.Set_Pose (wheel_back,  Yaw => H);

         --  IMU link tracks chassis heading (fixed joint, orientation update)
         Gz_Links.Set_Pose (imu_link, Yaw => H);

         Pace.Log.Wait (dT);
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

         --  All sensor links are fixed to base_link in the SDF; reflect their
         --  world pose so external tools can read sensor positions from shared memory
         Gz_Links.Set_Pose (camera_front, X => X, Y => Y, Yaw => H);
         Gz_Links.Set_Pose (camera_back,  X => X, Y => Y, Yaw => H + Pi);
         Gz_Links.Set_Pose (scan_front,   X => X, Y => Y, Yaw => H);
         Gz_Links.Set_Pose (scan_back,    X => X, Y => Y, Yaw => H + Pi);
         Gz_Links.Set_Pose (scan_omni,    X => X, Y => Y, Yaw => H);

         Pace.Log.Wait (dT * 2.0);   -- sensors update at half the drive rate
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
            --  Set_Pose on a revolute joint → JointPosition (Roll = joint angle)
            Gz_Joints.Set_Pose (warnign_light_joint, Roll => Angle);
         end if;
         Pace.Log.Wait (dT);
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

         --  First-order filter toward target (10 % step per cycle ≈ smooth servo)
         Cur_Arm  := Cur_Arm  + (Tgt_Arm  - Cur_Arm)  * 0.1;
         Cur_Hand := Cur_Hand + (Tgt_Hand - Cur_Hand) * 0.1;

         --  Set_Pose on revolute joint → JointPosition in Gazebo
         Gz_Joints.Set_Pose (gripper_joint,      Roll => Cur_Arm);
         Gz_Joints.Set_Pose (gripper_hand_joint, Roll => Cur_Hand);

         --  Also update gripper link poses for external consumers
         Gz_Links.Set_Pose (gripper,      Roll => Cur_Arm);
         Gz_Links.Set_Pose (gripper_hand, Roll => Cur_Hand);

         Pace.Log.Wait (dT);
      end loop;

   exception
      when E : others =>
         Pace.Log.Ex (E, "Tugbot Gripper_Task error");
   end Gripper_Task;

   --
   --  Ada Command Pattern bodies
   --

   procedure Input (Obj : in Navigate) is
   begin
      State.Set_Drive (Obj.Direction);
      State.Set_Speed (Obj.Speed);
      Pace.Log.Trace (Obj);
      Pace.Log.Put_Line ("Navigate => " & Drive_State'Image (Obj.Direction) &
                         "  speed=" & Long_Float'Image (Obj.Speed));
   end Input;

   procedure Input (Obj : in Set_Gripper) is
   begin
      State.Set_Gripper (Obj.State);
      Pace.Log.Trace (Obj);
      Pace.Log.Put_Line ("Gripper  => " & Gripper_State'Image (Obj.State));
   end Input;

   procedure Input (Obj : in Set_Warning_Light) is
   begin
      State.Set_Light (Obj.Enabled);
      Pace.Log.Trace (Obj);
      Pace.Log.Put_Line ("Light    => " & Boolean'Image (Obj.Enabled));
   end Input;

   procedure Output (Obj : out Get_Status) is
   begin
      Obj.Drive   := State.Get_Drive;
      Obj.Gripper := State.Get_Gripper;
      Obj.Light   := State.Get_Light;
      Obj.X       := State.Get_X;
      Obj.Y       := State.Get_Y;
      Obj.Heading := State.Get_Heading;
      Pace.Log.Trace (Obj);
   end Output;

   procedure Input (Obj : in Start) is
   begin
      Pace.Log.Put_Line ("Tugbot Start received -- simulation tasks running.");
      Pace.Log.Trace (Obj);
   end Input;

   -------------------------------------------------------------------------
   --  PACE Web Server Dispatch Actions
   --
   --  Remote manipulation URL scheme:
   --
   --  Navigate:
   --    GET http://host:8080/Tugbot.Navigate_Action?set=<xml><direction>forward</direction><speed>0.8</speed></xml>
   --    direction: forward | backward | left | right | stop
   --    speed:     0.0 .. 1.0  (normalised; default 1.0)
   --
   --  Gripper:
   --    GET http://host:8080/Tugbot.Gripper_Action?set=<xml><state>close</state></xml>
   --    state: open | close
   --
   --  Warning light:
   --    GET http://host:8080/Tugbot.Light_Action?set=<xml><enabled>true</enabled></xml>
   --    enabled: true | false
   --
   --  Status query (no parameters required):
   --    GET http://host:8080/Tugbot.Status_Action
   -------------------------------------------------------------------------

   use Pace.Server.Dispatch;
   use Pace.Strings;
   use Ada.Strings.Fixed;

   --  Shared helper: extract the inner text of the first occurrence of <Tag>...</Tag>
   function Extract_Tag (Doc : String; Tag : String) return String is
      Open  : constant String  := "<" & Tag & ">";
      Close : constant String  := "</" & Tag & ">";
      S     : constant Natural := Index (Doc, Open);
      E     : constant Natural := Index (Doc, Close);
   begin
      if S > 0 and then E > S then
         return Doc (S + Open'Length .. E - 1);
      end if;
      return "";
   end Extract_Tag;

   --
   --  Navigate_Action
   --
   type Navigate_Action is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Navigate_Action);
   procedure Inout (Obj : in out Navigate_Action) is
      Doc     : constant String := U2s (Obj.Set);
      Dir_Str : constant String := Extract_Tag (Doc, "direction");
      Spd_Str : constant String := Extract_Tag (Doc, "speed");
      Msg     : Navigate;
   begin
      if    Dir_Str = "forward"  then Msg.Direction := Moving_Forward;
      elsif Dir_Str = "backward" then Msg.Direction := Moving_Backward;
      elsif Dir_Str = "left"     then Msg.Direction := Turning_Left;
      elsif Dir_Str = "right"    then Msg.Direction := Turning_Right;
      else                            Msg.Direction := Stopped;
      end if;

      Msg.Speed := (if Spd_Str /= "" then Long_Float'Value (Spd_Str) else 1.0);
      Input (Msg);
      Pace.Server.Put_Data
        ("<result><direction>" & Drive_State'Image (Msg.Direction) &
         "</direction><speed>"  & Long_Float'Image  (Msg.Speed)    &
         "</speed></result>");
      Pace.Log.Trace (Obj);
   end Inout;

   --
   --  Gripper_Action
   --
   type Gripper_Action is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Gripper_Action);
   procedure Inout (Obj : in out Gripper_Action) is
      Doc : constant String := U2s (Obj.Set);
      Msg : Set_Gripper;
   begin
      Msg.State := (if Extract_Tag (Doc, "state") = "close" then Closed else Open);
      Input (Msg);
      Pace.Server.Put_Data
        ("<result><gripper>" & Gripper_State'Image (Msg.State) &
         "</gripper></result>");
      Pace.Log.Trace (Obj);
   end Inout;

   --
   --  Light_Action
   --
   type Light_Action is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Light_Action);
   procedure Inout (Obj : in out Light_Action) is
      Doc : constant String := U2s (Obj.Set);
      Msg : Set_Warning_Light;
   begin
      Msg.Enabled := (Extract_Tag (Doc, "enabled") = "true");
      Input (Msg);
      Pace.Server.Put_Data
        ("<result><light>" & Boolean'Image (Msg.Enabled) &
         "</light></result>");
      Pace.Log.Trace (Obj);
   end Inout;

   --
   --  Status_Action
   --
   type Status_Action is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Status_Action);
   procedure Inout (Obj : in out Status_Action) is
      S : Get_Status;
   begin
      Output (S);
      Pace.Server.Put_Data
        ("<status>" &
         "<drive>"   & Drive_State'Image   (S.Drive)   & "</drive>"   &
         "<gripper>" & Gripper_State'Image (S.Gripper) & "</gripper>" &
         "<light>"   & Boolean'Image       (S.Light)   & "</light>"   &
         "<x>"       & Long_Float'Image    (S.X)       & "</x>"       &
         "<y>"       & Long_Float'Image    (S.Y)       & "</y>"       &
         "<heading>" & Long_Float'Image    (S.Heading) & "</heading>" &
         "</status>");
      Pace.Log.Trace (Obj);
   end Inout;

begin
   --
   --  Register all web dispatch actions during package elaboration.
   --  The PACE web server will route incoming HTTP requests to these handlers.
   --
   Save_Action (Navigate_Action'(Pace.Msg with Set => Default));
   Save_Action (Gripper_Action' (Pace.Msg with Set => Default));
   Save_Action (Light_Action'   (Pace.Msg with Set => Default));
   Save_Action (Status_Action'  (Pace.Msg with Set => Default));

end Tugbot;
