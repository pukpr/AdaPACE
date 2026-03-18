with Pace.Log;
with Pace.Socket;

package body Assembly is

   -- Conveyor implementation
   procedure Input (Obj : in Load_Tray) is
      Ack : Tray_Loaded;
   begin
      Pace.Log.Put_Line ("Conveyor: Moving tray into work cell...");
      Pace.Log.Wait (1.0);
      Pace.Log.Put_Line ("Conveyor: Tray correctly positioned.");
      Pace.Socket.Send (Ack);
   end Input;

   -- PLC callback for Conveyor
   procedure Input (Obj : in Tray_Loaded) is
   begin
      Pace.Log.Put_Line ("PLC: Confirmed Tray Loaded.");
   end Input;

   -- Vision implementation
   procedure Input (Obj : in Inspect_Tray) is
      Result : Inspection_Result;
   begin
      Pace.Log.Put_Line ("Vision: Inspecting empty tray for debris...");
      Pace.Log.Wait (0.5);
      Result.Offset_X := 0.01; -- Simulated offset
      Result.Offset_Y := -0.02;
      Pace.Log.Put_Line ("Vision: Inspection complete. Sending offsets to PLC.");
      Pace.Socket.Send (Result);
   end Input;

   -- PLC callback for Vision
   procedure Input (Obj : in Inspection_Result) is
   begin
      Pace.Log.Put_Line ("PLC: Received Inspection Result (" & 
                         Float'Image(Obj.Offset_X) & "," & 
                         Float'Image(Obj.Offset_Y) & ")");
   end Input;

   -- Robot A implementation
   procedure Input (Obj : in Prepare_A) is
   begin
      Pace.Log.Put_Line ("Robot A (SCARA): Moving to pick position...");
      Pace.Log.Wait (0.8);
      Pace.Log.Put_Line ("Robot A: In pick position, waiting for PLC.");
   end Input;

   procedure Input (Obj : in Place_Cells) is
      Ack : Placement_Done;
   begin
      Pace.Log.Put_Line ("Robot A: Placing cells with offsets " & 
                         Float'Image(Obj.Offset_X) & "," & 
                         Float'Image(Obj.Offset_Y));
      Pace.Log.Wait (1.2);
      Pace.Log.Put_Line ("Robot A: Cell placement complete.");
      Pace.Socket.Send (Ack);
   end Input;

   -- PLC callback for Robot A
   procedure Input (Obj : in Placement_Done) is
   begin
      Pace.Log.Put_Line ("PLC: Robot A placement confirmed.");
   end Input;

   -- Robot B implementation
   procedure Input (Obj : in Pick_Busbar) is
      Ack : Busbar_Cleared;
   begin
      Pace.Log.Put_Line ("Robot B (6-Axis): Picking heavy busbar...");
      Pace.Log.Wait (1.5);
      Pace.Log.Put_Line ("Robot B: Busbar picked and clear of Robot C's envelope.");
      Pace.Socket.Send (Ack);
   end Input;

   -- PLC callback for Robot B
   procedure Input (Obj : in Busbar_Cleared) is
   begin
      Pace.Log.Put_Line ("PLC: Robot B cleared. Safe for Robot C to weld.");
   end Input;

   -- Robot C implementation
   procedure Input (Obj : in Weld_Cells) is
      Ack : Welding_Done;
   begin
      Pace.Log.Put_Line ("Robot C (SCARA): Performing ultrasonic weld...");
      Pace.Log.Wait (1.8);
      Pace.Log.Put_Line ("Robot C: Welding complete.");
      Pace.Socket.Send (Ack);
   end Input;

   -- PLC callback for Robot C
   procedure Input (Obj : in Welding_Done) is
   begin
      Pace.Log.Put_Line ("PLC: Robot C welding confirmed.");
   end Input;

end Assembly;
