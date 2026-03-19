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
   -- GAIT CONTROLLER: Handles legs and pelvis
   ----------------------------------------------------------------------------
   task Gait_Controller;
   task body Gait_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.5 * Vel_Mult;
      Phase : Long_Float;
      
      -- Amplitudes
      Hip_P_Amp   : constant := 0.3;
      Knee_P_Amp  : constant := 0.4;
      Ankle_P_Amp : constant := 0.15;
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         -- Legs (180 deg out of phase)
         Gz.Set_Rot(LThigh, Pitch => Hip_P_Amp * sin(Phase));
         Gz.Set_Rot(RThigh, Pitch => Hip_P_Amp * sin(Phase + Pi));
         
         Gz.Set_Rot(LTibia, Pitch => Knee_P_Amp * (0.5 + 0.5 * sin(Phase - Pi/2.0)));
         Gz.Set_Rot(RTibia, Pitch => Knee_P_Amp * (0.5 + 0.5 * sin(Phase + Pi/2.0)));
         
         Gz.Set_Rot(LAnkle, Pitch => Ankle_P_Amp * cos(Phase));
         Gz.Set_Rot(RAnkle, Pitch => Ankle_P_Amp * cos(Phase + Pi));

         -- Pelvis/Hip Roll for weight shifting
         Gz.Set_Rot(LHip, Roll => 0.1 * cos(Phase));
         Gz.Set_Rot(RHip, Roll => 0.1 * cos(Phase));

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Gait_Controller;

   ----------------------------------------------------------------------------
   -- ARM CONTROLLER: Handles shoulders, elbows, wrists
   ----------------------------------------------------------------------------
   task Arm_Controller;
   task body Arm_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.5 * Vel_Mult;
      Phase : Long_Float;
      
      Arm_S_Amp : constant := 0.3;
      Elbow_P   : constant := 0.4; -- Fixed bend
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         -- Shoulders (In sync with opposite leg)
         Gz.Set_Rot(LShoulder, Pitch => Arm_S_Amp * sin(Phase + Pi));
         Gz.Set_Rot(RShoulder, Pitch => Arm_S_Amp * sin(Phase));
         
         -- Slight elbow movement
         Gz.Set_Rot(LElbow, Pitch => Elbow_P + 0.1 * sin(Phase));
         Gz.Set_Rot(RElbow, Pitch => Elbow_P + 0.1 * sin(Phase + Pi));

         -- Wrists
         Gz.Set_Rot(LWrist, Yaw => 0.1 * sin(Phase));
         Gz.Set_Rot(RWrist, Yaw => 0.1 * sin(Phase + Pi));

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Arm_Controller;

   ----------------------------------------------------------------------------
   -- POSTURE CONTROLLER: Handles torso, neck, head
   ----------------------------------------------------------------------------
   task Posture_Controller;
   task body Posture_Controller is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      Freq : constant Long_Float := 1.5 * Vel_Mult;
      Phase : Long_Float;
   begin
      Pace.Log.Agent_Id (ID);
      loop
         Phase := 2.0 * Pi * Freq * Time;

         -- Torso sway
         Gz.Set_Rot(Torso, Roll => 0.05 * sin(Phase), Pitch => 0.05);
         
         -- Head/Neck stabilization (Counter-sway)
         Gz.Set_Rot(Neck, Yaw   => 0.05 * sin(Phase));
         Gz.Set_Rot(Head, Pitch => 0.02 * cos(Phase));

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Posture_Controller;

begin
   Ses.Pp.Parser;
exception
   when others =>
      Ses.Os_Exit(0);
end Walk_Main;
