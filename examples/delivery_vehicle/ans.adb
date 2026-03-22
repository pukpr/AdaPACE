with Pace.Socket;
package body ANS is

   -- Stub Version of ANS

   DX, DY, DH : Float := 0.0;

   procedure Input (Obj : in Start_Msg) is
   begin
      null;
   end;

   procedure Input (Obj : in Update_Msg) is
   begin
      DX := Obj.DX;
      DY := Obj.DY;
      DH := Obj.DH;
   end;

   procedure Output (Obj : out Position_Msg) is
   begin
      Obj.Easting := DX;
      Obj.Northing := DY;
      Obj.Heading := DH;
   end;


end;
