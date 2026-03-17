with Ada.Characters.Handling;
with Ada.Strings.Unbounded;
with Pace.Strings;
with Pace.Xml_Tree.Kbase;
with Pace.Server.Html;
with Pace.Server.Xml;

package body Pace.Server.Kbase_Utilities is

   use Pace.Strings;

   package Asu renames Ada.Strings.Unbounded;

   -- removes double quotes
   function Strip_Quotes (Str : in String) return String is
      use Ada.Strings.Unbounded;
      Result : Unbounded_String := To_Unbounded_String (Str);
      Double_Quote : String := "" & '"';
      I : Natural := Index (result, Double_Quote);
   begin
      while I /= 0 loop
         Result := Delete (Result, I, I);
         I := Index (Result, Double_Quote);
      end loop;
      return To_String (Result);
   end Strip_Quotes;

   function Kbase_To_Xml (Agent : in Pace.Rule_Process.Agent_Type;
                          Query : in Ada.Strings.Unbounded.Unbounded_String;
                          Is_Xml_Tree : Boolean;
                          Remove_Quotes : Boolean := false) return String is

      S : Asu.Unbounded_String := Asu.Null_Unbounded_String;

      procedure Xml_Display (Key, Val : in String) is
         use Asu;
      begin
         if Is_Xml_Tree then
            S := S & Val & " ";
         else
            S := S & Pace.Server.Xml.Item
                       (Element => Ada.Characters.Handling.To_Lower (Key),
                        Value => Val);
         end if;
      end Xml_Display;

