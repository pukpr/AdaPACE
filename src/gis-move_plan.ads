with Gis;
with Str; use Str;
with Ada.Containers.Vectors;
with Gkb;

generic
   with package Kb is new Gkb (<>);
 package Gis.Move_Plan is

   pragma Elaborate_Body;

   package Checkpoint_Vector is new Ada.Containers.Vectors (Positive, Checkpoint, "=");

   type Move_Plan_Data is
      record
         Id : Bstr.Bounded_String;
         Plan : Bstr.Bounded_String := S2b ("test");
         -- if start time is zero than start ASAP
         Start_Time : Duration;
         -- defines the width of the corridor that it is okay for the vehicle
         -- to travel in between waypoints
         -- the default value essentially means no corridor
         Max_Corridor : Integer := 100; -- should be Integer maximum
         Points : Checkpoint_Vector.Vector;

         -- if false then it is okay to start the mission after the start_time
         -- if true then the mission must start at the start_time
         No_Later_Than : Boolean := False;
      end record;

   procedure Add_Move_Plan (Id : Bstr.Bounded_String;
                            Data : Move_Plan_Data);

   procedure Remove_Move_Plan (Id : Bstr.Bounded_String);

   procedure Get_Move_Plan (Id : in Bstr.Bounded_String;
                            Found_It : out Boolean;
                            Data : out Move_Plan_Data);

end Gis.Move_Plan;
