with Arm;
with Pace.Log;
with Ada.Numerics.Long_Elementary_Functions;
with Ses.Pp;

procedure Arm_Control is
   use Arm;
   use Ada.Numerics.Long_Elementary_Functions;

   task Control_Task;
   task body Control_Task is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      dT : constant := 0.05;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Robotic Arm Control Started (Enhanced Motion).");

      loop
         -- Increased amplitudes for more visible motion
         Gz.Set_Rot(Name => Lower_Arm, Pitch => 1.5 * sin(Time));
         Gz.Set_Rot(Name => Upper_Arm, Pitch => 2.0 * cos(Time * 0.7));
         Gz.Set_Rot(Name => Gripper,   Yaw   => 1.0 * sin(Time * 2.0));

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Control_Task;

begin
   -- Listen for shutdown signal
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);
end Arm_Control;
