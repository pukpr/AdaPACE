with Text_Io;
with Unchecked_Deallocation;
with Ada.Containers.Indefinite_Vectors;

package body Pace.Xml_Tree is
   -- use Text_Io;

   procedure Free is new Unchecked_Deallocation (Node, Node_Ptr);

   Count : Integer;

   procedure Clean_Strings (N : in out Node) is
   begin
      Count := Count + 1;
      N.Tag := Null_Unbounded_String;
      N.Attributes := Null_Unbounded_String;
      N.Value := Null_Unbounded_String;
   end Clean_Strings;

   procedure Clean (N : in out Node_Ptr) is
      P, C : Node_Ptr;
   begin
      if N.Child /= null then
         P := N.Child.Next;
         Clean (N.Child);
         while P /= null loop
            C := P.Next;
            Clean (P);
            P := C;
         end loop;
      end if;
      Clean_Strings (N.all);
      Free (N);
   end Clean;

   procedure Finalize (Root : in out Tree) is
   begin
      if Root.N = null then
         return;
      end if;
      Count := 0;
      pragma Debug (Text_Io.Put_Line ("XML: Tree Cleanup"));
      Clean (Root.N);
      pragma Debug (Text_Io.Put ("XML: Elements Cleaned ="));
      pragma Debug (Text_Io.Put_Line (Integer'Image (Count)));
   end Finalize;


   function Get_Node (Buf : String; Index : access Natural) return Node_Ptr;
   --  The main parse routine. Starting at Index.all, Index.all is updated
   --  on return. Return the node starting at Buf (Index.all) which will
   --  also contain all the children and subchildren.


   procedure Extract_Attrib (Tag : in out Unbounded_String;
                             Attributes : out Unbounded_String;
                             Empty_Node : out Boolean);
   --  Extract the attributes as a string, if the tag contains blanks ' '
   --  On return, Tag is unchanged and Attributes contains the string
   --  If the last character in Tag is '/' then the node is empty and
   --  Empty_Node is set to True

   procedure Get_Next_Word (Buf : String;
                            Index : in out Natural;
                            Word : out Unbounded_String);
   --  extract the next textual word from Buf and return it.
   --  return null if no word left

   -----------------
   -- Skip_Blanks --
   -----------------

   procedure Skip_Blanks (Buf : String; Index : in out Natural) is
   begin
      while Index < Buf'Last and then
              (Buf (Index) = ' ' or else Buf (Index) = Ascii.Lf or else
               Buf (Index) = Ascii.Ht or else Buf (Index) = Ascii.Cr) loop
         Index := Index + 1;
      end loop;
   end Skip_Blanks;

   -------------
   -- Get_Buf --
   -------------

   procedure Get_Buf (Buf : String;
                      Index : in out Natural;
                      Terminator : Character;
                      S : out Unbounded_String) is
      Start : Natural := Index;

   begin
      while Buf (Index) /= Terminator loop
         Index := Index + 1;
      end loop;

      S := To_Unbounded_String (Buf (Start .. Index - 1));
      Index := Index + 1;

      if Index < Buf'Last then
         Skip_Blanks (Buf, Index);
      end if;
   end Get_Buf;

   ------------------------
   -- Extract_Attributes --
   ------------------------

   procedure Extract_Attrib (Tag : in out Unbounded_String;
                             Attributes : out Unbounded_String;
                             Empty_Node : out Boolean) is
      Index_Last_Of_Tag : Natural;
      T : constant String := To_String (Tag);
      Index : Natural := T'First;
   begin
      --  First decide if the node is empty

      if T (T'Last) = '/' then
         Empty_Node := True;
      else
         Empty_Node := False;
      end if;

      while Index <= T'Last and then
              not (T (Index) = ' ' or else T (Index) = Ascii.Lf or else
                   T (Index) = Ascii.Ht or else T (Index) = Ascii.Cr) loop
         Index := Index + 1;
      end loop;

      Index_Last_Of_Tag := Index - 1;
      Skip_Blanks (T, Index);

      if Index <= T'Last then
         if Empty_Node then
            Attributes := To_Unbounded_String (T (Index .. T'Last - 1));
         else
            Attributes := To_Unbounded_String (T (Index .. T'Last));
         end if;

         Tag := To_Unbounded_String (T (T'First .. Index_Last_Of_Tag));
      end if;
   end Extract_Attrib;

   --------------------
   --  Get_Next_Word --
   --------------------

   procedure Get_Next_Word (Buf : String;
                            Index : in out Natural;
                            Word : out Unbounded_String) is
      Terminator : Character := ' ';
   begin
      Skip_Blanks (Buf, Index);

      if Buf (Index) = ''' or Buf (Index) = '"' then
         --  If the word starts with a quotation mark, then read until
         --  the closing mark

         Terminator := Buf (Index);
         Index := Index + 1;
         Get_Buf (Buf, Index, Terminator, Word);

      else
         --  For a normal word, scan up to either a blank, or a '='

         declare
            Start_Index : constant Natural := Index;
         begin
            while Buf (Index) /= ' ' and Buf (Index) /= '=' loop
               Index := Index + 1;
            end loop;

            Word := To_Unbounded_String (Buf (Start_Index .. Index - 1));
         end;
      end if;

      if Index < Buf'Last then
         Skip_Blanks (Buf, Index);
      end if;
   end Get_Next_Word;

   --------------
   -- Get_Node --
   --------------

   function Get_Node (Buf : String; Index : access Natural) return Node_Ptr is
      N : Node_Ptr := new Node;
      Q : Node_Ptr;
      S : Unbounded_String;
      Index_Save : Natural;
      Empty_Node : Boolean;
      Last_Child : Node_Ptr;

   begin
      pragma Assert (Buf (Index.all) = '<');
      Index.all := Index.all + 1;
      Index_Save := Index.all;
      Get_Buf (Buf, Index.all, '>', N.Tag);

      --  Here we have to deal with the attributes of the form
      --  <tag attrib='xyyzy'>

      Extract_Attrib (N.Tag, N.Attributes, Empty_Node);

      --  it is possible to have a child-less node that has the form
      --  <tag /> or <tag attrib='xyyzy'/>

      if Empty_Node then
         N.Value := To_Unbounded_String ("");
      else
         if Buf (Index.all) = '<' then
            if Buf (Index.all + 1) = '/' then

               --  No value contained on this node

               N.Value := To_Unbounded_String ("");
               Index.all := Index.all + 1;

            else

               --  Parse the children

               N.Child := Get_Node (Buf, Index);
               N.Child.Parent := N;
               Last_Child := N.Child;
               pragma Assert (Buf (Index.all) = '<');

               while Buf (Index.all + 1) /= '/' loop
                  Q := Last_Child;
                  Q.Next := Get_Node (Buf, Index);
                  Q.Next.Parent := N;
                  Last_Child := Q.Next;
                  pragma Assert (Buf (Index.all) = '<');
               end loop;

               Index.all := Index.all + 1;
            end if;

         else

            --  Get the value of this node

            Get_Buf (Buf, Index.all, '<', N.Value);
         end if;

         pragma Assert (Buf (Index.all) = '/');
         Index.all := Index.all + 1;
         Get_Buf (Buf, Index.all, '>', S);
         pragma Assert (To_String (N.Tag) = To_String (S));
      end if;

      return N;
   end Get_Node;

   procedure Null_Print (Text : in String) is
   begin
      null;
   end;

   -----------
   -- Print --
   -----------

   procedure Print (Root : in out Tree;
                    Indent : in Natural := 0;
                    Display : in Print_Callback := null) is

      procedure Print (N : in Node_Ptr;
                       Indent : in Natural := 0) is
         P : Node_Ptr;

         procedure Put (Text : in String) is
         begin
            if Display = null then
               Text_Io.Put (Text);
            else
               Display (Text);
               Ada.Strings.Unbounded.Append(Root.S, Text);
            end if;
         end Put;

         procedure Put_Line (Text : in String) is
         begin
            if Display = null then
               Text_Io.Put_Line (Text);
            else
               Display (Text);
               Ada.Strings.Unbounded.Append(Root.S, Text);
            end if;
         end Put_Line;

         procedure Do_Indent (Indent : Natural);

         procedure Do_Indent (Indent : Natural) is
         begin
            if Display /= null then
               return;
            end if;
            for J in 1 .. Indent loop
               Put (" ");
            end loop;
         end Do_Indent;

      begin
         Do_Indent (Indent);
         Put ("<");
         Put (To_String (N.Tag));

         if To_String (N.Attributes) /= "" then
            Put (" ");
            Put (To_String (N.Attributes));
         end if;

         if N.Child /= null then
            Put_Line (">");
            Print (N.Child, Indent + 2);
            P := N.Child.Next;

            while P /= null loop
               Print (P, Indent + 2);
               P := P.Next;
            end loop;

            Do_Indent (Indent);
            Put ("</");
            Put (To_String (N.Tag));
            Put_Line (">");

         else
            if To_String (N.Value) = "" then
               Put_Line ("/>");
            else
               Put (">");
               Put (To_String (N.Value));
               Put ("</");
               Put (To_String (N.Tag));
               Put_Line (">");
            end if;
         end if;
      end Print;

   begin
      Root.S := Null_Unbounded_String;
      Print (Root.N, Indent);
   end Print;

   ------------
   -- Search --
   ------------

   procedure Search (Root : in out Tree'Class; N : in Node_Ptr) is
      P : Node_Ptr;
   begin
      Callback (Root, To_String (N.Tag), To_String (N.Value),
                To_String (N.Attributes));
      if N.Child /= null then
         Search (Root, N.Child);
         P := N.Child.Next;

         while P /= null loop
            Search (Root, P);
            P := P.Next;
         end loop;
      end if;
      Callback (Root, "", "", ""); -- end node
   end Search;

   procedure Search (Root : in out Tree) is
   begin
      Search (Root, Root.N);
      Callback (Root, "", "", ""); -- end node
   end Search;

   -----------
   -- Parse --
   -----------

   procedure Parse (Text : String; Root : out Tree) is
      Index : aliased Natural := Text'First;
   begin
      Root.N := Get_Node (Text, Index'Unchecked_Access);
   end Parse;

   --------------
   -- Find_Tag --
   --------------

   function Find_Tag (N : Node_Ptr; Tag : String) return Node_Ptr is
      P : Node_Ptr := N;

   begin
      while P /= null loop
         pragma Debug (Text_Io.Put_Line (To_String (P.Tag)));
         if To_String (P.Tag) = Tag then
            return P;
         end if;
         -- Go through children as well
         if P.Child = null then
            null;
         else
            declare
               Next : Node_Ptr := Find_Tag (P.Child, Tag);
            begin
               if Next /= null then
                  return Next;
               end if;
            end;
         end if;
         P := P.Next;
      end loop;
      return null;
   end Find_Tag;

   ---------------
   -- Get_Field --
   ---------------

   function Get_Field (Root : Tree; Name : String; Default : String := "")
                      return Unbounded_String is
      P : Node_Ptr := Find_Tag (Root.N, Name);
   begin
      if P /= null then
         return P.Value;
      else
         return To_Unbounded_String (Default);
      end if;
   end Get_Field;

   function Get_Field (Root : Tree; Name : String; Default : String := "")
                      return String is
      S : Unbounded_String := Get_Field (Root, Name, Default);
   begin
      return To_String (S);
   end Get_Field;

   -------------------
   -- Get_Attribute --
   -------------------

   function Get_Attribute (Root : Tree;
                           Name : String;
                           Attribute_Name : String;
                           Default : String := "") return Unbounded_String is
      P : Node_Ptr := Find_Tag (Root.N, Name);
      Key, Value : Unbounded_String;
      Return_Default : Boolean := True;
   begin
      if P /= null then
         declare
            Attr : constant String := To_String (P.Attributes);
            Index : Natural := Attr'First;
         begin
            while Index < Attr'Last loop
               Get_Next_Word (Attr, Index, Key);
               Get_Buf (Attr, Index, '=', Value);
               Get_Next_Word (Attr, Index, Value);

               if Attribute_Name = To_String (Key) then
                  Return_Default := False;
                  exit;
               end if;
            end loop;
         end;
      end if;
      if Return_Default then
         return To_Unbounded_String (Default);
      else
         return Value;
      end if;
   end Get_Attribute;

   function Get_Attribute (Root : Tree;
                           Name : String;
                           Attribute_Name : String;
                           Default : String := "") return String is
      S : Unbounded_String := Get_Attribute
                                (Root, Name, Attribute_Name, Default);
   begin
      return To_String (S);
   end Get_Attribute;

   procedure Callback (Root : in out Tree;
                       Tag, Value, Attributes : in String) is
      use Text_Io;
   begin
      if Tag /= "" then
         Put ("XML| ");
         Put (Tag);
         Put (" = ");
         Put (Value);
         Put (" [");
         Put (Attributes);
         Put_Line ("]");
      end if;
   end Callback;

   -----------------------
   -- XML search utility
   -----------------------

   type Xml_Tree is new Tree with
      record
         Key : Unbounded_String;
         Val : Unbounded_String;
      end record;
   procedure Callback (T : in out Xml_Tree; Tag, Value, Attributes : in String);


   procedure Callback (T : in out Xml_Tree;
                       Tag, Value, Attributes : in String) is
   begin
      if Tag = To_String (T.Key) and then T.Val = Null_Unbounded_String then
         T.Val := To_Unbounded_String (Value);
      end if;
   end Callback;

   function Search_Xml
              (Tree : in String; Key : in String; Default : in String := "")
              return String is
      Root : Xml_Tree;
   begin
      if Tree = "" then
         return Default;
      end if;
      Root.Key := To_Unbounded_String (Key);
      Root.Val := Null_Unbounded_String;
      Parse (Tree, Root);
      Search (Root);
      if Root.Val = Null_Unbounded_String then
         return Default;
      else
         return To_String (Root.Val);
      end if;
   end Search_Xml;


   ----------------------------------
   --  Multiple return Vector version
   ----------------------------------

   package UVector is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => Unbounded_String,
      "=" => "=");

   type Xml_Tree_Vector is new Tree with
      record
         Key : Unbounded_String;
         Vec : UVector.Vector;
      end record;
   procedure Callback (T : in out Xml_Tree_Vector; Tag, Value, Attributes : in String);


   procedure Callback (T : in out Xml_Tree_Vector;
                       Tag, Value, Attributes : in String) is
   begin
      if Tag = To_String (T.Key) then
         UVector.Append (T.Vec, To_Unbounded_String (Value));
      end if;
   end Callback;

   function Search_Xml
              (Tree : in String; Key : in String)
              return Strings is
      Root : Xml_Tree_Vector;
      Null_Strs : Strings (1..0);
   begin
      if Tree = "" then
         return Null_Strs;
      end if;
      Root.Key := To_Unbounded_String (Key);
      Parse (Tree, Root);
      Search (Root);
      declare
         Strs : Strings (1..UVector.Last_Index (Root.Vec));
      begin
         for I in 1..UVector.Last_Index (Root.Vec) loop
            Strs (I) := UVector.Element (Root.Vec, I);
         end loop;
         return Strs;
      end;
   end Search_Xml;

   function Get_Tree (Root : Tree) return String is
   begin
      return To_String (Root.S);
   end;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
end Pace.Xml_Tree;