--       procedure Xml_Tree_Display (Text : in String) is
--          use Asu;
--       begin
--          S := S & Text;
--       end Xml_Tree_Display;

      Root : Pace.Xml_Tree.Kbase.Tree;

   begin
      Agent.Query (Asu.To_String (Query), Xml_Display'Unrestricted_Access);

      if Is_Xml_Tree then
         Pace.Xml_Tree.Kbase.Parse (Asu.To_String (S), Root);
         -- S := Asu.Null_Unbounded_String;
         Pace.Xml_Tree.Kbase.Print (Root, 0,
                                    Pace.Xml_Tree.Null_Print'Access);
                                    -- Xml_Tree_Display'Unrestricted_Access);
         S := Asu.To_Unbounded_String(Pace.Xml_Tree.Kbase.Get_Tree (Root));
      end if;
      if Remove_Quotes then
         return Strip_Quotes (Asu.To_String (S));
      else
         return Asu.To_String (S);
      end if;
   end Kbase_To_Xml;

   function Ignore (Subtext : in String) return String is
   begin
      Pace.Display ("DIRECTIVE:" & Subtext);
      return "";
   end Ignore;
   function Directives is new Pace.Server.Html.Template ("<?", "?>", Ignore);

   procedure Xml_To_Kbase (Agent : in Pace.Rule_Process.Agent_Type;
                           Xml : in Ada.Strings.Unbounded.Unbounded_String;
                           Functor : String := "") is
      use Pace.Xml_Tree.Kbase;
      Root : Kb_Fact;
   begin
      Parse (Directives (Asu.To_String (Xml)), Root);
      Search (Root);
      Pace.Display ("ASSERTING:" & Get_Fact (Root));
      if Functor = "" then
         Agent.Parse ("asserta(" & Get_Fact (Root) & ")");
      else
         Agent.Parse ("asserta(" & Functor & "(" & Get_Fact (Root) & "))");
      end if;
   end Xml_To_Kbase;

   procedure Query_Kbase
               (Agent : in Pace.Rule_Process.Agent_Type;
                Query : in out Ada.Strings.Unbounded.Unbounded_String) is

      S : Asu.Unbounded_String := Asu.Null_Unbounded_String;

      procedure Display (Str : in String) is
         use Asu;
      begin
         S := S & Str;
      end Display;

   begin
      if Pace.Server.Key_Exists ("xml_list") then
         S := Asu.To_Unbounded_String (Kbase_To_Xml (Agent, Query, False));

         if Pace.Server.Value ("xml_list") = "template" then
            Query := S;
         else
            Pace.Server.Xml.Put_Content
              (Default_Stylesheet => Pace.Server.Keys.Value ("style", ""));
            Pace.Server.Put_Data (Pace.Server.Xml.Begin_Doc);
            Pace.Server.Put_Data (Asu.To_String (S));
            Pace.Server.Put_Data (Pace.Server.Xml.End_Doc);
         end if;
      elsif Pace.Server.Key_Exists ("xml_tree") then
         S := Asu.To_Unbounded_String (Kbase_To_Xml (Agent, Query, True));
         if Pace.Server.Value ("xml_tree") = "template" then
            Query := S;
         else
            Pace.Server.Xml.Put_Content
              (Default_Stylesheet => Pace.Server.Keys.Value ("style", ""));
            Pace.Server.Put_Data (Asu.To_String (S));
         end if;
      else
         Pace.Server.Put_Content (Content => "text/plain");
         Pace.Server.Put_Data ("** QUERY");
         Agent.Query (Asu.To_String (Query), Display'Unrestricted_Access);
         Pace.Server.Put_Data (Asu.To_String (S));
         Pace.Server.Put_Data ("** FINISHED");
      end if;
      S := Asu.Null_Unbounded_String;

   end Query_Kbase;




   function Get_List (Text : in String; Delimiter : Character := ' ')
                     return Pace.Rule_Process.Variables is

      Sep : Character;

      function Keep_Space return String is
         Nt : String := Text;
         Quoted : Boolean := False;
         Index : Integer := 0;
      begin
         for I in Text'Range loop
            if Text (I) = '"' then
               Quoted := not Quoted;
            else
               Index := Index + 1;
               if not Quoted and then Text (I) = ' ' then
                  Nt (Index) := Sep;
               else
                  Nt (Index) := Text (I);
               end if;
            end if;
         end loop;
         return Nt (1 .. Index);
      end Keep_Space;

      Str : Asu.Unbounded_String;
      use Pace.Rule_Process;
   begin
      if Delimiter = ' ' then
         Sep := Ascii.Lf;
         Str := S2u (Keep_Space);
      else
         Sep := Delimiter;
         Str := S2u (Text);
      end if;

      declare
         Length : constant Integer := Pace.Strings.Count_Fields (U2s (Str), Sep);
         V : Pace.Rule_Process.Variables (1 .. Length);
      begin
         for I in V'Range loop
            V (I) := S2u (Pace.Strings.Select_Field (U2s (Str), I, Sep));
         end loop;
         return V;
      end;
   end Get_List;


   function List_To_Xml (Text : in String;
                         Delimiter : in Character := ' ';
                         Xml_Tag : in String) return String is
      use Asu;
      use Pace.Rule_Process;
      V : Variables := Get_List (Text, Delimiter);
      Xml_Str : Unbounded_String;
   begin
      for I in V'Range loop
         Append (Xml_Str, Pace.Server.Xml.Item (Xml_Tag, +V (I)));
      end loop;
      return +Xml_Str;
   end List_To_Xml;


   function Lists_To_Xml (Lists : in List_Key_Array;
                          Delimiter : in Character := ' ';
                          Xml_Tag : in String) return String is
      use Asu;
      use Pace.Rule_Process;
      -- in order to know the length of each of the Variables lists,
      -- must do first call to Get_List immediately
      V1 : Variables := Get_List ((+Lists (1).Text), Delimiter);
      Vars : array (Lists'Range) of Variables (V1'Range);
      Xml_Str : Unbounded_String;
   begin
      -- parse the text for each one
      Vars (1) := V1;
      for I in 2 .. Vars'Last loop
         Vars (I) := Get_List ((+Lists (I).Text), Delimiter);
      end loop;

      -- create the xml
      for J in Vars (1)'Range loop
         declare
            Temp_Xml : Asu.Unbounded_String;
         begin
            for I in Vars'Range loop  -- looping through each Variables
               Append (Temp_Xml, Pace.Server.Xml.Item
                                   ((+Lists (I).Xml_Tag), +(Vars (I) (J))));
            end loop;
            Append (Xml_Str, Pace.Server.Xml.Item (Xml_Tag, +Temp_Xml));
         end;
      end loop;
      return +Xml_Str;
   end Lists_To_Xml;



end Pace.Server.Kbase_Utilities;
