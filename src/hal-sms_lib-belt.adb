with Pace.Socket;
with Hal.Fp_Utilities;
with Hal.Sms;
with Pace.Log;
with Pace.Strings;

package body Hal.Sms_Lib.Belt is

   package Circ is new Hal.Fp_Utilities.Circular (0.0, Rads (360.0));

   Slots : Hal.Sms.Proxy.Coordinate_Array_Safe (Size => Initial_Six_Dof'Length);

   subtype Slot_Range is Integer range Slots.List'First .. Slots.List'Last;

   Trk : Hal.Sms.Proxy.Coordinate_Array_Safe (Slots.Size * Intervals);
   subtype Track_Range is Integer range Trk.List'First .. Trk.List'Last;

   -- this is the minor slot at Track Index 1
   -- (note-> this is not the track index at slot 1... run this through mirror_effect to get this)
   Cur_Minor          : Track_Range := 1;

   function Major_To_Minor (Major_Slot : Float) return Integer is
      Result : Float := (Major_Slot - 1.0) * Float (Intervals) + 1.0;
   begin
      return Integer (Result);
   end Major_To_Minor;

   function Major_To_Minor (Major_Slot : Integer) return Integer is
   begin
      return Major_To_Minor (Float (Major_Slot));
   end Major_To_Minor;

   function Minor_To_Major (Minor_Slot : Integer) return Float is
   begin
      return Float (Minor_Slot - 1) / Float (Intervals) + 1.0;
   end Minor_To_Major;

   procedure Minor_To_Major (Minor_Slot : Integer; Success : out Boolean; Major_Slot : out Integer) is
   begin
      if (Minor_Slot - 1) mod Intervals = 0 then
         Success := True;
         Major_Slot := Integer (Minor_To_Major (Minor_Slot));
      else
         Success := False;
      end if;
   end Minor_To_Major;

   function Absolute_To_Minor (Absolute : Float) return Integer is
      Minor_Slot : Integer := Integer ((Absolute / Distance_Between_Slots - 1.0) * Float(Intervals) + 1.0);
   begin
      if Minor_Slot < 0 then
         Minor_Slot := Minor_Slot mod Slots.Size;
      end if;
      return Minor_Slot;
   end Absolute_To_Minor;

   function Minor_To_Absolute (Minor : Integer) return Float is
      Absolute : Float := Float (Minor - 1) / Float (Intervals) + 1.0 * Distance_Between_Slots;
   begin
      if Minor > Major_To_Minor (Slots.Size) then
         Absolute := Absolute - Float (Major_To_Minor (Slots.Size));
      end if;
      return Absolute;
   end Minor_To_Absolute;

   function Get_Current_Minor_Slot return Integer is
   begin
      return Cur_Minor;
   end Get_Current_Minor_Slot;

   function Get_Current_Major_Slot return Float is
   begin
      return Minor_To_Major (Cur_Minor);
   end Get_Current_Major_Slot;

   function Get_Current_Absolute return Float is
   begin
      return Minor_To_Absolute (Cur_Minor);
   end Get_Current_Absolute;

   procedure Setup_Slots is
   begin
      Cur_Minor := 1;
      for I in 1 .. Slots.Size loop
         Slots.List (I) := (Hal.Sms.To_Name (Prefix & Pace.Strings.Trim (I)),
                            Initial_Six_Dof (I).Pos,
                            Initial_Six_Dof (I).Ori,
                            Hal.Sms.To_Name (Entity));
      end loop;
   end Setup_Slots;

   -- occurs instantaneously
   procedure Initialize_Slots is
   begin
      Setup_Slots;
      declare
         Msg : Hal.Sms.Proxy.Coordinate_Array_Safe := Slots;
      begin
         Pace.Socket.Send (Slots, Ack => True);
      end;
   end Initialize_Slots;

   function Mirror_Effect (Value : Track_Range) return Track_Range is
   begin
      if Value = 1 then
         return 1;
      else
         return Track_Range'Last + 2 - Value;
      end if;
   end Mirror_Effect;

   procedure Set_Coordinate (Minor_slot : Integer) is
      Msg : Hal.Sms.Proxy.Coordinate_Array_Safe := Slots;
   begin
      Cur_Minor := Minor_Slot;
      for Index in Slot_Range loop
         declare
            I : Integer := (Index - 1) * Intervals + Mirror_Effect (Cur_Minor);
         begin
            if I > Track_Range'Last then
               I := I mod Track_Range'Last;
            end if;
            Msg.List (Index).Pos := Trk.List (I).Pos;
            Msg.List (Index).Rot := Trk.List (I).Rot;
         end;
      end loop;
      if Slot_Pick = 0 then
         Pace.Socket.Send (Msg, Ack => True);
      else
         declare
            M : Hal.Sms.Proxy.Coordinate;
         begin
            M.Assembly := Msg.List (Slot_Pick).Assembly;
            M.Pos      := Msg.List (Slot_Pick).Pos;
            M.Rot      := Msg.List (Slot_Pick).Rot;
            M.Entity   := Msg.List (Slot_Pick).Entity;
            Pace.Socket.Send (M, Ack => True);
         end;
      end if;
   end Set_Coordinate;

   procedure Step
     (Direction : in Belt_Direction;
      Number : in Integer := 1)
   is
      Number_Steps : Integer                             := 0;
      Time         : Duration                            := Pace.Now;
   begin
      -- update Slots by morphing one position into the next
      loop
         if Direction = Increasing then
            if Cur_Minor = Track_Range'Last then
               Cur_Minor := Track_Range'First;
            else
               Cur_Minor := Cur_Minor + 1;
            end if;
         else
            if Cur_Minor = Track_Range'First then
               Cur_Minor := Track_Range'Last;
            else
               Cur_Minor := Cur_Minor - 1;
            end if;
         end if;
         Set_Coordinate (Cur_Minor);
         Number_Steps := Number_Steps + 1;
         Time         := Time + Time_Delta / Duration (Intervals);
         Pace.Log.Wait_Until (Time);
         Track_Callback (Cur_Minor);
         exit when Number_Steps = Number;
      end loop;
   end Step;

   function Morph_Rot
     (Current, Next : in Slot_Range;
      Interval      : in Track_Range)
      return          Orientation
   is
      C  : Orientation renames Slots.List (Current).Rot;
      N  : Orientation renames Slots.List (Next).Rot;
      R  : Orientation;
      Fn : Float := Float (Interval - 1) / Float (Intervals);
   begin
      R.A := Circ.Add (C.A, Circ.Difference (N.A, C.A) * Fn);
      R.B := Circ.Add (C.B, Circ.Difference (N.B, C.B) * Fn);
      R.C := Circ.Add (C.C, Circ.Difference (N.C, C.C) * Fn);
      return R;
   end Morph_Rot;

   function Morph_Pos
     (Current, Next : in Slot_Range;
      Interval      : in Track_Range)
      return          Position
   is
      C  : Position renames Slots.List (Current).Pos;
      N  : Position renames Slots.List (Next).Pos;
      P  : Position;
      Fn : Float := Float (Interval - 1) / Float (Intervals);
   begin
      P.X := C.X + (N.X - C.X) * Fn;
      P.Y := C.Y + (N.Y - C.Y) * Fn;
      P.Z := C.Z + (N.Z - C.Z) * Fn;
      return P;
   end Morph_Pos;

   subtype Spline_Range is Integer range 0 .. Intervals * 2;
   S1, S2, S3 : array (Spline_Range) of Float;

   function Spline
     (V_Start, V_Mid, V_End : in Float;
      Interval              : in Spline_Range)
      return                  Float
   is
      Vm : Float := (V_Mid - (V_Start + V_End) / 2.0) + V_Mid; -- mid-points
   begin
      return V_Start * S1 (Interval) +
             Vm * S2 (Interval) +
             V_End * S3 (Interval);
   end Spline;

   procedure Spline
     (P_Start, P_Mid, P_End : in Slot_Range;
      Interval              : in Spline_Range;
      X, Y, Z               : out Float)
   is
      Ps : Position renames Slots.List (P_Start).Pos;
      Pm : Position renames Slots.List (P_Mid).Pos;
      Pe : Position renames Slots.List (P_End).Pos;
   begin
      X := Spline (Ps.X, Pm.X, Pe.X, Interval);
      Y := Spline (Ps.Y, Pm.Y, Pe.Y, Interval);
      Z := Spline (Ps.Z, Pm.Z, Pe.Z, Interval);
   end Spline;

   function Spline_Pos
     (Current, Next, Ahead, Behind : in Slot_Range;
      Interval                     : in Track_Range)
      return                         Position
   is
      P                      : Position;
      Fn                     : Float :=
         Float (Interval - 1) / Float (Intervals);
      X1, Y1, Z1, X2, Y2, Z2 : Float;
   begin
      Spline (Behind, Current, Next, Intervals + Interval - 1, X1, Y1, Z1);
      Spline (Current, Next, Ahead, Interval - 1, X2, Y2, Z2);

      P.X := X1 + (X2 - X1) * Fn;
      P.Y := Y1 + (Y2 - Y1) * Fn;
      P.Z := Z1 + (Z2 - Z1) * Fn;
      return P;
   end Spline_Pos;

   procedure Initialize_Spline is
      T : Float;
   begin
      for I in  Spline_Range loop
         T      := Float (I) / Float (Spline_Range'Last);
         S1 (I) := 1.0 - 2.0 * T + T * T;
         S2 (I) := 2.0 * T * (1.0 - T);
         S3 (I) := T * T;
      end loop;
   end Initialize_Spline;

   procedure Shortest_Route (Dest_Minor_Slot : in Integer;
                             Direction : out Belt_Direction;
                             Minor_Slot_Distance : out Integer) is
      Max : Integer := Trk.Size;
      Incr_Distance, Decr_Distance : Integer := 0;
   begin
      if Dest_Minor_Slot = Cur_Minor then
         Minor_Slot_Distance := 0;
      else
         if Dest_Minor_Slot > Cur_Minor then
            Incr_Distance := Dest_Minor_Slot - Cur_Minor;
            Decr_Distance := Max - Incr_Distance;
         else
            Decr_Distance := Cur_Minor - Dest_Minor_Slot;
            Incr_Distance := Max - Decr_Distance;
         end if;
         if Incr_Distance < Decr_Distance then
            Direction := Increasing;
            Minor_Slot_Distance := Incr_Distance;
         else
            Direction := Decreasing;
            Minor_Slot_Distance := Decr_Distance;
         end if;
      end if;
   end Shortest_Route;

   procedure Select_Major_Slot (Major_Slot : in Integer) is
   begin
      Select_Minor_Slot (Major_To_Minor (Float (Major_Slot)));
   end Select_Major_Slot;

   procedure Select_Major_Slot_Absolute (Major_Slot : in Float) is
   begin
      Select_Minor_Slot (Major_To_Minor (Major_Slot));
   end Select_Major_Slot_Absolute;

   procedure Select_Major_Slot_Relative (Relative : in Float) is
   begin
      Select_Major_Slot_Absolute (Get_Current_Major_Slot + Relative);
   end Select_Major_Slot_Relative;

   procedure Select_Absolute_Meters (Absolute : Float) is
   begin
      Select_Minor_Slot (Absolute_To_Minor (Absolute));
   end Select_Absolute_Meters;

   procedure Select_Relative_Meters (Relative : Float) is
   begin
      Select_Absolute_Meters (Get_Current_Absolute + Relative);
   end Select_Relative_Meters;

   procedure Select_Minor_Slot (Minor_Slot : in Integer) is
      Direction : Belt_Direction;
      Amount : Integer := 0;
   begin
      Shortest_Route (Minor_Slot, Direction, Amount);
      if Amount > 0 then
         Step (Direction, Amount);
      end if;
   end Select_Minor_Slot;

   procedure Initialize_Track is
   begin
      Initialize_Spline;
      for Index in  Slot_Range loop
         for Interval in  1 .. Intervals loop
            declare
               Next, Behind, Ahead : Slot_Range;
               I                   : Track_Range;
            begin
               if Index = Slot_Range'Last then
                  Next := Slot_Range'First;
               else
                  Next := Index + 1;
               end if;
               if Next = Slot_Range'Last then
                  Ahead := Slot_Range'First;
               else
                  Ahead := Next + 1;
               end if;
               if Index = Slot_Range'First then
                  Behind := Slot_Range'Last;
               else
                  Behind := Index - 1;
               end if;

               I := Intervals * (Index - 1) + Interval;
               if True then -- always do spline on position updates
                  Trk.List (I).Pos :=
                    Spline_Pos (Index, Next, Ahead, Behind, Interval);
               else -- available for testing
                  Trk.List (I).Pos := Morph_Pos (Index, Next, Interval);
               end if;
               Trk.List (I).Rot := Morph_Rot (Index, Next, Interval);
            end;
         end loop;
      end loop;
   end Initialize_Track;

   procedure Set_Major_Slot (Major_Slot : in Float) is
   begin
      Set_Coordinate (Major_To_Minor (Major_Slot));
   end Set_Major_Slot;

begin
   Setup_Slots;
   Initialize_Track;
exception
   when E : others =>
      Pace.Log.Ex (E, "elaborate belt");
end Hal.Sms_Lib.Belt;
