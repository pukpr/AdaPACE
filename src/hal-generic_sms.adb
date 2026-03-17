with Ada.Numerics.Elementary_Functions;
with Pace.Strings;
with Pace.Config;
with Pace.Socket;
with Pace.Multicast;
with Pace.Log;
with Pace.Surrogates;
with Pace.Server.Dispatch;
with Text_Io;
with Ual.Utilities;
with Hal.Fp_Utilities;
with Hal.Velocity_Plots;
with Hal.Geometry_And_Trig;
with Hal.Rotations;
with Hal.Shaper;
with Interfaces.C;
with Gis.Dead_Reckoning;

package body Hal.Generic_Sms is

   use Pace.Strings;

   Animation_Mode : Boolean := "1" = Pace.Getenv ("HAL_SMS", "1");
   Dead_Reckoning_On : Boolean := (Pace.Getenv ("HAL_DR", 0) = 1);
   Mcast_Addr : constant String := Pace.Getenv ("HAL_SMS_MCAST" & Route_Tag, "");
   Mcast_Addr_RX : constant String := Pace.Getenv ("HAL_SMS_MCAST_RX" & Route_Tag, Mcast_Addr);

   Dt : Duration := Duration (Pace.Getenv ("HAL_DELTA", 0.05)); -- 20 Hz default

   package Circ is new Hal.Fp_Utilities.Circular (-Ada.Numerics.Pi, Ada.Numerics.Pi);

   RX : Pace.Multicast.Receiver := Pace.Multicast.Create (Mcast_Addr_RX);

   Debug_Once : Boolean := True;
   
   procedure P_S_Send (Obj : in Pace.Msg'Class; Ack : in Boolean := True) is
   begin
      Pace.Socket.Send (Obj, Ack);
   end;

   procedure P_S_Send_Inout (Obj : in out Pace.Msg'Class) is
   begin
      Pace.Socket.Send_Inout (Obj);
   end;

   function S (Value : Float) return String is
   begin
--      return Float'Image(Value) & " ";
      return Ual.Utilities.Float_Put (Value) & " ";
   end S;

   procedure Log (Txt : in String) is
   begin
      Text_Io.Put_Line (S (Float (Pace.Now)) & " " & Txt);
   end Log;

   procedure Old_Display (Txt : in String) is
   begin
      null;
   end Old_Display;

   procedure Default_Trans (Pos : in Hal.Position) is
   begin
      null;
   end Default_Trans;

   procedure Default_Rot (Ori : in Hal.Orientation) is
   begin
      null;
   end Default_Rot;

   procedure Default_Motion (Value : in Float) is
   begin
      null;
   end Default_Motion;

   procedure Interval_Calculate (Time : in Duration;
                                 Number : out Integer;
                                 Delta_Time : out Duration) is
   begin
      Number := Integer (Float (Time) / Float (Dt));
      if Number = 0 then
         Number := 1;
         Delta_Time := Time;
      else
         Delta_Time := Dt;
      end if;
   end Interval_Calculate;

   Override : Boolean := False;

   protected Suspend is
      entry Wait_On_Check;
      procedure Signal_To_Uncheck;
      procedure Signal_To_Check;
      function Is_Check_On return Boolean;
   private
      Check_Is_Off : Boolean := True;
   end Suspend;


   protected body Suspend is
      entry Wait_On_Check when Check_Is_Off is
      begin
         null;
      end Wait_On_Check;

      procedure Signal_To_Uncheck is
      begin
         Check_Is_Off := True;
      end Signal_To_Uncheck;

      procedure Signal_To_Check is
      begin
         Check_Is_Off := False;
      end Signal_To_Check;

      function Is_Check_On return Boolean is
      begin
         return not Check_Is_Off;
      end Is_Check_On;

   end Suspend;

   procedure Wait_If_Check_Is_On (Name : in String) is
   begin
      if Suspend.Is_Check_On and not Override then
--     if Reduced_Power then
--        Agent.Input (Name);
--     else
         Suspend.Wait_On_Check;
--     end if;
         if Override then
            raise Stop;
         end if;
      end if;
   end Wait_If_Check_Is_On;

   -----------
   -- Check --
   -----------

   procedure Check is
   begin
      Suspend.Signal_To_Check;
   end Check;

   --------------------
   -- Check_Override --
   --------------------

   procedure Check_Override is
   begin
      Override := True;
      Suspend.Signal_To_Uncheck;
   end Check_Override;

   ------------------
   -- Coordination --
   ------------------

   procedure Coordination (Name : in String;
                           Start_Pos : in Position;
                           Final_Pos : in out Position;
                           Start_Rot : in Orientation;
                           Final_Rot : in out Orientation;
                           Time : in Duration;
                           Stopped : out Boolean;
                           Entity : in String := "") is
      Num : Integer;
      Pos : Position;
      Dx, Dy, Dz : Float;
      Rot : Orientation;
      Da, Db, Dc : Float;
      D_T : Duration;
      Current_Time : Duration := Pace.Now;
   begin
      Interval_Calculate (Time, Num,
                          D_T); -- Num := Integer (Float (Time) / Float (Dt));
      Pos := Start_Pos;
      Rot := Start_Rot;
      Dx := (Final_Pos.X - Start_Pos.X) / Float (Num);
      Dy := (Final_Pos.Y - Start_Pos.Y) / Float (Num);
      Dz := (Final_Pos.Z - Start_Pos.Z) / Float (Num);
      Da := (Final_Rot.A - Start_Rot.A) / Float (Num);
      Db := (Final_Rot.B - Start_Rot.B) / Float (Num);
      Dc := (Final_Rot.C - Start_Rot.C) / Float (Num);
      Set (Name, Pos, Rot, Entity);
      for I in 1 .. Num loop
         -- should be a wait_until
         Current_Time := Current_Time + D_T;
         Pace.Log.Wait_Until (Current_Time);
         Pos.X := Pos.X + Dx;
         Pos.Y := Pos.Y + Dy;
         Pos.Z := Pos.Z + Dz;
         Rot.A := Rot.A + Da;
         Rot.B := Rot.B + Db;
         Rot.C := Rot.C + Dc;
         Set (Name, Pos, Rot, Entity);
      end loop;
      Stopped := False;
   end Coordination;

   ----------
   -- Link --
   ----------

   procedure Link (Parent : in String; Child : in String; Shared_Entity : in String := "") is
   begin
      if Parent = Child then
         Pace.Log.Put_Line ("!!!!!!!!!!!!! Attempting to Link an entity to itself.  This is really bad.  Aborting link!!!!!!!!!!");
      else
         Wait_If_Check_Is_On (Parent);
         if not Animation_Mode then
            Log ("link " & Parent & " " & Child);
            return;
         end if;

         declare
            Msg : Proxy.Set_Link;
         begin
            Msg.Parent := To_Name (Parent);
            Msg.Child := To_Name (Child);
            Msg.Shared_Entity := To_Name (Shared_Entity);
            P_S_Send (Msg, Ack => True);
         end;
      end if;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping Link", 8);
         null;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping Link and Propagating", 8);
         raise Stop_And_Propagate;
      when others =>
         null;
   end Link;

   --------------
   -- Pendulum --
   --------------

   procedure Pendulum (Name : in String;
                       Start : in Orientation;
                       Extent : in Orientation;
                       Freq : in Rate;
                       Damp : in Rate;
                       Max_Time : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access) is
      Num : Integer;
      Rot : Orientation;
      T : Float := 0.0;
      use Ada.Numerics.Elementary_Functions;
      Tc : constant Float := Float (Damp.Second) / Damp.Units;
      W : constant Float := 2.0 * Ada.Numerics.Pi *
                              Freq.Units / Float (Freq.Second);
   begin
      Num := Integer (2.0 * Tc / Float (Dt));
      -- restrict time to run by max_time
      if Max_Time > 0.001 and (Duration (Num) / Dt) > Max_Time then
         Num := Integer (Max_Time / Dt);
      end if;
      Rot := Start;
      for I in 1 .. Num loop
         Set (Name, Rot);
         Callback (Rot);
         -- Wait_Until ??
         Pace.Log.Wait (Dt);
         T := T + Float (Dt);
         Rot.A := Start.A + Extent.A * Sin (T * W) * Exp (-T * Tc);
         Rot.B := Start.B + Extent.B * Sin (T * W) * Exp (-T * Tc);
         Rot.C := Start.C + Extent.C * Sin (T * W) * Exp (-T * Tc);
      end loop;
   end Pendulum;

   --------------
   -- Rotation --
   --------------

   procedure Rotation (Name : in String;
                       Start : in Orientation;
                       Final : in out Orientation;
                       Speed : in Rate;
                       Stopped : out Boolean;
                       Ramp_Up : in Duration := 0.0;
                       Ramp_Down : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access;
                       Entity : in String := "";
                       Which_Way : in Direction_To_Rotate := Shortest_Route) is
      Time : Duration;
      Amt : Float := 0.0;
      use Ada.Numerics.Elementary_Functions;
      Minimum_Time : Float;
   begin
      Amt := abs Circ.Difference(Final.A, Start.A);
      Amt := Float'Max(Amt, abs Circ.Difference(Final.B, Start.B));
      Amt := Float'Max(Amt, abs Circ.Difference(Final.C, Start.C));
      Minimum_Time := abs (Amt * Float (Speed.Second) / Speed.Units);
      Time := Duration (Minimum_Time) + (Ramp_Up + Ramp_Down) / 2;
      if Ramp_Up + Ramp_Down < Time then
         Rotation (Name, Start, Final, Time, Stopped,
                   Ramp_Up, Ramp_Down, Callback, Entity);
      else
         Rotation (Name, Start, Final, Ramp_Up + Ramp_Down,
                   Stopped, Ramp_Up, Ramp_Down, Callback, Entity);
      end if;
   end Rotation;

   --------------
   -- Rotation --
   --------------

   procedure Rotation (Name : in String;
                       Start : in Orientation;
                       Final : in out Orientation;
                       Time : in Duration;
                       Stopped : out Boolean;
                       Ramp_Up : in Duration := 0.0;
                       Ramp_Down : in Duration := 0.0;
                       Callback : in Rot_Callback := Default_Rot'Access;
                       Entity : in String := "";
                       Which_Way : in Direction_To_Rotate := Shortest_Route) is

      function More_Than_One_Axe (S, F : Orientation) return Boolean is
         Count : Integer := 0;
      begin
         if S.A /= F.A then
            Count := Count + 1;
         end if;
         if S.B /= F.B then
            Count := Count + 1;
         end if;
         if S.C /= F.C then
            Count := Count + 1;
         end if;
         if Count > 1 then
            return True;
         else
            return False;
         end if;
      end More_Than_One_Axe;

      function Calculate_Velocity (Current_Rot, Prev_Rot : Orientation;
                                   Delta_Time : Duration) return Float is
         -- assumes only one axis is changing, so two of the differences in this calculation
         -- will be zero.. easier than an if clause
         Delta_Angle : Float := abs (Current_Rot.A - Prev_Rot.A) +
                                abs (Current_Rot.B - Prev_Rot.B) +
                                abs (Current_Rot.C - Prev_Rot.C);

      begin
         return Delta_Angle / Float (Delta_Time);
      end Calculate_Velocity;

      Num : Integer;
      Da : Float;
      Db : Float;
      Dc : Float;
      Rot, Prev_Rot : Orientation;
      So_Far : Duration := 0.0;
      Ratio : Float;
      Max_Ratio : Float;
      D_T : Duration;
      Current_Time : Duration := Pace.Now;
      Do_Velocity_Plot : Boolean := False;
      Velocities : Hal.Velocity_Plots.Velocity_Vector.Vector;
      Use_Quaternions : Boolean := False;

      procedure Calculate_Next_Rot_Euler is
      begin
         if So_Far < Ramp_Up and then Ramp_Up /= 0.0 then
            Ratio := Max_Ratio * Float (So_Far) / Float (Ramp_Up);
            Rot.A := Rot.A + Da * Ratio;
            Rot.B := Rot.B + Db * Ratio;
            Rot.C := Rot.C + Dc * Ratio;
         elsif So_Far > Time - Ramp_Down and then Ramp_Down /= 0.0 then
            Ratio := Max_Ratio * Float (Time - So_Far) / Float (Ramp_Down);
            Rot.A := Rot.A + Da * Ratio;
            Rot.B := Rot.B + Db * Ratio;
            Rot.C := Rot.C + Dc * Ratio;
         else
            Rot.A := Rot.A + Da * Max_Ratio;
            Rot.B := Rot.B + Db * Max_Ratio;
            Rot.C := Rot.C + Dc * Max_Ratio;
         end if;
      end Calculate_Next_Rot_Euler;

      function Choose_Which_Way (Value : Float) return Float is
      begin
         if Which_Way = Shortest_Route then
            return Value;
         elsif Which_Way = Pos then
            return abs (Value);
         else
            -- neg
            return -abs (Value);
         end if;
      end Choose_Which_Way;

   begin
      if Ramp_Up /= 0.0 and Ramp_Down /= 0.0 then
         Do_Velocity_Plot := True;
      end if;
      if Time = 0.0 then
         Stopped := False;
         return;
      end if;
      Ratio := Float (Ramp_Up + Ramp_Down) / Float (Time) / 2.0;
      Max_Ratio := 1.0 / (1.0 - Ratio);
      Interval_Calculate (Time, Num,
                          D_T); -- Num := Integer (Float (Time)/ Float (Dt));

      declare
         -- only used when quaternion interpolation is done
         Rots_Arr : Ori_Arr (1 .. Num);
      begin

         if More_Than_One_Axe (Start, Final) then
            Use_Quaternions := True;
            Rots_Arr := Hal.Rotations.Interpolate_Quat (Num, Start, Final);
         else -- rotate with euler
            Da := Choose_Which_Way ((Circ.Difference(Final.A,Start.A)) / Float (Num));
            Db := Choose_Which_Way ((Circ.Difference(Final.B,Start.B)) / Float (Num));
            Dc := Choose_Which_Way ((Circ.Difference(Final.C,Start.C)) / Float (Num));
         end if;

         Rot := Start;
         for I in 1 .. Num loop
            Set (Name, Rot, Entity);
            Callback (Rot);
            -- See translate for wait_until
            Current_Time := Current_Time + D_T;
            Pace.Log.Wait_Until (Current_Time);
            So_Far := So_Far + D_T;
            Prev_Rot := Rot;
            if Use_Quaternions then
               Rot := Rots_Arr (I);
                           Pace.Log.Put_Line ("*** USING QUATERNIONS ***");
            else
               Calculate_Next_Rot_Euler;
            end if;
            -- calculate velocity and add it to the velocity_vector for plot data
            if Do_Velocity_Plot then
               Hal.Velocity_Plots.Velocity_Vector.Append (Velocities, Calculate_Velocity (Rot, Prev_Rot, D_T));
            end if;
         end loop;
      end;

      Rot := Final;

      if Do_Velocity_Plot then
         declare
            Plot_Data : Hal.Velocity_Plots.Velocity_Plot_Data;
         begin
            Plot_Data.Delta_Time := D_T;
            Plot_Data.Velocities := Velocities;
            Hal.Velocity_Plots.Add_Plot_Data (hal.bounded_Assembly.To_Bounded_String (Name),
                                              Plot_Data);
         end;
      end if;
      Set (Name, Rot, Entity);
      Callback (Rot);
      Stopped := False;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping " & Name, 8);
         Final := Rot;
         Stopped := True;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping " & Name, 8);
         --Final := Rot;
         --Stopped := True;
         raise Stop_And_Propagate;
   end Rotation;

   -- start and final in radians
   procedure Renormalize_Shortest_Path
               (Start : in Float; Final : in out Float) is
      use Ada.Numerics;
   begin
      if abs (Final - Start) > Pi then
         if Final > 0.0 then
            Final := Final - 2.0 * Pi;
         else
            Final := Final + 2.0 * Pi;
         end if;
      end if;
   end Renormalize_Shortest_Path;

   ---------
   -- Set --
   ---------

   procedure Set (Name : in String; Event : in String; Time_Lapse : Duration; Entity : String := "") is
   begin
      Wait_If_Check_Is_On (Name);
      if not Animation_Mode then
         Log ("event " & Name & " " & Event);
         return;
      end if;

      declare
         Msg : Proxy.Set_Event;
      begin
         Msg.Assembly := To_Name (Name);
         Msg.Event := To_Name (Event);
         Msg.Entity := To_Name (Entity);
         Pace.Set_Wait (Msg, abs (Time_Lapse));
         P_S_Send (Msg, Ack => True);
      end;

      -- only wait if time_lapse is positive
      if Time_Lapse > 0.0 then
         Pace.Log.Wait (Time_Lapse);
      end if;

   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping Event " & Name, 8);
         null;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping Event " & Name, 8);
         raise Stop_And_Propagate;
      when others =>
         null;
   end Set;

   ---------
   -- Set --
   ---------

   procedure Set (Name : in String; Pos : in Position; Rot : in Orientation; Entity : in String := "") is
   begin
      Wait_If_Check_Is_On (Name);
      if not Animation_Mode then
         Log ("pos " & Name & " " & S (Pos.X) & S (Pos.Y) & S (Pos.Z));
         Log ("rot " & Name & " " & S (Rot.A) & S (Rot.B) & S (Rot.C));
         return;
      end if;
      declare
         Msg : Proxy.Coordinate;
      begin
         Msg.Assembly := To_Name (Name);
         Msg.Pos := Pos;
         Msg.Rot := Rot;
         Msg.Entity := To_Name (Entity);
         P_S_Send (Msg, Ack => True);
      end;
   end Set;

   ---------
   -- Set --
   ---------

   procedure Set (Name : in String; Pos : in Position; Entity : in String := "") is
   begin
      Wait_If_Check_Is_On (Name);
      if not Animation_Mode then
         Log ("pos " & Name & " " & S (Pos.X) & S (Pos.Y) & S (Pos.Z));
         return;
      end if;
      declare
         Msg : Proxy.Translate;
      begin
         Msg.Assembly := To_Name (Name);
         Msg.Pos := Pos;
         Msg.Entity := To_Name (Entity);
         P_S_Send (Msg, Ack => True);
      end;
   end Set;

   ---------
   -- Set --
   ---------

   procedure Set (Name : in String; Rot : in Orientation; Entity : in String := "") is
   begin
      Wait_If_Check_Is_On (Name);
      if not Animation_Mode then
         Log ("rot " & Name & " " & S (Rot.A) & S (Rot.B) & S (Rot.C));
         return;
      end if;

      declare
         Msg : Proxy.Rotate;
      begin
         Msg.Assembly := To_Name (Name);
         Msg.Rot := Rot;
         Msg.Entity := To_Name (Entity);
         P_S_Send (Msg, Ack => True);
      end;
   end Set;

   ---------------
   -- Set_Delta --
   ---------------

   procedure Set_Delta (Frequency : in Rate) is
   begin
      Dt := Duration (Float (Frequency.Second) / Frequency.Units);
   end Set_Delta;

   ---------------
   -- Set_Delta --
   ---------------

   procedure Set_Delta (Tick : in Duration) is
   begin
      Dt := Tick;
   end Set_Delta;

   -------------
   -- Set_Var --
   -------------

   procedure Set_Var (Name : in String; Value : in String) is
   begin
      Wait_If_Check_Is_On (Name);
      if not Animation_Mode then
         Log ("var " & Name & " " & Value);
         return;
      end if;

      declare
         Msg : Proxy.Set_Variable;
      begin
         if Name = "SCALE" then
            Msg.Object := To_Name ("@" & Name);
         else
            Msg.Object := To_Name (Name);
         end if;
         Msg.Variable := To_Name (Value);
         P_S_Send (Msg, Ack => True);
      end;
      -- Add a slight delay to make sure variable
      -- gets there before the event.
      Pace.Log.Wait (0.1);
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping Variable " & Name, 8);
         null;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping Variable and Propagating " & Name, 8);
         raise Stop_And_Propagate;
      when others =>
         null;
   end Set_Var;

   --------------
   -- Show_All --
   --------------

   procedure Show_All (Proc : in Display) is
   begin
      null;
   end Show_All;

   ------------
   -- Spring --
   ------------

   procedure Spring (Name : in String;
                     Start : in Position;
                     Extent : in Position;
                     Freq : in Rate;
                     Damp : in Rate;
                     Max_Time : in Duration := 0.0;
                     Callback : in Trans_Callback := Default_Trans'Access) is
      Num : Integer;
      Pos : Position;
      T : Float := 0.0;
      use Ada.Numerics.Elementary_Functions;
      Tc : constant Float := Float (Damp.Second) / Damp.Units;
      W : constant Float := 2.0 * Ada.Numerics.Pi *
                              Freq.Units / Float (Freq.Second);
   begin
      Num := Integer (2.0 * Tc / Float (Dt));
      -- restrict time to run by max_time
      if Max_Time > 0.001 and (Duration (Num) / Dt) > Max_Time then
         Num := Integer (Max_Time / Dt);
      end if;
      Pos := Start;
      for I in 1 .. Num loop
         Set (Name, Pos);
         Callback (Pos);
         -- Wait_Until for real-time?
         Pace.Log.Wait (Dt);
         T := T + Float (Dt);
         Pos.X := Start.X + Extent.X * Sin (T * W) * Exp (-T * Tc);
         Pos.Y := Start.Y + Extent.Y * Sin (T * W) * Exp (-T * Tc);
         Pos.Z := Start.Z + Extent.Z * Sin (T * W) * Exp (-T * Tc);
      end loop;
   end Spring;

   ----------------
   -- Time_Scale --
   ----------------

   procedure Time_Scale (Scale : in Float) is
      Int_Scale : constant Integer := Integer (Scale);
      Factor : constant String := Pace.Strings.Trim (Int_Scale);
   begin
      Pace.Log.Put_Line ("Setting Division Time Scale to " & Factor);
      Set_Var ("SCALE", Factor);
   end Time_Scale;

   -------------
   -- To_Name --
   -------------

   function To_Name (Str : in String) return Name is
      use Interfaces.C;
      The_Name : Name;
      Len : Size_T;
   begin
      if Str'Length > Name'Length then
         Pace.Log.Put_Line (Str & " name too long for Division");
      end if;
      To_C (Str, The_Name, Len);
      return The_Name;
   end To_Name;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : in Pace.Msg'Class) is
   begin
      null;
   end Trace;

   -----------------
   -- Translation --
   -----------------

   procedure Translation
               (Name : in String;
                Start : in Position;
                Final : in out Position;
                Speed : in Rate;
                Stopped : out Boolean;
                Ramp_Up : in Duration := 0.0;
                Ramp_Down : in Duration := 0.0;
                Callback : in Trans_Callback := Default_Trans'Access;
                Entity : in String := "") is
      Time : Duration;
      Dist, Dx, Dy, Dz : Float;
      Minimum_Time : Float;
      use Ada.Numerics.Elementary_Functions;
   begin
      Dx := (Final.X - Start.X);
      Dy := (Final.Y - Start.Y);
      Dz := (Final.Z - Start.Z);
      Dist := Sqrt (Dx * Dx + Dy * Dy + Dz * Dz);
      Minimum_Time := abs (Dist * Float (Speed.Second) / Speed.Units);
      Time := Duration (Minimum_Time) + (Ramp_Up + Ramp_Down) / 2;
      if Ramp_Up + Ramp_Down < Time then
         Translation (Name, Start, Final, Time, Stopped,
                      Ramp_Up, Ramp_Down, Callback, Entity);
      else
         Translation (Name, Start, Final, Ramp_Up + Ramp_Down,
                      Stopped, Ramp_Up, Ramp_Down, Callback, Entity);
      end if;
   end Translation;

   -----------------
   -- Translation --
   -----------------

   procedure Translation
               (Name : in String;
                Start : in Position;
                Final : in out Position;
                Time : in Duration;
                Stopped : out Boolean;
                Ramp_Up : in Duration := 0.0;
                Ramp_Down : in Duration := 0.0;
                Callback : in Trans_Callback := Default_Trans'Access;
                Entity : in String := "") is

      function Calculate_Velocity (Current_Pos, Prev_Pos : Position;
                                   Delta_Time : Duration) return Float is
      begin
         return Hal.Geometry_And_Trig.Distance_Between_Points (Current_Pos, Prev_Pos) / Float (Delta_Time);
      end Calculate_Velocity;

      Num : Integer;
      Pos, Prev_Pos : Position;
      Dx, Dy, Dz : Float;
      So_Far : Duration := 0.0;
      Current_Time : Duration := Pace.Now;
      Ratio : Float;
      Max_Ratio : Float;
      D_T : Duration;
      Do_Velocity_Plot : Boolean := False;
      Velocities : Hal.Velocity_Plots.Velocity_Vector.Vector;
   begin
      if Ramp_Up /= 0.0 and Ramp_Down /= 0.0 then
         Do_Velocity_Plot := True;
      end if;

      if Time = 0.0 then
         Stopped := False;
         return;
      end if;
      Ratio := Float (Ramp_Up + Ramp_Down) / Float (Time) / 2.0;
      Max_Ratio := 1.0 / (1.0 - Ratio);
      Interval_Calculate (Time, Num,
                          D_T); -- Integer (Float (Time) / Float (Dt));
      Pos := Start;
      Dx := (Final.X - Start.X) / Float (Num);
      Dy := (Final.Y - Start.Y) / Float (Num);
      Dz := (Final.Z - Start.Z) / Float (Num);
      for I in 1 .. Num loop
         Set (Name, Pos, Entity);
         Callback (Pos);
         Current_Time := Current_Time + D_T;
         Pace.Log.Wait_Until (Current_Time);
         So_Far := So_Far + D_T;
         Prev_Pos := Pos;
         if So_Far < Ramp_Up and then Ramp_Up /= 0.0 then
            Ratio := Max_Ratio * Float (So_Far) / Float (Ramp_Up);
            Pos.X := Pos.X + Dx * Ratio;
            Pos.Y := Pos.Y + Dy * Ratio;
            Pos.Z := Pos.Z + Dz * Ratio;
         elsif So_Far > Time - Ramp_Down and then Ramp_Down /= 0.0 then
            Ratio := Max_Ratio * Float (Time - So_Far) / Float (Ramp_Down);
            Pos.X := Pos.X + Dx * Ratio;
            Pos.Y := Pos.Y + Dy * Ratio;
            Pos.Z := Pos.Z + Dz * Ratio;
         else
            Pos.X := Pos.X + Dx * Max_Ratio;
            Pos.Y := Pos.Y + Dy * Max_Ratio;
            Pos.Z := Pos.Z + Dz * Max_Ratio;
         end if;
         -- calculate velocity and add it to the velocity_vector for plot data
         if Do_Velocity_Plot then
            Hal.Velocity_Plots.Velocity_Vector.Append (Velocities, Calculate_Velocity (Pos, Prev_Pos, D_T));
         end if;
      end loop;
      Pos := Final;
      if Do_Velocity_Plot then
         declare
            Plot_Data : Hal.Velocity_Plots.Velocity_Plot_Data;
         begin
            Plot_Data.Delta_Time := D_T;
            Plot_Data.Velocities := Velocities;
            Hal.Velocity_Plots.Add_Plot_Data (hal.bounded_Assembly.To_Bounded_String (Name),
                                              Plot_Data);
         end;
      end if;
      Set (Name, Pos, Entity);
      Callback (Pos);
      Stopped := False;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping " & Name, 8);
         Final := Pos;
         Stopped := True;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping " & Name, 8);
         --Final := Pos;
         --Stopped := True;
         raise Stop_And_Propagate;
   end Translation;

   procedure Translation (Names : in Names_Array;
                          Start : in Float;
                          Final : in out Float;
                          Axis : in Axes;
                          Max_Velocity : in Float;
                          Accel : in Float;
                          Decel : in Float;
                          Stopped : out Boolean;
                          Callback : in Motion_Callback := Default_Motion'Access;
                          Entity : in String := "") is

      use Hal.Bounded_Assembly;

      function Calculate_Velocity (Current_Pos, Prev_Pos : Position;
                                   Delta_Time : Duration) return Float is
      begin
         return Hal.Geometry_And_Trig.Distance_Between_Points (Current_Pos, Prev_Pos) / Float (Delta_Time);
      end Calculate_Velocity;

      Start_Pos : Position := Get_Pos (Axis, Start);
      Final_Pos : Position := Get_Pos (Axis, Final);

      Xmax : Float := abs(Start - Final);
      Dx : Float := 0.0;

      Pos, Prev_Pos : Position;
      Current_Time : Duration := Pace.Now;
      D_T : Duration := Dt;
      Velocities : Hal.Velocity_Plots.Velocity_Vector.Vector;
      Start_Time : Duration := Current_Time;
   begin
      if Accel = 0.0 or Decel = 0.0 then
         Stopped := False;
         return;
      end if;
      Pos := Start_Pos;
      loop
         for I in Names'Range loop
            Set (To_String (Names (I)), Pos, Entity);
         end loop;
         Callback (Get_Axis_Value (Axis, Pos));
         Current_Time := Current_Time + D_T;
         Pace.Log.Wait_Until (Current_Time);
         Prev_Pos := Pos;
         -- calculate velocity and add it to the velocity_vector for plot data
         Hal.Velocity_Plots.Velocity_Vector.Append (Velocities, Calculate_Velocity (Pos, Prev_Pos, D_T));
         Dx := Hal.Shaper.Get_Position (Current_Time - Start_Time, Xmax, Max_Velocity, Accel, Decel, True);
         exit when Dx >= XMax;
         if Start < Final then
            Pos := Get_Pos (Axis, Start+Dx);
         else
            Pos := Get_Pos (Axis, Start-Dx);
         end if;
      end loop;
      Pos := Final_Pos;
      declare
         Plot_Data : Hal.Velocity_Plots.Velocity_Plot_Data;
      begin
         Plot_Data.Delta_Time := D_T;
         Plot_Data.Velocities := Velocities;
         -- only plot 1 of the Names
         Hal.Velocity_Plots.Add_Plot_Data (Names (1),
                                           Plot_Data);
      end;
      for I in Names'Range loop
         Set (To_String (Names (I)), Pos, Entity);
      end loop;
      Callback (Final);
      Stopped := False;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping " & To_String (Names (1)), 8);
         Final := Get_Axis_Value (Axis, Pos);
         Stopped := True;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping " & To_String (Names (1)), 8);
         raise Stop_And_Propagate;
   end Translation;

   procedure Rotation (Names : in Names_Array;
                       Start : in Float;
                       Final : in out Float;
                       Axis : in Axes;
                       Max_Velocity : in Float;
                       Accel : in Float;
                       Decel : in Float;
                       Stopped : out Boolean;
                       Callback : in Motion_Callback := Default_Motion'Access;
                       Entity : in String := "";
                       Which_Way : in Direction_To_Rotate := Shortest_Route) is

      use Hal.Bounded_Assembly;

      function Calculate_Velocity (Current_Rot, Prev_Rot : Orientation;
                                   Delta_Time : Duration) return Float is
         -- assumes only one axis is changing, so two of the differences in this calculation
         -- will be zero.. easier than an if clause
         Delta_Angle : Float := abs (Current_Rot.A - Prev_Rot.A) +
                                abs (Current_Rot.B - Prev_Rot.B) +
                                abs (Current_Rot.C - Prev_Rot.C);

      begin
         return Delta_Angle / Float (Delta_Time);
      end Calculate_Velocity;

      function Choose_Which_Way return Float is
      begin
         if Which_Way = Shortest_Route then
            return Float'Copy_Sign (1.0, Circ.Difference (Final, Start));
         elsif Which_Way = Pos then
            return 1.0;
         else
            -- neg
            return -1.0;
         end if;
      end Choose_Which_Way;

      Start_Ori : Orientation := Get_Ori (Axis, Start);
      Final_Ori : Orientation := Get_Ori (Axis, Final);

      Xmax : Float := abs (Circ.Difference (Final, Start));
      Sign : Float := Choose_Which_Way;
      Dx : Float := 0.0;

      Rot, Prev_Rot : Orientation;
      D_T : Duration := Dt;
      Current_Time : Duration := Pace.Now;
      Start_Time : Duration := Current_Time;
      Velocities : Hal.Velocity_Plots.Velocity_Vector.Vector;

   begin
      if Accel = 0.0 or Decel = 0.0 then
         Stopped := False;
         return;
      end if;
      Rot := Start_Ori;
      loop
         for I in Names'Range loop
            Set (To_String (Names (I)), Rot, Entity);
         end loop;
         Callback (Get_Axis_Value (Axis, Rot));
         -- See translate for wait_until
         Current_Time := Current_Time + D_T;
         Pace.Log.Wait_Until (Current_Time);
         Prev_Rot := Rot;
         -- calculate velocity and add it to the velocity_vector for plot data
         Hal.Velocity_Plots.Velocity_Vector.Append (Velocities, Calculate_Velocity (Rot, Prev_Rot, D_T));
         Dx := Hal.Shaper.Get_Position (Current_Time - Start_time, Xmax, Max_Velocity, Accel, Decel, True);
         exit when Dx >= XMax;
         Rot := Get_Ori (Axis, Circ.Add (Start, Sign * Dx));
      end loop;
      Rot := Final_Ori;
      declare
         Plot_Data : Hal.Velocity_Plots.Velocity_Plot_Data;
      begin
         Plot_Data.Delta_Time := D_T;
         Plot_Data.Velocities := Velocities;
         -- only plot 1 of the Names
         Hal.Velocity_Plots.Add_Plot_Data (Names (1),
                                           Plot_Data);
      end;
      for I in Names'Range loop
         Set (To_String (Names (I)), Rot, Entity);
      end loop;
      Callback (Final);
      Stopped := False;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping " & To_String (Names (1)), 8);
         Final := Get_Axis_Value (Axis, Rot);
         Stopped := True;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping " & To_String (Names (1)), 8);
         raise Stop_And_Propagate;
   end Rotation;

   procedure Motion (Name : in String;
                     Start : in Float;
                     Final : in out Float;
                     Axis : in Axes;
                     Max_Velocity : in Float;
                     Accel : in Float;
                     Decel : in Float;
                     Stopped : out Boolean;
                     Callback : in Motion_Callback := Default_Motion'Access;
                     Entity : in String := "";
                     Which_Way : in Direction_To_Rotate := Shortest_Route) is
      Names : Names_Array := (1 => Hal.Bounded_Assembly.To_Bounded_String (Name));
   begin
      if Axis = X or Axis = Y or Axis = Z then
         Translation (Names, Start, Final, Axis, Max_Velocity, Accel, Decel, Stopped, Callback, Entity);
      else
         Rotation (Names, Start, Final, Axis, Max_Velocity, Accel, Decel, Stopped, Callback, Entity, Which_Way);
      end if;
   end Motion;

   procedure Motion (Names : in Names_Array;
                     Start : in Float;
                     Final : in out Float;
                     Axis : in Axes;
                     Max_Velocity : in Float;
                     Accel : in Float;
                     Decel : in Float;
                     Stopped : out Boolean;
                     Callback : in Motion_Callback := Default_Motion'Access;
                     Entity : in String := "";
                     Which_Way : in Direction_To_Rotate := Shortest_Route) is
   begin
      if Axis = X or Axis = Y or Axis = Z then
         Translation (Names, Start, Final, Axis, Max_Velocity, Accel, Decel, Stopped, Callback, Entity);
      else
         Rotation (Names, Start, Final, Axis, Max_Velocity, Accel, Decel, Stopped, Callback, Entity, Which_Way);
      end if;
   end Motion;

   procedure Get_Terrain_Elevation (Z_North : in Float; X_East : in Float; Y_Elevation : out Float; Active : out Boolean) is
      Msg : Proxy.Query_Terrain_Elevation;
   begin
      Msg.Z_North := Z_North;
      Msg.X_East := X_East;
      P_S_Send_Inout (Msg);
      Y_Elevation := Msg.Y_Elevation;
      Active := Msg.Active;
   end Get_Terrain_Elevation;

   procedure Get_Coordinate (Assembly : in String; Pos : out Position; Ori : out Orientation; Active : out Boolean; Is_Absolute : in Boolean := False; Scale : out Position; Entity : in String := "") is
      Msg : Proxy.Query_Coordinate;
   begin
      Msg.Assembly := To_Name (Assembly);
      Msg.Entity := To_Name (Entity);
      Msg.Is_Absolute := Is_Absolute;
      P_S_Send_Inout (Msg);
      Pos := Msg.Pos;
      Ori := Msg.Ori;
      Active := Msg.Active;
      Scale := Msg.Scale;
   end Get_Coordinate;

   procedure Create_Object (Entity : String; Geom_Type : String; Pos : Position; Ori : Orientation; Ground_Clamp : Boolean := False; Is_Instance : Boolean := False) is
      Msg : Proxy.Init_Object;
   begin
      Msg.Entity := To_Name (Entity);
      Msg.Geom_Type := To_Name (Geom_Type);
      Msg.Pos := Pos;
      Msg.Ori := Ori;
      Msg.Ground_Clamp := Ground_Clamp;
      Msg.Is_Instance := Is_Instance;
      P_S_Send (Msg);
   end Create_Object;

   procedure Create_Effect (Entity : String; Fx_Type : String; Pos : Position; Ori : Orientation) is
      Msg : Proxy.Init_Effect;
   begin
      Msg.Entity := To_Name (Entity);
      Msg.Fx_Type := To_Name (Fx_Type);
      Msg.Pos := Pos;
      Msg.Ori := Ori;
      P_S_Send (Msg);
   end Create_Effect;

   procedure Set_Switch (Entity : String; Switch_Name : String; State : Integer) is
      Msg : Proxy.Set_Switch;
   begin
      Msg.Entity := To_Name (Entity);
      Msg.Switch_Name := To_Name (Switch_Name);
      Msg.State := State;
      P_S_Send (Msg);
   end Set_Switch;

   procedure Impact (Munition : String; Pos : Position) is
      Msg : Proxy.Set_Impact;
   begin
      Msg.Munition := To_Name (Munition);
      Msg.Pos := Pos;
      P_S_Send (Msg);
   end Impact;

   procedure Launch (Munition : String; Entity : String := "") is
      Msg : Proxy.Set_Launch;
   begin
      Msg.Munition := To_Name (Munition);
      Msg.Entity := To_Name (Entity);
      P_S_Send (Msg);
   end Launch;

   procedure Rot_Order (Entity : String; Dof : String; Rot_Order : String) is
      Msg : Proxy.Set_Rot_Order;
   begin
      Msg.Entity := To_Name (Entity);
      Msg.Dof := To_Name (Dof);
      Msg.Rot_Order := To_Name (Rot_Order);
      P_S_Send (Msg);
   end Rot_Order;

   -- enable and disable visual plotting of an entity's position.
   procedure StartPlot (Entity : String) is
      Msg : Proxy.Set_Start_Plot;
   begin
      Msg.Entity := To_Name(Entity);
      P_S_Send (Msg);
   end StartPlot;

   procedure StopPlot (Entity : String) is
      Msg : Proxy.Set_Stop_Plot;
   begin
      Msg.Entity := To_Name(Entity);
      P_S_Send (Msg);
   end StopPlot;

   procedure Player (Filename : String) is
      Msg : Proxy.Set_Player;
   begin
      Msg.Filename := To_Name(Filename);
      P_S_Send(Msg);
   end Player;

   -------------
   -- Uncheck --
   -------------

   procedure Uncheck is
   begin
      Suspend.Signal_To_Uncheck;
   end Uncheck;

   ------------
   -- UnLink --
   ------------

   procedure Unlink (Assembly : in String) is
   begin
      Wait_If_Check_Is_On (Assembly);
      if not Animation_Mode then
         Log ("unlink " & Assembly);
         return;
      end if;

      declare
         Msg : Proxy.Set_Unlink;
      begin
         Msg.Assembly := To_Name (Assembly);
         P_S_Send (Msg, Ack => True);
      end;
   exception
      when Stop =>
         Pace.Log.Put_Line ("--- Stopping UnLink", 8);
         null;
      when Stop_And_Propagate =>
         Pace.Log.Put_Line ("--- Stopping UnLink and Propagating ", 8);
         raise Stop_And_Propagate;
      when others =>
         null;
   end Unlink;

-- --------------------------------------
-- -- DEAD RECKONING section ------------
-- --------------------------------------

   package DRP is new Gis.Dead_Reckoning.Dead_Reckoner
      (Assembly => Proxy.Dvs_Record,
       Assembly_Name => Name,
       To_String => Interfaces.C.To_Ada,
       Render => Proxy.Render);

-- --------------------------------------
-- -- End DEAD RECKONING section --------
-- --------------------------------------

   -----------
   -- Proxy --
   -----------

   package body Proxy is separate;


   Assembly : constant String := "assembly";
   Coordinate : constant String := "coordinate";
   Create : constant String := "create";
   Geom_Type : constant String := "geom_type";
   Ground_Clamp : constant String := "ground_clamp";
   Event : constant String := "event";
   Variable : constant String := "variable";
   Float_Value : constant String := "value";
   Time_Scale_Value : constant String := "time_scale";
   X : constant String := "x";
   Y : constant String := "y";
   Z : constant String := "z";
   A : constant String := "a";
   B : constant String := "b";
   C : constant String := "c";


   use Pace.Server;

--   type Dvs is new Dispatch.Action with null record;
--   procedure Inout (Obj : in out Dvs);

   procedure Inout (Obj : in out Dvs) is
      Pos : Hal.Position;
      Rot : Hal.Orientation;
   begin
      if Key_Exists ("set") then
         Pace.Server.Put_Data (" Time_Scale : " & Value ("set"));
         Time_Scale (Keys.Value ("set", 1.0));
      elsif Key_Exists (Time_Scale_Value) then
         Pace.Server.Put_Data (" Time_Scale : " & Value (Time_Scale_Value));
         Time_Scale (Float (Integer'Value (Value (Time_Scale_Value))));
         -- Pace.Log.Set_Time_Scale (Duration(Integer'Value (Value (Time_Scale))));

         -- Event
      elsif Key_Exists (Assembly) and Key_Exists (Event) then
         Pace.Server.Put_Data (Value (Assembly) & " : " & Value (Event));
         Set (Value (Assembly), Value (Event), 0.0);

         -- Variable
      elsif Key_Exists (Variable) and Key_Exists (Float_Value) then
         Pace.Server.Put_Data (Value (Variable) & " : " & Value (Float_Value));
         Set_Var (Value (Variable), Value (Float_Value));

         -- Position
      elsif Key_Exists (Assembly) and Key_Exists (X) then
         Pace.Server.Put_Data (Value (Assembly) & " : " & Value (X) &
                               " : " & Value (Y) & " : " & Value (Z));
         Pos := (Float'Value (Value (X)), Float'Value (Value (Y)),
                 Float'Value (Value (Z)));
         Set (Value (Assembly), Pos);

         -- set orientation
      elsif Key_Exists (Assembly) and Key_Exists (A) then
         Pace.Server.Put_Data (Value (Assembly) & " : " & Value (A) &
                               " : " & Value (B) & " : " & Value (C));
         Rot := (Float'Value (Value (A)), Float'Value (Value (B)),
                 Float'Value (Value (C)));
         Set (Value (Assembly), Rot);

         -- do a rotation from start to final orientation
      elsif Key_Exists (Assembly) and Key_Exists ("a1") then
         Pace.Server.Put_Data ("doing a rotation..");
         Rot := (Float'Value (Value ("a1")), Float'Value (Value ("b1")),
                 Float'Value (Value ("c1")));
         declare
            Final_Ori : Orientation := (Float'Value (Value ("a2")), Float'Value (Value ("b2")), Float'Value (Value ("c2")));
            Dummy : Boolean;
            Velocity : Rate;
         begin
            Velocity.Units := Hal.Rads (10.0);
            Rotation (Value (Assembly), Rot, Final_Ori, Velocity, Dummy);
         end;

      elsif Key_Exists (Assembly) and Key_Exists (Coordinate) then
         declare
            use Ual.Utilities;
            Active : Boolean;
            Is_Absolute : Boolean;
            Scale : aliased Position;
         begin
            if Value ("relative") = "yes" then
               Is_Absolute := False;
               Pace.Log.Put_Line ("asking for relative");
            else
               Is_Absolute := True;
               Pace.Log.Put_Line ("asking for absolute");
            end if;
            Pace.Log.Put_Line ("assembly is :" & Value (Assembly) & ":");
            Get_Coordinate (Pace.Strings.Trim (Value (Assembly)), Pos, Rot, Active, Is_Absolute, Scale);
            if Active then
               Pace.Server.Put_Data (Value (Assembly) & "<br/>");
               Pace.Server.Put_Data (" Pos-> (" & Float_Put (Pos.X, 4)
                                     & ", " & Float_Put (Pos.Y, 4) & ", " &
                                     Float_Put (Pos.Z, 4) & ")<br/>");
               Pace.Server.Put_Data (" Ori-> (" & Float_Put (Rot.A, 4) &
                                     ", " & Float_Put (Rot.B, 4) & ", " &
                                     Float_Put (Rot.C, 4) & ")<br/>");
               Pace.Server.Put_Data (" Scale-> (" & Float_Put (Scale.X, 4) &
                                     ", " & Float_Put (Scale.Y, 4) & ", " &
                                     Float_Put (Scale.Z, 4) & ")<br/>");
            else
               Pace.Server.Put_Data ("INACTIVE");
            end if;
         end;
      elsif Key_Exists ("check") then
         Check;
      elsif Key_Exists ("uncheck") then
         Uncheck;
      elsif Key_Exists ("check_override") then
         Check_Override;
         -- Then replaces with the maintenance screen
      elsif Key_Exists (Create) then
         Pos := (Float'Value (Value (X)), Float'Value (Value (Y)),
                 Float'Value (Value (Z)));
         Rot := (Float'Value (Value (A)), Float'Value (Value (B)),
                 Float'Value (Value (C)));
         Create_Object (Value (Create), Value (Geom_Type), Pos, Rot, Boolean'Value (Value (Ground_Clamp)));
      else
         Pace.Server.Put_Data (Pace.Tag (Obj) & " not found : " & Value (""));
      end if;

   end Inout;

   procedure Set_Spin (Name : in String; Spin_Amount : in Orientation) is
      Msg : Proxy.Spin;
   begin
      Msg.Assembly := To_Name (Name);
      Msg.Rot := Spin_Amount;
      P_S_Send (Msg);
   end Set_Spin;

   procedure Set_Scale (Name : in String; Scaling : in Position; Entity : in String := "") is
      Msg : Proxy.Scale;
   begin
      if not Animation_Mode then
         Log ("scale " & Name & " " & S (Scaling.X) & S (Scaling.Y) &
              S (Scaling.Z));
         return;
      end if;
      Msg.Assembly := To_Name (Name);
      Msg.Mag := Scaling;
      Msg.Entity := To_Name (Entity);
      P_S_Send (Msg);
   end Set_Scale;

--   type Dead_Reckoning is new Dispatch.Action with null record;
--   procedure Inout (Obj : in out Dead_Reckoning);
   procedure Inout (Obj : in out Dead_Reckoning) is
      use Dispatch;
      Part : String := U2s (Obj.Set);
   begin
      if Part = "" then
         Dead_Reckoning_On := not Dead_Reckoning_On;
         Log ("Dead Reckoning toggled " & Boolean'Image(Dead_Reckoning_On));
      else
         DRP.Set (To_Name (Part));
         Dead_Reckoning_On := True;
      end if;
   end Inout;

begin
   Dispatch.Save_Action (Dvs'(Pace.Msg with Set => Dispatch.Default));
   Dispatch.Save_Action (Dead_Reckoning'(Pace.Msg with Set => Dispatch.Default));

   if not Animation_Mode then
      Pace.Log.Set_Display (Old_Display'Unrestricted_Access);
   end if;

   Set_Var ("SCALE", Pace.Getenv ("PACE_TIME_SCALE", "1"));
exception
   when X : others =>
      Pace.Log.Ex (X, "elaboration");

end Hal.Generic_Sms;
