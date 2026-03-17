with Pace.Hash_Table;
-- with Pace.Log;

package body Gis.Dead_Reckoning is

   procedure Update
     (Obj        : in out State;
      X, Y, Z    : in Float;
      W, A, B, C : in Float;
      Time       : in Duration := Pace.Now)
   is
   begin
      Update (Obj.X, X, Time);
      Update (Obj.Y, Y, Time);
      Update (Obj.Z, Z, Time);
      Update (Obj.A, A, Time);
      Update (Obj.B, B, Time);
      Update (Obj.C, C, Time);
      Update (Obj.W, W, Time);
      Update (Obj.DX, Derivative (Obj.X), Time);
      Update (Obj.DY, Derivative (Obj.Y), Time);
      Update (Obj.DZ, Derivative (Obj.Z), Time);
      Update (Obj.DA, Derivative (Obj.A), Time);
      Update (Obj.DB, Derivative (Obj.B), Time);
      Update (Obj.DC, Derivative (Obj.C), Time);
      Update (Obj.DW, Derivative (Obj.W), Time);
   end Update;

   function Current (Obj : State) return WRT_Time is
   begin
      return
        (+Obj.DX,
         +Obj.DY,
         +Obj.DZ,
         +Obj.DW,
         +Obj.DA,
         +Obj.DB,
         +Obj.DC,
         Derivative (Obj.DX),
         Derivative (Obj.DY),
         Derivative (Obj.DZ),
         Derivative (Obj.DW),
         Derivative (Obj.DA),
         Derivative (Obj.DB),
         Derivative (Obj.DC));
   end Current;

   function Delta_T (Obj : State; Back : History := 1) return Duration is
   begin
      return Delta_T (Obj.X, Back);
   end Delta_T;

   function X (Obj : State) return Float is
   begin
      return +Obj.X;
   end;
   function Y (Obj : State) return Float is
   begin
      return +Obj.Y;
   end;
   function Z (Obj : State) return Float is
   begin
      return +Obj.Z;
   end;
   function W (Obj : State) return Float is
   begin
      return +Obj.W;
   end;
   function A (Obj : State) return Float is
   begin
      return +Obj.A;
   end;
   function B (Obj : State) return Float is
   begin
      return +Obj.B;
   end;
   function C (Obj : State) return Float is
   begin
      return +Obj.C;
   end;

   function Dead_Reckon_X  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.X);
   end;
   
   function Dead_Reckon_Y  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.Y);
   end;
   
   function Dead_Reckon_Z  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.Z);
   end;
   
   function Dead_Reckon_W  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.W);
   end;
   
   function Dead_Reckon_A  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.A);
   end;
   
   function Dead_Reckon_B  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.B);
   end;
   
   function Dead_Reckon_C  (Obj : in State;
                            Time : in Duration := Pace.Now) return Float is
   begin
      return Predict (Obj.C);
   end;


   package body Dead_Reckoner is

      type DR_State_Type is
         record
             Value : Assembly;
             Name : Assembly_Name;
             State : Dead_Reckoning.State;
             Enable : Boolean := False; -- Can synchronize a value
             Start : Boolean := False;  -- Start updating values
             Fresh : Boolean := False;  -- Can update a value according to Dead Reckoning
         end record;
      type DR_State is access DR_State_Type;

      Empty : constant DR_State := null;

      function Same (L, R : Assembly_Name) return Boolean is
      begin
         return To_String(L) = To_String(R);
      end;

      function Hash (Key : Assembly_Name) return Pace.Hash_Table.Hash_Type is
      begin
         return Pace.Hash_Table.Hash (To_String (Key));
      end Hash;

      package Data is new Pace.Hash_Table.Simple_Htable 
         (Element => DR_State,
          No_Element => Empty,
          Key => Assembly_Name,
          Hash => Hash,
          Equal => Same);

      procedure Synchronize ( Part       : in Assembly;
                              Part_Name  : in Assembly_Name;
                              X, Y, Z    : in Float;
                              W, A, B, C : in Float) is
         DR : DR_State := Data.Get (Part_Name);
      begin
         if DR /= null and then DR.Enable then
            --Pace.Log.Put_Line ("Synch DR :" & To_String (DR.Name));
            DR.Value := Part;
            DR.Name := Part_Name;
            Gis.Dead_Reckoning.Update (DR.State, 
                                       X, Y, Z,
                                       0.0, -- Ignore Quaternion W value, assume Euler deltas
                                       A, B, C);
            DR.Fresh := True;
            DR.Start := True;
            Data.Set (Part_Name, DR);
         end if;
      end Synchronize;

      procedure Update is
         DR : DR_State;
      begin
         Data.Iterator.Reset;
         loop
            DR := Data.Iterator.Next;
            if DR /= null and then DR.Start then
               if DR.Fresh then
                  DR.Fresh := False;
                  Data.Set (DR.Name, DR);
               else
                  -- pragma Debug (Pace.Log.Put_Line ("Update DR :" & To_String (DR.Name) & Pace.Now'Img));
                  Render (DR.Value, Dead_Reckon_X (DR.State),
                                    Dead_Reckon_Y (DR.State),
                                    Dead_Reckon_Z (DR.State),
                                    0.0,
                                    Dead_Reckon_A (DR.State),
                                    Dead_Reckon_B (DR.State),
                                    Dead_Reckon_C (DR.State));
               end if;
            end if;
            exit when Data.Iterator.Done;
         end loop;
      end Update;

      procedure Set (Part_Name : in Assembly_Name) is
         DR : DR_State := new DR_State_Type;
      begin
         DR.Name := Part_Name;
         --DR.Value := Default; -- 
         DR.Enable := True;
         Data.Set (Part_Name, DR);
         -- Pace.Log.Put_Line ("Set DR :" & To_String (DR.Name));
      end Set;

   end Dead_Reckoner;

   -- $Id: gis-dead_reckoning.adb,v 1.5 2005/06/21 17:45:08 pukitepa Exp $
end Gis.Dead_Reckoning;
