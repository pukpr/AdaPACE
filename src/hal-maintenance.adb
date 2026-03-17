with Hal.Sms;
with Pace.Log;
with Pace.Socket;
with Ada.Numerics;

package body Hal.Maintenance is

   procedure Url_Configure_Params (Obj : in out Step'Class;
                                   Params : out Step_Parameters) is
      Speed : Hal.Rate;
      Amount : Float;
      Direction : String := Pace.Server.Value ("direction");
   begin
      Speed.Units := Pace.Server.Keys.Value ("speed_units", 1.0);
      if Obj in Step_Rotate'Class then
         Speed.Units := Hal.Rads (Speed.Units);
      end if;
      if Direction = "home" then
         Amount := Home;
      else
         Amount := Pace.Server.Keys.Value ("amount", 1.0);
         if Obj in Step_Rotate'Class then
            Amount := Hal.Rads (Amount);
         end if;
         if Direction = "neg" then
            Amount := -1.0 * Amount;
         end if;
      end if;
      -- and finally, assign values to Params
      Params.Amount := Amount;
      Params.Speed := Speed;
   end Url_Configure_Params;


   procedure Check_Limits (Obj : in out Step'Class) is
   begin
      if Obj.Destination_Location < Obj.Lower_Limit then
         Pace.Log.Put_Line (Ada.Strings.Unbounded.To_String
                              (Obj.Assembly_Name) &
                            " has attempted to step to " &
                            Float'Image (Obj.Destination_Location) &
                            " which is beyond it's lower limit of " &
                            Float'Image (Obj.Lower_Limit));
         Obj.Destination_Location := Obj.Lower_Limit;
      elsif Obj.Destination_Location > Obj.Upper_Limit then
         Pace.Log.Put_Line (Ada.Strings.Unbounded.To_String
                              (Obj.Assembly_Name) &
                            " has attempted to step to " &
                            Float'Image (Obj.Destination_Location) &
                            " which is beyond it's upper limit of " &
                            Float'Image (Obj.Upper_Limit));
         Obj.Destination_Location := Obj.Upper_Limit;
      end if;
   end Check_Limits;

   procedure Calculate_Destination (Obj : in out Step'Class; Amount : Float) is
   begin
      if Amount = Home then
         case Obj.Axis is
            when X =>
               Obj.Destination_Location := Obj.Home_Location.X;
            when Y =>
               Obj.Destination_Location := Obj.Home_Location.Y;
            when Z =>
               Obj.Destination_Location := Obj.Home_Location.Z;
         end case;
      else
         Obj.Destination_Location := Obj.Current_Location + Amount;
      end if;
   end Calculate_Destination;

   -- uses lower limit as 0% and upper limit as 100%
   function Calculate_Location_As_Percent (Obj : Step'Class) return Float is
      Numerator : Float;
      Percent : Float;
   begin
      Numerator := Obj.Current_Location - Obj.Lower_Limit;
      Percent := 100.0 * Numerator / (Obj.Upper_Limit - Obj.Lower_Limit);
      return Percent;
   end Calculate_Location_As_Percent;

   function Get_Location_As_Absolute
              (Obj : in Step'Class)
              return Ada.Strings.Unbounded.Unbounded_String is
      Absolute : Float;
      Str : String (1 .. 9);
      use Float_Display_Io;
      use Pace.Server.Dispatch;
   begin
      Absolute := Obj.Current_Location;
      if Obj in Step_Rotate'Class then
         Absolute := Absolute * 180.0 / Ada.Numerics.Pi;
      end if;
      Put (Str, Float_Display (Absolute), 4, 0);
      return Ada.Strings.Unbounded.To_Unbounded_String(Str);
   end Get_Location_As_Absolute;


   -- Step_Translate methods
   procedure Perform_Action (Obj : in out Step_Translate;
                             Params : in out Step_Parameters) is
      Stopped : Boolean;
      Destination_Pos : Hal.Position;
   begin
      Destination_Pos := Get_Destination_Pos (Obj);
      Hal.Sms.Translation (Ada.Strings.Unbounded.To_String (Obj.Assembly_Name),
                           Get_Current_Pos (Obj), Destination_Pos,
                           Params.Speed, Stopped, 0.0, 0.0);
      case Obj.Axis is
         when X =>
            Obj.Current_Location := Destination_Pos.X;
         when Y =>
            Obj.Current_Location := Destination_Pos.Y;
         when Z =>
            Obj.Current_Location := Destination_Pos.Z;
      end case;
   end Perform_Action;

   function Get_Current_Pos (Obj : Step_Translate'Class) return Hal.Position is
      Result : Hal.Position;
   begin
      Result.X := Obj.Home_Location.X;
      Result.Y := Obj.Home_Location.Y;
      Result.Z := Obj.Home_Location.Z;
      case Obj.Axis is
         when X =>
            Result.X := Obj.Current_Location;
         when Y =>
            Result.Y := Obj.Current_Location;
         when Z =>
            Result.Z := Obj.Current_Location;
      end case;
      return Result;
   end Get_Current_Pos;

   function Get_Destination_Pos
              (Obj : Step_Translate'Class) return Hal.Position is
      Result : Hal.Position;
   begin
      Result.X := Obj.Home_Location.X;
      Result.Y := Obj.Home_Location.Y;
      Result.Z := Obj.Home_Location.Z;
      case Obj.Axis is
         when X =>
            Result.X := Obj.Destination_Location;
         when Y =>
            Result.Y := Obj.Destination_Location;
         when Z =>
            Result.Z := Obj.Destination_Location;
      end case;
      return Result;
   end Get_Destination_Pos;


   -- Step_Rotate methods
   procedure Perform_Action (Obj : in out Step_Rotate;
                             Params : in out Step_Parameters) is
      Stopped : Boolean;
      Destination_Ori : Hal.Orientation;
   begin
      Destination_Ori := Get_Destination_Ori (Obj);
      Hal.Sms.Rotation (Ada.Strings.Unbounded.To_String (Obj.Assembly_Name),
                        Get_Current_Ori (Obj), Destination_Ori,
                        Params.Speed, Stopped, 0.0, 0.0);
      case Obj.Axis is
         when X =>
            Obj.Current_Location := Destination_Ori.A;
         when Y =>
            Obj.Current_Location := Destination_Ori.B;
         when Z =>
            Obj.Current_Location := Destination_Ori.C;
      end case;
   end Perform_Action;


   function Get_Current_Ori (Obj : Step_Rotate'Class) return Hal.Orientation is
      Result : Hal.Orientation;
   begin
      Result.A := Obj.Home_Location.X;
      Result.B := Obj.Home_Location.Y;
      Result.C := Obj.Home_Location.Z;
      case Obj.Axis is
         when X =>
            Result.A := Obj.Current_Location;
         when Y =>
            Result.B := Obj.Current_Location;
         when Z =>
            Result.C := Obj.Current_Location;
      end case;
      return Result;
   end Get_Current_Ori;

   function Get_Destination_Ori
              (Obj : Step_Rotate'Class) return Hal.Orientation is
      Result : Hal.Orientation;
   begin
      Result.A := Obj.Home_Location.X;
      Result.B := Obj.Home_Location.Y;
      Result.C := Obj.Home_Location.Z;
      case Obj.Axis is
         when X =>
            Result.A := Obj.Destination_Location;
         when Y =>
            Result.B := Obj.Destination_Location;
         when Z =>
            Result.C := Obj.Destination_Location;
      end case;
      return Result;
   end Get_Destination_Ori;


   -- adjusts amount for saving onto the undo stack
   -- this is necessary in case the step attempted to move beyond one of
   -- it's limits, or for any reason that the hal movement didn't go as
   -- far as planned
   -- Also, swaps the sign of the amount, thereby switching direction of
   -- motion.
   procedure Adjust_Amount (Amount : in out Float; Difference : Float) is
      Positive : Boolean := False;
   begin
      if Amount >= 0.0 then
         Amount := -1.0 * Difference;
      else
         Amount := Difference;
      end if;
   end Adjust_Amount;


   -- following is needed for Undo capabilities

   procedure Input (Obj : in Save) is
   begin
      Guarded_Stack.Put (Obj.Execute_Object);
   end Input;

   procedure Execute (Obj : in out Step_Transaction'Class) is
      Msg : Save;
   begin
      -- send to application
      Pace.Socket.Send_Inout (Obj);
      Msg.Execute_Object := Pace.To_Channel_Msg (Obj);
      -- sent to save stack
      Pace.Socket.Send (Msg);
   end Execute;

   procedure Undo is
      C_Msg : Pace.Channel_Msg;
   begin
      -- what should happen when stack is empty? .. should there be a boolean
      -- out variable telling the caller whether or not the undo completed
      -- successfully?
      if Guarded_Stack.Is_Ready then
         Guarded_Stack.Get (C_Msg);
         declare
            Msg : Step_Transaction'Class :=
              Step_Transaction'Class (Pace.To_Msg (C_Msg));
         begin
            -- this does the undo
            Pace.Socket.Send_Inout (Msg);
         end;
      end if;
   end Undo;

end Hal.Maintenance;

