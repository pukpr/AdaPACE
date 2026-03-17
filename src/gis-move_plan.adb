with Pace;
with Pace.Log;
with Ada.Strings.Unbounded;
with Ada.Characters.Handling;

package body Gis.Move_Plan is

   package Asu renames Ada.Strings.Unbounded;

   use Str;
   use Checkpoint_Vector;

   -- note ... date is not fully implemented

   procedure Add_Move_Plan (Id : Bstr.Bounded_String;
                            Data : Move_Plan_Data) is
      use Ada.Characters.Handling;
      function Get_Points_Prolog (Points : Vector) return String is
         use Asu;
         use Kb.Rules;
         Result : Unbounded_String := Null_Unbounded_String;
      begin
         for I in First_Index (Points) .. Last_Index (Points) loop
            if I /= 1 then
               Append (Result, ", ");
            end if;
            Append (Result, F ("point", "n=" & Q (S (I)) & "," &
                               F ("type", To_Lower (Element (Points, I).Kind'Img)) & "," &
                               F ("east", S (Element (Points, I).Coord.Easting)) & "," &
                               F ("north", S (Element (Points, I).Coord.Northing)) & "," &
                               F ("zone_num", S (Element (Points, I).Coord.Zone_Num)) & "," &
                               F ("hemisphere", Q (Element (Points, I).Coord.Hemisphere'Img)) & "," &
                               F ("time", S (Float (Element (Points, I).Time))) & "," &
                               F ("date", "")));
         end loop;
         return To_String (Result);
      end Get_Points_Prolog;

      use Kb.Rules;
      Msg : Kb.Query;
   begin
      Msg.Set := S2u (F ("assert",
                        F ("mp", F ("id", Q (B2s (Id))) & ", " &
                           F ("data", F("plan", Q ( B2s(Data.Plan))) & ", " &
                              F ("start_time", S (Float (Data.Start_Time))) & ", " &
                              F ("no_later_than", To_Lower (Data.No_Later_Than'Img)) & ", " &
                              F ("max_corridor", S (Data.Max_Corridor)) & ", " &
                              F ("num_points", S (Integer (Length (Data.Points)))) & ", " &
                              F ("point_list", Get_Points_Prolog (Data.Points))
                              ))));
      Pace.Dispatching.Inout (Msg);
   end Add_Move_Plan;

   procedure Remove_Move_Plan (Id : Bstr.Bounded_String) is
      use Kb.Rules;
      Msg : Kb.Query;
   begin
      Msg.Set := S2u (F ("retract",
                        F ("mp", F ("id", Q (B2s (Id))) & ", _")));
      Pace.Dispatching.Inout (Msg);
   end Remove_Move_Plan;

   procedure Get_Move_Plan (Id : in Bstr.Bounded_String;
                            Found_It : out Boolean;
                            Data : out Move_Plan_Data) is
      use Kb.Rules;
      use Bstr;
      Num_Points : Integer;
      -- id to query with.. has quotes around it
      Query_Id : Bstr.Bounded_String;
   begin
      -- logic to handle Id coming in with quotes or not with quotes
      if Bstr.Element (Id, 1) = '"'  -- " (Quote Comment is for Xemacs Visualizing)
        or Bstr.Element (Id, 1) = ''' then -- '
         -- has quotes already so..
         Query_Id := Id;
         Data.Id := Bstr.Delete (Id, 1, 1);
         Data.Id := Bstr.Delete (Data.Id, Length (Data.Id), Length (Data.Id));
      else
         -- doesn't have quotes so...
         Data.Id := Id;
         Append (Query_Id, '"'); -- "
         Append (Query_Id, Id);
         Append (Query_Id, '"'); -- "
      end if;

      declare
         V : Variables (1 .. 6);
      begin
         V (1) := B2u (Query_Id);
         Kb.Agent.Query ("get_mp", V);
         Data.Plan := U2b (V (2));
         Data.Start_Time := Duration'Value (Asu.To_String (V (3)));
         Data.No_Later_Than := Boolean'Value (Asu.To_String (V (4)));
         Data.Max_Corridor := Integer'Value (Asu.To_String (V (5)));
         Num_Points := Integer'Value (Asu.To_String (V (6)));
      end;
      for I in 1 .. Num_Points loop
         declare
            V : Variables (1 .. 13);
            Cpoint : Checkpoint;
         begin
            V (1) := B2u (Query_Id);
            V (2) := S2u (I'Img);
            Kb.Agent.Query ("get_cp", V);
            Cpoint.Kind := Checkpoint_Type'Value (U2s (V (3)));
            Cpoint.Coord.Easting := Float'Value (U2s (V (4)));
            Cpoint.Coord.Northing := Float'Value (U2s (V (5)));
            Cpoint.Coord.Zone_Num := Integer'Value (U2s (V (6)));
            Cpoint.Coord.Hemisphere := Hemisphere_Type'Value (U2s (V (7)));
            Cpoint.Time := Duration'Value (U2s (V (8)));
            Append (Data.Points, Cpoint);
            -- ignore date for now
         end;
      end loop;

      Found_It := True;
   exception
      when E : Kb.Rules.No_Match =>
         Found_It := False;
   end Get_Move_Plan;

end Gis.Move_Plan;

