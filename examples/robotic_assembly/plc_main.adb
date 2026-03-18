with Pace.Log;
with Pace.Socket;
with Assembly;
with Ada.Text_IO;
with Ses.Pp;

procedure PLC_Main is
   function ID is new Pace.Log.Unit_ID;

   task Conductor;
   task body Conductor is
      Cmd_Load     : Assembly.Load_Tray;
      Cmd_Inspect  : Assembly.Inspect_Tray;
      Cmd_PrepA    : Assembly.Prepare_A;
      Cmd_PlaceA   : Assembly.Place_Cells;
      Cmd_PickB    : Assembly.Pick_Busbar;
      Cmd_WeldC    : Assembly.Weld_Cells;
   begin
      Pace.Log.Wait (2.0); -- Let everything boot

      loop
         Pace.Log.Put_Line ("PLC: --- Starting New Assembly Cycle ---");

         -- Concurrent Action: Load Tray AND Prepare Robot A
         Pace.Log.Put_Line ("PLC: Commanding Conveyor to Load and Robot A to Prepare...");
         Pace.Socket.Send (Cmd_PrepA, Ack => False);
         Pace.Socket.Send (Cmd_Load, Ack => True); -- Wait for tray to arrive

         -- Once Tray is loaded, Start Inspection
         Pace.Log.Put_Line ("PLC: Tray at station. Starting Vision Inspection...");
         -- Synchronous call: blocks until Vision's Inout(Obj) returns
         Pace.Socket.Send_Inout (Cmd_Inspect); 
         
         Pace.Log.Put_Line ("PLC: Received Vision Offsets (" & 
                            Float'Image(Cmd_Inspect.Offset_X) & "," & 
                            Float'Image(Cmd_Inspect.Offset_Y) & ")");

         -- High Speed Core: Placement
         Pace.Log.Put_Line ("PLC: Commanding Robot A to Place with vision adjustments.");
         Cmd_PlaceA.Offset_X := Cmd_Inspect.Offset_X;
         Cmd_PlaceA.Offset_Y := Cmd_Inspect.Offset_Y;
         Pace.Socket.Send (Cmd_PlaceA, Ack => True);

         -- Concurrent: Pick Busbar (B) and Prepare Welding (C)
         -- BUT Robot B must clear before welding start.
         Pace.Log.Put_Line ("PLC: Commanding Robot B to Pick Busbar.");
         Pace.Socket.Send (Cmd_PickB, Ack => True); -- Wait for Robot B to signal Clear

         Pace.Log.Put_Line ("PLC: Robot B clear. Commanding Robot C to Weld.");
         Pace.Socket.Send (Cmd_WeldC, Ack => True);

         Pace.Log.Put_Line ("PLC: --- Cycle Complete. Indexing... ---");
         Pace.Log.Wait (2.0);
      end loop;
   end Conductor;

begin
   Pace.Log.Agent_Id (ID);
   Ada.Text_IO.Put_Line ("PLC Conductor (Node 1) Started.");
   Ses.Pp.Parser;
exception
    when others =>
        Ses.Os_Exit (0);
end PLC_Main;
