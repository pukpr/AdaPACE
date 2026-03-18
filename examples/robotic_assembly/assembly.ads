with Pace;

package Assembly is
   pragma Elaborate_Body;

   -- 1. Conveyor Control
   type Load_Tray is new Pace.Msg with null record;
   procedure Input (Obj : in Load_Tray); -- PLC -> Conveyor

   type Tray_Loaded is new Pace.Msg with null record;
   procedure Input (Obj : in Tray_Loaded); -- Conveyor -> PLC

   -- 2. Vision System
   type Inspect_Tray is new Pace.Msg with null record;
   procedure Input (Obj : in Inspect_Tray); -- PLC -> Vision

   type Inspection_Result is new Pace.Msg with record
      Offset_X : Float;
      Offset_Y : Float;
   end record;
   procedure Input (Obj : in Inspection_Result); -- Vision -> PLC

   -- 3. Robot A (SCARA - Cell Placement)
   type Prepare_A is new Pace.Msg with null record;
   procedure Input (Obj : in Prepare_A); -- PLC -> Robot A

   type Place_Cells is new Pace.Msg with record
      Offset_X : Float;
      Offset_Y : Float;
   end record;
   procedure Input (Obj : in Place_Cells); -- PLC -> Robot A

   type Placement_Done is new Pace.Msg with null record;
   procedure Input (Obj : in Placement_Done); -- Robot A -> PLC

   -- 4. Robot B (6-axis - Busbar Handling)
   type Pick_Busbar is new Pace.Msg with null record;
   procedure Input (Obj : in Pick_Busbar); -- PLC -> Robot B

   type Busbar_Cleared is new Pace.Msg with null record;
   procedure Input (Obj : in Busbar_Cleared); -- Robot B -> PLC (Clear of envelope)

   -- 5. Robot C (SCARA - Welder)
   type Weld_Cells is new Pace.Msg with null record;
   procedure Input (Obj : in Weld_Cells); -- PLC -> Robot C

   type Welding_Done is new Pace.Msg with null record;
   procedure Input (Obj : in Welding_Done); -- Robot C -> PLC

end Assembly;
