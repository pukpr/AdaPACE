with Ada.Numerics.Elementary_Functions;
with Pace.Socket;
with Pace.Log;
with Hal.Rotations;
with Interfaces.C;

package body Hal.Sms_Lib.Ribbon is

   use Ada.Numerics.Elementary_Functions;

   Ca : Hal.Sms.Proxy.Coordinate_Array_Safe (Links);

   procedure Step (Number : in Integer := 1;
                   Relative_Orientation_Per_Link : in Boolean := True) is
      
      function Check_Relative (Value : in  Hal.Orientation) return Hal.Orientation is
      begin
         if Relative_Orientation_Per_Link then
            return Value;
         else
            return (0.0, 0.0, 0.0);
         end if;
      end Check_Relative;

      Number_Steps : Integer := 0;

      procedure Send is
      begin
         Pace.Socket.Send (Ca, Ack => False);
         if Time_Delta > 0.0 then
            Pace.Log.Wait (Time_Delta);
         end if;
      end;   
      
   begin
      -- update Links by morphing one position into the next
      loop
         Ca.List (1).Rot := Check_Relative (Ca.List (1).Rot) + 
                            Flex (1, Ca.List (1).Pos);
         for I in 2 .. Links loop
            Ca.List (I).Rot := Check_Relative (Ca.List (I - 1).Rot) + 
                               Flex (I, Ca.List (I).Pos);
            Ca.List (I).Pos := Ca.List (I - 1).Pos +
                                 Hal.Rotations.R3_Div (Segment,
                                                   Ca.List (I - 1).Rot);
         end loop;
         if Number > 0 then
            Send;
         end if;
         Number_Steps := Number_Steps + 1;
         exit when Number_Steps >= Number;
      end loop;
   end Step;

   function Calculate_Deflection (Relative_Orientation_Per_Link : in Boolean := True) 
     return Hal.Position is
   begin
      Step (0, Relative_Orientation_Per_Link);
      return Ca.List (Links).Pos;
   end Calculate_Deflection;

   procedure Initialize is
   begin
      -- Initialize links
      Ca.List (1).Assembly :=
        Hal.Sms.To_Name (Interfaces.C.To_Ada (Base.Assembly) & Integer'Image (-1));
      Ca.List (1).Pos := Base.Pos;
      Ca.List (1).Rot := Base.Rot;
      for I in 2 .. Links loop
         Ca.List (I).Assembly :=
           Hal.Sms.To_Name (Interfaces.C.To_Ada (Base.Assembly) & Integer'Image (-I));
         Ca.List (I).Rot := Base.Rot;
         Ca.List (I).Pos := Ca.List (I - 1).Pos + Base.Pos;
      end loop;
   end Initialize;

begin
   Initialize;
exception
   when E: others =>
      Pace.Log.Ex (E, "elaborate ribbon");
end Hal.Sms_Lib.Ribbon;
