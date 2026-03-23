with Panda;
with Pace.Log;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics;
with Ses.Pp;

procedure Panda_Control is
   use Panda;
   use Ada.Numerics;
   use Ada.Numerics.Long_Elementary_Functions;

   task Control_Task;
   task body Control_Task is
      function ID is new Pace.Log.Unit_ID;
      Time : Long_Float := 0.0;
      dT   : constant := 0.05;
      
      Joint_Pos : Long_Float;
      Finger_Pos : Long_Float;
   begin
      Pace.Log.Agent_Id (ID);
      Pace.Log.Put_Line ("Panda Robot Joint Position Controller Started.");

      loop
         -- Exercise Arm Joints (1-7) with sinusoidal motion
         for J in Joints range Panda_Joint1 .. Panda_Joint7 loop
            -- Each joint gets a slightly different frequency/phase
            Joint_Pos := 0.5 * sin(Time * (1.0 + 0.1 * Long_Float(Joints'Pos(J))));
            Gz.Set_Pose(J, Roll => Joint_Pos);
         end loop;

         -- Exercise Finger Joints (Open/Close)
         Finger_Pos := 0.02 * (0.5 + 0.5 * sin(Time * 2.0)); -- range 0 to 0.04
         Gz.Set_Pose(Panda_Finger_Joint1, Roll => Finger_Pos);
         Gz.Set_Pose(Panda_Finger_Joint2, Roll => Finger_Pos);

         Pace.Log.Wait (dT);
         Time := Time + dT;
      end loop;
   end Control_Task;

begin
   Ses.Pp.Parser;
end Panda_Control;
