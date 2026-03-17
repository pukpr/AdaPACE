with Hal.Sms;
with Pace.Socket;

package body Hal.Sms_Lib.Mesh is

   procedure Send (Name : in String;
                   Msg : in SD) is
      L : constant Integer := Msg'Length;
      M : Hal.Sms.Proxy.Coordinate_Array_Safe(L);
   begin
      for I in 1..L loop
         M.List(I).Pos := Msg(I).P;
         M.List(I).Rot := Msg(I).R;
         M.List(I).Assembly := Hal.Sms.To_Name (Name & Integer'Image(-I));
      end loop;
      Pace.Socket.Send (M);
   end;

   -- $Id: hal-sms_lib-mesh.adb,v 1.1 2006/05/25 19:01:18 ludwiglj Exp $
end;
