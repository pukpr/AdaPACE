
with Pace.Log;
with Ada.Numerics.Elementary_Functions;
with Hal.Sms;
with Text_Io;
with Hal.Geometry_And_Trig;
with Hal.Key_Frame;
with Hal.Constraint_2d;

package body Hal.Jack_Track is

   function Id is new Pace.Log.Unit_Id;
   function UName return String renames Pace.Log.Name;

   -- Jack Track should move in 1.5 seconds for complete travel
   use Ada.Numerics.Elementary_Functions;

   X, Y, X0, Y0, Angle, Hinge : Float;
   P : Hal.Position := (0.0, 0.0, 0.0);
   O : Hal.Orientation := (0.0, 0.0, 0.0);
   Total_Time : Duration := 0.0;

   Slant : constant Float := Arctan (Width, Length);
   Bend : constant Float := Arctan ((Wheel + Base - width)/Height);

   function Get_Current_Orientation return Float is
   begin
      return O.A;
   end Get_Current_Orientation;

   Check_Tolerance : constant Duration := 0.01;
   procedure Time_Step is
   begin
      Total_Time := Total_Time + Duration (Delta_T);
      Pace.Log.Wait_Until (Total_Time);
      P.Y := Y + Offset;
      P.Z := X + Shift; -- Wheel - 0.05;
      Angle := Arctan (Y - Y0, X - X0) - Slant;
      O.A := Ada.Numerics.Pi / 2.0 - Angle; -- - 2.0*Slant;
      --Text_IO.Put_Line (X'Img & " " & Y'Img); Text_IO.Put_Line (X0'Img & " " & Y0'Img);
      Pace.Log.Put_Line (Total_Time'Img & " " & X'Img & " " & Y'Img & " " & X0'Img & " " & Y0'Img & " " & Hal.Degs (Angle)'Img, 20);
      declare
         Now : Duration := Pace.Now;
      begin
         Callback_Check (Hal.Position'(0.0, 0.0, 0.0));
         if Pace.Now - Now > Check_tolerance then
            Total_Time := Total_Time + Pace.Now - Now;
         end if;
      end;
      --Pace.Log.Put_Line ("### O.A is " & O.A'Img);
      Hal.Sms.Set (Name, P, O);
   end Time_Step;

   Bend1 : constant Float := Crook; -- 0.6
   Span : constant Float := Sqrt ((Width) * (Width) + Length * Length);
   Cam : constant Float := Sqrt (Radius * Radius - Base * Base);
   Travel_Run : constant Float := Radius;
   Short_Piece : constant Float := Short;

   Travel : Float := 0.0;

   function True_Theta (Wait : Boolean := False) return Float renames Elevation;
   function Crooked_Theta return Float is
   begin
      return Elevation - Bend1;
   end Crooked_Theta;


   Hash_Float : constant := 10_000;
   Key_Frame_Map : array (Integer range -Hash_Float .. Hash_Float) of Float := (others => Float'Last);

   procedure Constraint (Xm : in Float;
                         Ym : out Float) is
      Xm_Key : Integer := Integer (Xm * 1000.0);
   begin
      if Key_Frame_Map (Xm_Key) = Float'Last then
         Ym := Hal.Key_Frame.X (Back_Track, Xm, 0.01, 0.01);
         Key_Frame_Map (Xm_Key) := Ym;
      else
         Ym := Key_Frame_Map (Xm_Key);
      end if;
   exception
      when E : Constraint_Error =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line ("The index was likely out of bounds on the key_frame_map!!!");
   end;

   function Condition (X,Y,Xm,Ym : in Float) return Boolean is
   begin
      return X >= Xm;
   end;

   procedure Intersect_Back is
      procedure Constrainer is new Hal.Constraint_2d
        ( X0 => Back_track(Back_track'First).Y,
          X1 => Back_track(Back_track'Last).Y,
          DX => Pace.Getenv ("JACK_DELTA", 0.005),
          Length => Span,
          Constraint => Constraint,
          Condition => Condition);
      Scale, Theta : Float;
   begin
      Constrainer (Y, X, Theta, Scale);
      if Theta=0.0 and Scale=0.0 then
         Pace.Log.Put_line ("nothing");
      else
         X0 := X + Span * sin (Theta);
         Y0 := Y + Span * cos (Theta);
      end if;
   end;

   Last_X : Float;


   -- this task ensures that the gun is done elevating
   task Agent is pragma Task_Name (UName);
      entry Follow_Elevation (Crooked_Counter : in Integer;
                              True_Counter : in Integer);

   end Agent;
   task body Agent is
      Theta : Float;
      Crooked_Counter : Integer;
      True_Counter : Integer;
      Xi : Float;
      Yi : Float;
   begin
      Pace.Log.Agent_Id (Id);

      Hal.Sms.Set (Name, Start_Pos, Start_Ori);

      loop

         accept Follow_Elevation (Crooked_Counter : in Integer;
                                  True_Counter : in Integer) do
            Agent.Crooked_Counter := Crooked_Counter;
            Agent.True_Counter := True_Counter;
         end Follow_Elevation;

         loop

            Theta := Elevation;
            Pace.Log.Wait (0.06);
            exit when Theta = Elevation;

            Xi := -Wheel * Sin (Crooked_Theta);
            Yi := +Wheel * Cos (Crooked_Theta);

            Y := Yi + Float (Crooked_Counter) * Delta_T *
                        Up_Velocity * Sin (Crooked_Theta) +
                   Float (True_Counter) * Delta_T *
                     Up_Velocity * Sin (True_Theta);

            X := Xi + Float (Crooked_Counter) * Delta_T *
                        Up_Velocity * Cos (Crooked_Theta) +
                   Float (True_Counter) * Delta_T *
                     Up_Velocity * Cos (True_Theta);

            Intersect_Back; -- circle part;
            Time_Step;
         end loop;

      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   Current_Stage : Natural := 0;

   function Get_Current_Stage return Natural is
   begin
      return Current_Stage;
   end Get_Current_Stage;

   First_Entry : Boolean := True;
   Theta : Float;
   Crooked_Counter : Integer := 0;
   True_Counter : Integer := 0;

   procedure Up (Dest_Stage : in Natural := Natural'Last;
                 Step : in Boolean := False) is
      Xi : Float;
      Yi : Float;
   begin
      Total_Time := Pace.Now;
      if Dest_Stage = 0 then
         return;
      end if;
      loop
         case Current_Stage is
            -- To do a step, enter into any one of these states, and do a single loop.
            -- If the exit criteria is met before the end of the loop, set the state transition
            -- for the next go around.  This is done atomatically after the loop, since otherwise
            -- the call simply returns.
            when 0 =>
               -- Straight Up along short section
               if First_Entry then
                  Travel := 0.0;
                  X := Base - Width;
                  X0 := Base;
                  Y := -Height - Short_Piece;
                  First_Entry := False;
               end if;

               loop
                  Y := Y + Delta_T * Up_Velocity;
                  Y0 := Y - Length;
                  Intersect_Back; -- straight line part
                  exit when Y > -Height;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;
            when 1 =>
               if First_Entry then
                  -- Straight Up along Bent rail
                  --  X := Base - Width;
                  Y := -Height;
                  Hinge := -Wheel * Sin (Bend);
                  First_Entry := False;
               end if;

               loop
                  Y := Y + Delta_T * Up_Velocity * Cos (Bend);
                  X := X - Delta_T * Up_Velocity * Sin (Bend);
                  Intersect_Back; -- straight line part
                  exit when Y > Hinge;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 2 =>
               if First_Entry then
                  -- Wheel
                  Theta := -Bend;
                  First_Entry := False;
               end if;
               loop
                  Theta := Theta + Delta_T * Up_Velocity / Wheel;
                  X := -Wheel * Cos (Theta);
                  Y := Wheel * Sin (Theta);
                  Intersect_Back; -- straight line part
                  exit when Theta > Ada.Numerics.Pi / 2.0 - Crooked_Theta;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 3 =>
               --Xi := X;
               --Yi := Y;
               if First_Entry then
                  True_Counter := 0;
                  Crooked_Counter := 0;
                  First_Entry := False;
               end if;

               -- Crooked path into true path
               --Theta := Crooked_Theta;
               loop

                  if Travel > Travel_Run then
                     True_Counter := True_Counter + 1;
                  else
                     Crooked_Counter := Crooked_Counter + 1;
                  end if;

                  Xi := -Wheel * Sin (Crooked_Theta);
                  Yi := +Wheel * Cos (Crooked_Theta);

                  --Y := Y + Delta_T * Up_Velocity * Sin (Theta);
                  Y := Yi + Float (Crooked_Counter) * Delta_T *
                              Up_Velocity * Sin (Crooked_Theta) +
                         Float (True_Counter) * Delta_T * Up_Velocity * Sin (True_Theta);

                  --X := X + Delta_T * Up_Velocity * Cos (Theta);
                  X := Xi + Float (Crooked_Counter) * Delta_T *
                              Up_Velocity * Cos (Crooked_Theta) +
                         Float (True_Counter) * Delta_T * Up_Velocity * Cos (True_Theta);

                  Travel := Travel + Delta_T * Up_Velocity;
                  Intersect_Back; -- straight line part
                  Last_X := X;
                  exit when Travel >= Travel_Run or Angle < True_Theta;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 4 =>
               if First_Entry then
                  First_Entry := False;
               end if;
               loop

                  True_Counter := True_Counter + 1;

                  Xi := -Wheel * Sin (Crooked_Theta);
                  Yi := +Wheel * Cos (Crooked_Theta);

                  Y := Yi + Float (Crooked_Counter) * Delta_T *
                              Up_Velocity * Sin (Crooked_Theta) +
                         Float (True_Counter) * Delta_T * Up_Velocity * Sin (True_Theta);

                  X := Xi + Float (Crooked_Counter) * Delta_T *
                              Up_Velocity * Cos (Crooked_Theta) +
                         Float (True_Counter) * Delta_T * Up_Velocity * Cos (True_Theta);

                  Intersect_Back; -- circle part;
                  -- stay a bit under so as not to overshoot
                  exit when Angle < True_Theta;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;
               Agent.Follow_Elevation (Crooked_Counter, True_Counter);
            when others =>
               Pace.Log.Put_Line ("Warning: JACK TRACK ends above, improper state machine", 2);
               return;
         end case;
         if Current_Stage < Dest_Stage then
            Current_Stage := Current_Stage + 1;
            First_Entry := True;
         end if;
         exit when Current_Stage = Dest_Stage;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E, "raising Jack Track");
   end Up;

   procedure Down (Dest_Stage : in Natural := 0;
                   Step : in Boolean := False) is
      --Theta : Float;
   begin
      Total_Time := Pace.Now;
      if Dest_Stage >= 5 then
         return;
      end if;
      loop
         case Current_Stage is
            when 5 =>
               --Theta := True_Theta;
               -- Follow circle down
               loop
                  Y := Y - Delta_T * Down_Velocity * Sin (True_Theta);
                  X := X - Delta_T * Down_Velocity * Cos (True_Theta);
                  Intersect_Back; -- circle part;
                  exit when X < Last_X;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 4 =>
               --Pace.Log.Put_Line ("INSIDE 4 " & First_Entry'Img);
               loop
                  Y := Y - Delta_T * Down_Velocity * Sin (Crooked_Theta);
                  X := X - Delta_T * Down_Velocity * Cos (Crooked_Theta);
                  Travel := Travel - Delta_T * Down_Velocity;
                  Intersect_Back; -- straight line part
                  exit when Travel < 0.0;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 3 =>
               --Pace.Log.Put_Line ("INSIDE 3 " & First_Entry'Img);
               if First_Entry then
                  -- Wheel
                  Theta := Ada.Numerics.Pi / 2.0 - Crooked_Theta;
                  First_Entry := False;
               end if;
               loop
                  Theta := Theta - Delta_T * Down_Velocity / Wheel;
                  X := -Wheel * Cos (Theta);
                  Y := Wheel * Sin (Theta);
                  Intersect_Back; -- straight line part
                  exit when Theta < -Bend;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 2 =>
               -- Down bent slope
               loop
                  Y := Y - Delta_T * Down_Velocity * Cos (Bend);
                  X := X + Delta_T * Down_Velocity * Sin (Bend);
                  Intersect_Back; -- straight line part
                  exit when Y < -Height;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;

            when 1 =>
               loop
                  Y := Y - Delta_T * Down_Velocity;
                  Y0 := Y - Length;
                  exit when Y < -Height - Short_Piece;
                  Time_Step;
                  if Step then
                     return;
                  end if;
               end loop;
            when others =>
               Pace.Log.Put_Line ("Warning: JACK TRACK can't go that high, improper state machine");
               return;
         end case;
         if Current_Stage > Dest_Stage then
            Current_Stage := Current_Stage - 1;
            First_Entry := True;
         end if;
         exit when Current_Stage = Dest_Stage;
      end loop;
      if Dest_Stage = 0 then
         Hal.Sms.Set (Name, Start_Pos, Start_Ori);
      end if;

   exception
      when E : Hal.Sms.Stop_And_Propagate =>
         raise Hal.Sms.Stop_And_Propagate;
      when E: others =>
         Pace.Log.Ex (E, "lowering Jack Track");
   end Down;

-- $id: hal-jack_track.adb,v 1.10 12/22/2003 22:19:27 pukitepa Exp $
end Hal.Jack_Track;
