with Pace.Notify;
with Ada.Strings.Unbounded;
with Gis.Location;

generic
   with package Loc is new Gis.Location (<>);
   Do_Monitor_Progress : Boolean := True;
package Gis.Route_Following is

   pragma Elaborate_Body;

   type Clear_Route is new Pace.Msg with null record;
   procedure Input (Obj : in Clear_Route);

   subtype Cp_Range is Integer range 0 .. 100;

   type Add_Point is new Pace.Msg with
      record
         Index : Cp_Range;
         Radius : Float;
         Point : Checkpoint;
         Heading : Float;
         -- setting this means the point is for finding the correct
         -- orientation instead of finding the correct position
         -- The actual value means how close to Heading the orientation
         -- must be to be considered at that waypoint
         Heading_Restriction : Float := 0.0;  -- degrees
      end record;
   procedure Input (Obj : in Add_Point);

   type Start is new Pace.Msg with
      record
         Index : Integer;
      end record;
   procedure Input (Obj : in Start);

   type Stop is new Pace.Msg with null record;
   procedure Input (Obj : in Stop);

   type Steer is (Straight, Left, Right);

   type Monitor_Progress is new Pace.Notify.Subscription with
      record
         Index : Integer;
         Heading_Correction : Float;
         Distance_To_Control_Point : Float;
         Reached_Control_Point : Boolean;
         Steer_Correction : Steer;
         Pitch, Roll : Float;
         Time_To_Control_Point : Float;
         Remaining_Distance : Float;
         Complete : Boolean;
         Release : Boolean := False;
      end record;


   type Get_Current_Waypoint is new Pace.Msg with
      record
         Route_In_Progress : Boolean;
         Corrected_Heading : Float;
         Distance_From_Corridor : Integer;
         Point : Checkpoint;
         Dist_To_Last_Point : Float; -- meters
         Dist_To_Next_Point : Float; -- meters
         Time_To_Last_Point : Duration;
         Time_To_Next_Point : Duration;
      end record;
   procedure Output (Obj : out Get_Current_Waypoint);

   type Recover is new Pace.Msg with null record;
   procedure Input (Obj : in Recover);

private
   pragma Inline (Input);
end Gis.Route_Following;
