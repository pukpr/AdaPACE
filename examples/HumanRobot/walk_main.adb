with Humanoid;
with Pace.Log;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;
with Ses.Pp;

procedure Walk_Main is
   use Humanoid;
   use Ada.Numerics;
   use Ada.Numerics.Long_Elementary_Functions;

   -- Global Velocity Multiplier
   Vel_Mult : constant Long_Float := 1.0;
   
   -- Common timing
   dT : constant := 0.02; 

   ----------------------------------------------------------------------------
   -- GAIT CONTROLLER: Handles legs and pelvis joints
   ----------------------------------------------------------------------------
   task Gait_Controller;
   task body Gait_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.0 * Vel_Mult;
      Phase : Long_Float;
      
      -- Amplitudes (in radians for joint positions)
      Hip_P_Amp   : constant := 0.4;
      Knee_P_Amp  : constant := 0.5;
      Ankle_P_Amp : constant := 0.2;
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         -- Leg Joints (180 deg out of phase)
         Gz_Joints.Set_Pose(LHipPitch, Roll => Hip_P_Amp * sin(Phase));
         Gz_Joints.Set_Pose(RHipPitch, Roll => Hip_P_Amp * sin(Phase + Pi));
         
         -- Knees bend forward
         Gz_Joints.Set_Pose(LKneePitch, Roll => Knee_P_Amp * (0.5 + 0.5 * sin(Phase - Pi/2.0)));
         Gz_Joints.Set_Pose(RKneePitch, Roll => Knee_P_Amp * (0.5 + 0.5 * sin(Phase + Pi/2.0)));
         
         Gz_Joints.Set_Pose(LAnklePitch, Roll => -Ankle_P_Amp * sin(Phase));
         Gz_Joints.Set_Pose(RAnklePitch, Roll => -Ankle_P_Amp * sin(Phase + Pi));

         -- Weight shifting via Hip Roll
         Gz_Joints.Set_Pose(LHipRoll, Roll => 0.1 * cos(Phase));
         Gz_Joints.Set_Pose(RHipRoll, Roll => 0.1 * cos(Phase));

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Gait_Controller;

   ----------------------------------------------------------------------------
   -- ARM CONTROLLER: Handles shoulders, elbows
   ----------------------------------------------------------------------------
   task Arm_Controller;
   task body Arm_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.0 * Vel_Mult;
      Phase : Long_Float;
      
      Arm_S_Amp : constant := 0.4;
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         -- Shoulders (Opposite to legs)
         Gz_Joints.Set_Pose(LShoulderPitch, Roll => Arm_S_Amp * sin(Phase + Pi));
         Gz_Joints.Set_Pose(RShoulderPitch, Roll => Arm_S_Amp * sin(Phase));
         
         -- Fixed elbow bend
         Gz_Joints.Set_Pose(LElbowRoll, Roll => -0.5);
         Gz_Joints.Set_Pose(RElbowRoll, Roll => 0.5);

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Arm_Controller;

   ----------------------------------------------------------------------------
   -- POSTURE CONTROLLER: Handles torso (kinematic) and head joints
   ----------------------------------------------------------------------------
   task Posture_Controller;
   task body Posture_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.0 * Vel_Mult;
      Phase : Long_Float;
      
      -- Ground Plane enforcement variables
      X_Pos : Long_Float := 0.0;
      Forward_Speed : constant Long_Float := 0.15 * Vel_Mult; -- m/s
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         Gz_Links.Set_Rot(Torso, Yaw => 0.05 * sin(Phase));
         -- Enforce Ground Plane: Fix Z at 0.35, increment X for forward motion.
         -- Using Set_Pose instead of Set_Rot to surgically control position.
         -- Gz_Links.Set_Pose(Torso, 
         --                  X => X_Pos, 
         --                  Z => 0.35, 
         --                  Roll => 0.05 * sin(Phase));
         
         -- Head/Neck stabilization
         Gz_Joints.Set_Pose(HeadYaw,   Roll => 0.1 * sin(Phase));
         Gz_Joints.Set_Pose(HeadPitch, Roll => 0.05 * cos(Phase));

         X_Pos := X_Pos + Forward_Speed * dT;
         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Posture_Controller;

begin
   Ses.Pp.Parser;
end Walk_Main;
