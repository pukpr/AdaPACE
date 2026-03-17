with Pace.Server.Dispatch;

separate (Hal.Generic_Sms)
package body Proxy is

   -----------
   -- Input --
   -----------

   procedure Input (Obj : in Shape) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Translate) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Rotate) is
   begin
      null; -- Log ("ROT");
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Coordinate) is
      use Interfaces.C;
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Set_Event) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Set_Link) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Set_Unlink) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Set_Variable) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Translate_Array) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Rotate_Array) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Coordinate_Array) is
   begin
      null;
   end Input;

   procedure Input (Obj : Coordinate_Array_Safe) is
      use Interfaces.C;
   begin
      if Animation_Mode then
         return;
      end if;
      for I in 1..Obj.Size loop
         declare
            A : Name renames Obj.List(I).Assembly;
            P : Position renames Obj.List(I).Pos;
            R : Orientation renames Obj.List(I).Rot;
         begin
         Log ("pos " & To_Ada(A) & " " & S (P.X) & S (P.Y) & S (P.Z));
         Log ("rot " & To_Ada(A) & " " & S (R.A) & S (R.B) & S (R.C));
         end;
      end loop;
   end Input;


   procedure Input (Obj : Coordinate_Vector) is
      use Interfaces.C;
   begin
      for I in Coord_Vec.First_Index (Obj.V) ..
                Coord_Vec.Last_Index (Obj.V) loop
         declare
            CR : constant Coord_Record := Coord_Vec.Element (Obj.V, I);
         begin
            Log ("pos " & To_Ada(CR.Assembly) & " " & S (CR.Pos.X) & S (CR.Pos.Y) & S (CR.Pos.Z));
            Log ("rot " & To_Ada(CR.Assembly) & " " & S (CR.Rot.A) & S (CR.Rot.B) & S (CR.Rot.C));
         end;
      end loop;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Scale) is
   begin
      null;
   end Input;

   -----------
   -- Input --
   -----------

   procedure Input (Obj : Spin) is
   begin
      null;
   end Input;

   -----------------
   -- Plant_Is_On --
   -----------------

   function Is_On return Boolean is
   begin
      return False;
   end Is_On;

   ---------
   -- Put --
   ---------

   procedure Playback_Put (Msg : Dvs_Record) is
   begin
      null;
   end Playback_Put;

   procedure Put (Data : Dvs_Record;
                  Instantaneous_Event : Boolean := False;
                  Collision : Boolean := False;
                  Collision_Description : Collision_Description_String.Bounded_String :=
                    Collision_Description_String.To_Bounded_String ("")) is
   begin
      null;
   end Put;

   procedure Inout (Obj : in out Query_Terrain_Elevation) is
   begin
      Obj.Active := False;
   end Inout;

   procedure Inout (Obj : in out Query_Coordinate) is
   begin
      Obj.Active := False;
   end Inout;

   procedure Input (Obj : in Init_Object) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Init_Effect) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Switch) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Impact) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Launch) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Rot_Order) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Start_Plot) is
   begin
      null;
   end Input;

   procedure Input (Obj : in Set_Stop_Plot) is
   begin
      null;
   end Input;

   function "<" (L, R : Dvs_Stored_Record) return Boolean is
   begin
      -- this is a dummy method... but might as well implement it
      -- correctly instead of always return true or false
      if L.Timestamp < R.Timestamp then
         return True;
      else
         return False;
      end if;
   end "<";

   -- Used by Dead Reckoning
   procedure Render (Part       : in Dvs_Record;
                     X, Y, Z    : in Float;    -- Position
                     W, A, B, C : in Float) is
   begin
      null;
   end;

   use Pace.Server.Dispatch;
   type Put_Coord_Vector is new Action with null record;
   procedure Inout (Obj : in out Put_Coord_Vector);
   procedure Inout (Obj : in out Put_Coord_Vector) is
   begin
      Pace.Log.Put_Line ("Received Put_Coord_Vector action request with xml: " & (U2s (Obj.Set)));
   end Inout;

   procedure Input(Obj : in Set_Player) is
   begin
      null;
   end Input;

end Proxy;
