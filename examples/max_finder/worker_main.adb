with Pace;
with Pace.Log;
with Pace.Socket;
with Max_Finder;
with Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
--with Sal.Gen_Math;
--with Sal.Gen_Math.Gen_Gauss;
with Pace.Ses.Pp;

procedure Worker_Main is
   function ID is new Pace.Log.Unit_ID;

   --package My_Math is new Sal.Gen_Math (Float);
   --package Elementary is new Ada.Numerics.Generic_Elementary_Functions (Float);
   --package Gaussian_Gen is new My_Math.Gen_Gauss (Elementary);

   Node_ID : constant Integer := Pace.Getenv ("PACE_NODE", 0);

   task Worker;
   task body Worker is
      Gen : Ada.Numerics.Float_Random.Generator;
      Msg : Max_Finder.Found_Value;
      Val : Float;
   begin
      Ada.Numerics.Float_Random.Reset (Gen);
      Pace.Log.Wait (1.0); -- Wait for nodes to initialize

      loop
         -- Draw from a normal distribution with mean 0 and std dev 10
         --Val := Gaussian_Gen.Gauss (Gen, Std_Dev => 10.0, Enabled => True);
         Val := Ada.Numerics.Float_Random.Random(Gen);
         
         Msg.Value := Val;
         Msg.Origin := Node_ID;

         Pace.Socket.Send (Msg, Ack => True);

         -- Delay to keep it slow
         Pace.Log.Wait (0.5);
      end loop;
   exception
      when others =>
         null; -- Exit on shutdown
   end Worker;

begin
   Pace.Log.Agent_Id; -- (ID);
   Ada.Text_IO.Put_Line ("Worker Node" & Integer'Image(Node_ID) & " Started.");

   -- Listen for shutdown signal
   Pace.Ses.Pp.Parser;
exception
    when others =>
        Pace.Log.Os_Exit (0);
end Worker_Main;
