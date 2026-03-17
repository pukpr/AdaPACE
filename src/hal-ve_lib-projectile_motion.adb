with Ada.Characters.Handling;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Hashed_Maps;
with Ada.Numerics.Elementary_Functions;
with Hal.Ve;
with Interfaces.C;
with Pace.Log;
with Pace.Semaphore;
with Pace.Socket;
with Pace.Strings;
with Pace.Surrogates;
with Pbm.Parabolic_Motion;
with Ual.Probability;

package body Hal.Ve_Lib.Projectile_Motion is

   use Pace.Strings;

   function Id is new Pace.Log.Unit_Id;

   task Agent is pragma Task_Name (Pace.Log.Name);
   entry Activate;
   end Agent;

   Below_Ground_Offset : constant Float := 5.0;
   Disable_Random_Flying : Boolean := Pace.Getenv ("DISABLE_RANDOM_FLYING", 0) /= 0;
   Exact_Landing_Spot : Boolean := Pace.Getenv ("EXACT_LANDING_SPOT", 1) = 1;
   Hla_Dt : Duration := Duration (Pace.Getenv ("HLA_DT", 0.05));
   Slow_Down_Velocity: Float := Pace.Getenv ("SLOW_DOWN_VELOCITY", 1.0);
   Trail_Counter : Integer := 1;

   -- A hashed map of munitions to counters for tracking what the next projectile id is for a specific munition type
   package Munition_Counters_Pkg is new
     Ada.Containers.Hashed_Maps (Key_Type => Bs,
                                 Element_Type => Positive,
                                 Hash => Pace.Strings.Hash,
                                 Equivalent_Keys => Pace.Strings.Bstr."=",
                                 "=" => "=");

   Munition_Counters : Munition_Counters_Pkg.Map;
   Map_Mutex : aliased Pace.Semaphore.Mutex;
   Trail_Mutex : aliased Pace.Semaphore.Mutex;

   type Projectile is record
      Theta : Float;
      Initial_Vel : Float;
      Start_Pos : Hal.Position;
      Target_Pos : Hal.Position; -- for knowing when the projectile lands
      Heading : Float;
      Start_Time : Duration;
      Uid : Hal.Ve.Name;
      Trail_Id : Bs;
      Trail_On : Boolean := False;
      Munition : Bs;
      Z_Offset : Float := 0.0; -- chosen randomly for realism
      X_Offset : Float := 0.0; -- chosen randomly for realism
   end record;

   function "=" (L, R : Projectile) return Boolean is
      use Interfaces.C;
   begin
      if L.Uid = R.Uid then
         return True;
      else
         return False;
      end if;
   end "=";

   package Projectile_List is new Ada.Containers.Doubly_Linked_Lists (Element_Type => Projectile, "=" => "=");

   Flying_Projectiles : Projectile_List.List;

   function Get_Trail_Id return Bs is
      L : Pace.Semaphore.Lock (Trail_Mutex'Access);
   begin
      Trail_Counter := Trail_Counter + 1;
      return S2b ("trail" & Pace.Strings.Trim (Trail_Counter));
   end Get_Trail_Id;

   function Create_Uid (Munition : Bs) return Hal.Ve.Name is
      L : Pace.Semaphore.Lock (Map_Mutex'Access);
      Count : Positive;
      Result : Hal.Ve.Name;
   begin
      if Munition_Counters.Contains (Munition) then
         Count := Munition_Counters.Element (Munition) + 1;
      else
         Count := 1;
      end if;
      if Count > 24 then
         Count := 1;
      end if;
      Munition_Counters.Include (Munition, Count);
      Result := Hal.Ve.To_Name (Ada.Characters.Handling.To_Lower (B2s (Munition)) & "#" & Pace.Strings.Trim (Count));
      return Result;
   end Create_Uid;

   procedure Assign_Random_Factor (Accuracy_Radius : in Float; Z_Offset : out Float; X_Offset : out Float) is
   begin
      Z_Offset := Ual.Probability.F_Random * Accuracy_Radius;
      X_Offset := Ual.Probability.F_Random * Accuracy_Radius;
      if Ual.Probability.F_Random > 0.5 then
         Z_Offset := -Z_Offset;
      end if;
      if Ual.Probability.F_Random > 0.5 then
         X_Offset := -X_Offset;
      end if;
   end Assign_Random_Factor;

   procedure Input (Obj : Launch_Projectile) is
      use Projectile_List;
      P : Projectile;
   begin
      P.Theta := Obj.Theta;
      P.Initial_Vel := Obj.Initial_Velocity / Slow_Down_Velocity;
      P.Start_Pos := Obj.Start_Pos;
      P.Heading := Obj.Heading;
      P.Start_Time := Pace.Now;
      P.Target_Pos := Obj.Target_Pos;
      P.Munition := Obj.Munition;
      P.Trail_Id := Get_Trail_Id;

      if Disable_Random_Flying then
         P.Z_Offset := 0.0;
         P.X_Offset := 0.0;
      else
         Assign_Random_Factor (Obj.Accuracy_Radius, P.Z_Offset, P.X_Offset);
      end if;
      Pace.Log.Put_Line ("creating new projectile with: theta -> " & Obj.Theta'Img &
                         " vel -> " & Obj.Initial_Velocity'Img &
                         " start_pos.x " & Obj.Start_Pos.X'Img &
                         " start_pos.y-> " & Obj.Start_Pos.Y'Img,
                         8);
      Pace.Log.Put_Line (" heading-> " & Obj.Heading'Img &
                         " time -> " & P.Start_Time'Img,
                         8);
      declare
         List_Is_Empty : Boolean := Is_Empty (Flying_Projectiles);
      begin
         P.Uid := Create_Uid (P.Munition);
         Append (Flying_Projectiles, P);
         Hal.Ve.StartPlot (Interfaces.C.To_Ada (P.Uid));
         Hal.Ve.Set("", "on", 0.0, Interfaces.C.To_Ada (P.Uid));
         if List_Is_Empty then
            Agent.Activate;
         end if;
      end;
      Hal.Ve.Launch (B2s (P.Munition), Pace.Strings.Trim (Pace.Get_Node (Obj)));
   end Input;

   -- Applies random factor incrementally, building towards the full offset
   procedure Apply_Random_Factor (P : in Projectile;
                                  Time_Of_Flight : Duration;
                                  Pos : in out Position) is
      Random_Offset_Wait : constant Duration := 1.0;
      Time_To_Full_Offset : constant Duration := 6.0;
   begin
      -- Wait a bit to begin applying the random factor so that the projectile leaves the shooter as expected
      if Time_Of_Flight > Random_Offset_Wait then
         if Time_Of_Flight > Time_To_Full_Offset then
            -- At full offset
            Pos.Z := Pos.Z + P.Z_Offset;
            Pos.X := Pos.X + P.X_Offset;
         else
            -- Incrementally add the offset
            Pos.Z := Pos.Z + P.Z_Offset * Float (Time_Of_Flight / Time_To_Full_Offset);
            Pos.X := Pos.X + P.X_Offset * Float (Time_Of_Flight / Time_To_Full_Offset);
         end if;
      end if;
   end Apply_Random_Factor;

   function Find_Exact_Landing_Spot (P : Projectile; Time_Of_Flight : Duration) return Hal.Position is

      Max_Intervals_Allowed : constant Integer := 40;

      function Get_Location (Time_Of_Flight : Duration) return Hal.Position is
         use Ada.Numerics.Elementary_Functions;
         Pos : Hal.Position;
         Delta_Vertical, Delta_Horizontal, Tangent_Angle : Float;
      begin
         Pbm.Parabolic_Motion.Calculate_Location (P.Theta, P.Initial_Vel, Time_Of_Flight, Delta_Vertical, Delta_Horizontal, Tangent_Angle);
         Pos.Z := P.Start_Pos.Z + Delta_Horizontal * Cos (P.Heading);
         -- Negating delta_horizontal term here since positive heading is flip-flopped with coordinate system
         Pos.X := P.Start_Pos.X + Delta_Horizontal * Sin (P.Heading);
         Pos.Y := P.Start_Pos.Y + Delta_Vertical;
         Apply_Random_Factor (P, Time_Of_Flight, Pos);
         return Pos;
      end Get_Location;

      -- Algorithm: Back up in time at 1/600 second intervals until above ground.
      -- Rationale: Max velocity is approx. 700 m/s.
      --   700 / 20 = At most 35 meters apart between DT updates.
      --   To get approx. 1 meter accuracy, check at 1/20/30 = 1/600 second intervals
      Time_Interval : Duration := 1.0 / 600.0;
      Interval_Index : Integer := 0;
      Result : Hal.Position;
   begin
      loop
         Interval_Index := Interval_Index + 1;
         Result := Get_Location (Time_Of_Flight - Time_Interval * Duration(Interval_Index));
         exit when Result.Y > P.Target_Pos.Y or Interval_Index > Max_Intervals_Allowed;
      end loop;
      Pace.Log.Put_Line ("Found exact landing spot at " & Hal.To_Str (Result) & " in " & Interval_Index'Img & " num intervals.", 8);
      return Result;
   end Find_Exact_Landing_Spot;

   function Has_Projectile_Landed (P : Projectile; Delta_Vertical : Float; Tangent_Angle  : Float) return Boolean is
   begin
      -- We know that the projectile has landed when it is past the peak of its
      -- parabolic path (or when the tangent angle becomes positive) and the
      -- height of it is lower than the target height.
      if Tangent_Angle > 0.0 then
         if P.Start_Pos.Y + Delta_Vertical < P.Target_Pos.Y then
            return True;
         else
            return False;
         end if;
      else
         return False;
      end if;
   end Has_Projectile_Landed;

   procedure Turn_Trail_On (P : in out Projectile) is
   begin
      P.Trail_On := True;
   end Turn_Trail_On;

   -- Moves projectile a few meters down from where it landed to avoid the occasional projectile appearing above ground.
   --   Can't turn invisible -> trails disappear.
   --   Can't unlink trails and then turn invisible -> happens out of order.
   --   Can't move to (0, 0, 0) -> makes an ugly trail.
   --   Must do this in surrogate or sometimes the other set will override it.
   type Set_Below_Ground is new Pace.Msg with
      record
         Pos : Position;
         Ori : Orientation;
         Uid : Hal.Ve.Name;
      end record;
   procedure Input (Obj : in Set_Below_Ground);
   procedure Input (Obj : in Set_Below_Ground) is
   begin
      Pace.Log.Wait (0.1);
      -- Now that we have a surrogate, maybe we can unlink and then turn invisible instead of moving it lower
      Pace.Log.Put_Line ("Setting " & Interfaces.C.To_Ada (Obj.Uid) & " below ground!!");
      Hal.Ve.Set ("", Position'(Obj.Pos.X, Obj.Pos.Y - Below_Ground_Offset, Obj.Pos.Z), Obj.Ori, Interfaces.C.To_Ada (Obj.Uid));
   end Input;

   -- Determine where projectile should be at and put it there. Delete if it has gone below the min height.
   procedure Move_Projectile (Curs : in out Projectile_List.Cursor) is
      use Ada.Numerics.Elementary_Functions;
      use Projectile_List;
      Delta_Vertical, Delta_Horizontal, Tangent_Angle : Float;
      Pos : Hal.Position;
      Ori : Hal.Orientation;
      Ori_Vis : Hal.Orientation;
      P : Projectile := Element (Curs);
      Landing_Spot : Hal.Position;
      Time_Of_Flight : Duration := Pace.Now - P.Start_Time;
   begin
      Pbm.Parabolic_Motion.Calculate_Location (P.Theta, P.Initial_Vel, Time_Of_Flight, Delta_Vertical, Delta_Horizontal, Tangent_Angle);
      Pos.Z := P.Start_Pos.Z + Delta_Horizontal * Cos (P.Heading);
      -- Negating Delta_Horizontal term here since positive heading is flip-flopped with coordinate system
      Pos.X := P.Start_Pos.X + Delta_Horizontal * Sin (P.Heading);
      Pos.Y := P.Start_Pos.Y + Delta_Vertical;
      Apply_Random_Factor (P, Time_Of_Flight, Pos);
      -- VE model has 0.0 degrees pointing straight up, whereas Tangent_Angle is relative to horizontal.
      -- Negation on Ori.A needed ever since the CTDB/IV1/NVIG orientation changes
      Ori.A := -Tangent_Angle;
      Ori.B := -P.Heading;
      Ori.C := 0.0;  -- Projectiles are cylindrical, so this angle doesn't matter

      declare -- Update any subscribers
         Msg : Update;
      begin
         Msg.Ack := False;
         if Exact_Landing_Spot then
            Msg.Pos := (Pos.X - P.Start_Pos.X, Pos.Y - P.Start_Pos.Y, Pos.Z - P.Start_Pos.Z);  -- for exact hit of target location
         else
            Msg.Pos := Pos;
         end if;
         Msg.Ori := Ori;
         Msg.Pid := S2b (Interfaces.C.To_Ada (P.Uid));
         Pace.Socket.Send (Msg);
      end;

      Ori_Vis.A := 0.0;
      Ori_Vis.B := 0.0;
      Ori_Vis.C := Float(Time_Of_Flight) * 10.0;
      Hal.Ve.Set ("", Ori_Vis, Interfaces.C.To_Ada (P.Uid) & ":geom");
      Hal.Ve.Set ("", Pos, Ori, Interfaces.C.To_Ada (P.Uid));

      if not P.Trail_On then
         -- Turn the trail on. This needs to happen after the first set to avoid a long trail from the origin
         Update_Element (Flying_Projectiles, Curs, Turn_Trail_On'Access);
      end if;

      if Has_Projectile_Landed (P, Delta_Vertical, Tangent_Angle) then
         Landing_Spot := Find_Exact_Landing_Spot (P, Time_Of_Flight);
         declare -- Update any subscribers that want to know if it landed
            Msg : Landed;
            Diff : Hal.Position;
         begin
            Msg.Ack := False;
            Diff := (P.Target_Pos.X - P.Start_Pos.X, P.Target_Pos.Y - P.Start_Pos.Y, P.Target_Pos.Z - P.Start_Pos.Z);
            if Exact_Landing_Spot then
               Msg.Pos := Diff;  -- For exact hit of target location from starting location
            else
               Msg.Pos := Landing_Spot; -- For approximate hit as terrain varies
            end if;
            Msg.Pid := S2b (Interfaces.C.To_Ada (P.Uid));
            Pace.Socket.Send (Msg);
         end;
         Delete (Flying_Projectiles, Curs);
         Hal.Ve.StopPlot(Interfaces.C.To_Ada (P.Uid));
         Hal.Ve.Impact (B2s (P.Munition), Landing_Spot);
         Hal.Ve.Set("", "off", 0.0, Interfaces.C.To_Ada (P.Uid));
         declare
            Msg : Set_Below_Ground;
         begin
            Msg.Pos := Position'(Landing_Spot.X, Landing_Spot.Y - Below_Ground_Offset, Landing_Spot.Z);
            Msg.Ori := Ori;
            Msg.Uid := P.Uid;
            Pace.Surrogates.Input (Msg);
         end;
      end if;

   end Move_Projectile;

   task body Agent is
      use Projectile_List;
      Curs : Cursor;
      Current_Time : Duration;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         accept Activate;
         while not Is_Empty (Flying_Projectiles) loop
            Current_Time := Pace.Now;
            -- Iterate through flying projectiles, updating each projectile, removing those that are done
            Curs := First (Flying_Projectiles);
            while Curs /= No_Element loop
               Move_Projectile (Curs);
               Next (Curs);
            end loop;
            Pace.Log.Wait_Until (Current_Time + Hla_Dt);
         end loop;
      end loop;
   exception
      when E : others =>
         Pace.Log.Ex (E);
   end Agent;

end Hal.Ve_Lib.Projectile_Motion;
