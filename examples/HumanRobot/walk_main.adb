with Humanoid;
with Pace.Log;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;
with Ses.Pp;

procedure Walk_Main is
   use Humanoid;
   use Ada.Numerics;
   use Ada.Numerics.Long_Elementary_Functions;

   task Walking_Agent;
   task body Walking_Agent is
      function ID is new Pace.Log.Unit_ID;
      
      Time : Long_Float := 0.0;
      dT   : constant := 0.02; -- 50Hz control loop
      
      -- Gait Parameters (Angles in Radians)
      Freq : constant Long_Float := 1.5; -- Hz
      Hip_Pitch_Amp : constant Long_Float := 0.3;
      Knee_Pitch_Amp : constant Long_Float := 0.4;
      Shoulder_Pitch_Amp : constant Long_Float := 0.3;
      
      Phase : Long_Float;
      
      L_Hip_P, R_Hip_P : Long_Float;
      L_Knee_P, R_Knee_P : Long_Float;
      L_Shoulder_P, R_Shoulder_P : Long_Float;
      Torso_Roll : Long_Float;
      
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Humanoid Walking Agent Started.");

      loop
         Phase := 2.0 * Pi * Freq * Time;
         
         -- Hips (Out of phase)
         L_Hip_P := Hip_Pitch_Amp * sin(Phase);
         R_Hip_P := Hip_Pitch_Amp * sin(Phase + Pi);
         
         -- Knees (Bend during swing phase)
         -- Knee is mostly 0 when leg is back, and bends when leg moves forward
         L_Knee_P := Knee_Pitch_Amp * (0.5 + 0.5 * sin(Phase - Pi/2.0));
         R_Knee_P := Knee_Pitch_Amp * (0.5 + 0.5 * sin(Phase + Pi/2.0));
         
         -- Shoulders (Opposite to hips)
         L_Shoulder_P := Shoulder_Pitch_Amp * sin(Phase + Pi);
         R_Shoulder_P := Shoulder_Pitch_Amp * sin(Phase);
         
         -- Torso sway
         Torso_Roll := 0.05 * sin(Phase);

         -- Apply Rotations
         Gz.Set_Rot(LThigh, Pitch => L_Hip_P);
         Gz.Set_Rot(RThigh, Pitch => R_Hip_P);
         
         Gz.Set_Rot(LTibia, Pitch => L_Knee_P);
         Gz.Set_Rot(RTibia, Pitch => R_Knee_P);
         
         Gz.Set_Rot(LShoulder, Pitch => L_Shoulder_P);
         Gz.Set_Rot(RShoulder, Pitch => R_Shoulder_P);
         
         Gz.Set_Rot(Torso, Roll => Torso_Roll);

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Walking_Agent;

begin
   Ses.Pp.Parser;
exception
   when others =>
      Ses.Os_Exit(0);
end Walk_Main;
