with Pace.Log;
with Ada.Text_IO;

package body Max_Finder is

   protected body Max_Store is
      procedure Update (New_Value : Float; From_Node : Integer; Success : out Boolean) is
      begin
         if New_Value > Current_Max then
            Current_Max := New_Value;
            Success := True;
         else
            Success := False;
         end if;
      end Update;

      function Get_Max return Float is
      begin
         return Current_Max;
      end Get_Max;
   end Max_Store;

   procedure Input (Obj : in Found_Value) is
      New_Max_Found : Boolean;
   begin
      Max_Store.Update (Obj.Value, Obj.Origin, New_Max_Found);
      if New_Max_Found then
         Pace.Log.Put_Line ("Server: NEW MAX found! Value =" & 
                            Float'Image(Obj.Value) & 
                            " from Node" & Integer'Image(Obj.Origin));
      end if;
   end Input;

end Max_Finder;
