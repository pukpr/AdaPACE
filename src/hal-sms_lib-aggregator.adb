
with Pace.Log;
with Pace.Socket;
with Hal.Sms;

package body Hal.Sms_Lib.Aggregator is

   use Hal.Sms;
   use Hal.Sms.Proxy;

   function Id is new Pace.Log.Unit_Id;

   procedure Ada_Init;
   pragma Import (C, Ada_Init, "adainit");

   protected Vector is
      procedure Append (C : Coord_Record);
      procedure Send;
      procedure Elaborate;
   private
      Vec : Coord_Vec.Vector;
      Is_Elaborated : Boolean := False;
   end Vector;

   protected body Vector is

      procedure Append (C : Coord_Record) is
      begin
         Vec.Append (C);
      end Append;

      procedure Send is
      begin
         if Integer (Vec.Length) > 0 then
            declare
               Msg : Coordinate_Vector;
            begin
               Msg.V := Vec;
               Pace.Socket.Send (Msg);
               Vec.Clear;
            end;
         end if;
      end Send;

      procedure Elaborate is
      begin
         if not Is_Elaborated then
            Ada_Init;
            Is_Elaborated := True;
         end if;
      end Elaborate;

   end Vector;

   procedure Send_Coord (Assembly : String;
                         Pos : Position;
                         Ori : Orientation;
                         Entity : String) is
      Data : Coord_Record := (To_Name (Assembly), Pos, Ori, To_Name (Entity));
   begin
      Vector.Append (Data);
   end Send_Coord;

   procedure Send_Coord (Assembly : Name;
                         X, Y, Z : Float;
                         A, B, C : Float;
                         Entity : Name) is
      Data : Coord_Record := (Assembly, Position'(X, Y, Z), Orientation'(A, B, C), Entity);
   begin
      Vector.Elaborate;
      Vector.Append (Data);
   end Send_Coord;

   task Agent is pragma Task_Name (Pace.Log.Name);
   end Agent;

   task body Agent is
      Dt : Duration := 0.03;
      Time : Duration := Pace.Now;
   begin
      loop
         Time := Time + Dt;
         Pace.Log.Wait_Until (Time);
         Vector.Send;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

end Hal.Sms_Lib.Aggregator;
