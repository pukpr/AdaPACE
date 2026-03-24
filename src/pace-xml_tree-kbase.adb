with Text_Io;
with Ada.Strings.Unbounded;

package body Pace.Xml_Tree.Kbase is
   use Ada.Strings.Unbounded;

   ------------------------
   -- Extract_Attributes --
   ------------------------

   procedure Extract_Attrib (Str : in String;
                             Index : access Natural;
                             Attributes : out Unbounded_String) is
      --  Extract the attributes as a string, if the tag contains blanks ' '
      --  On return, Tag is unchanged and Attributes contains the string
      Start, Middle, Last : Natural;
      Attr, Sep : Boolean := False;
      function Quote_Atom (Atom : String) return String is
      begin
         if Atom (Atom'First) = '"' then  -- "
            return Atom;
         else
            return '"' & Atom & '"';
         end if;
      end Quote_Atom;
   begin
      -- (= attr value) (= attr value) (= attr value)
      Attributes := Null_Unbounded_String;
      if Str'Length > 2 and then Str (Str'First + 2) /= '=' then
         return;
      end if;
      for I in Str'First + 3 .. Str'Last loop
         if Str (I - 3 .. I - 2) = "( " then
            if Str (I - 1 .. I) = "= " then
               Attr := True;
               Sep := False;
               Start := I + 1;
            else
               Index.all := I - 3;
               exit;
            end if;
         elsif Attr then
            if not Sep and Str (I) = ' ' then
               Sep := True;
               Middle := I;
            elsif Str (I) = ')' then
               Last := I - 1;
               Attr := False;
               -- if str Value is lower case, enclose in quotes
               Append (Attributes,
                       Str (Start .. Middle - 1) & '=' &
                         Quote_Atom (Str (Middle + 1 .. Last - 1)) & " ");
            end if;
            Index.all := I + 1;
         elsif Str (I) = ')' then
            exit;
         end if;
      end loop;

   end Extract_Attrib;


   --------------
   -- Get_Node --
   --------------

   function Get_Node (Buf : String; Index : access Natural) return Node_Ptr is
      --  The main parse routine. Starting at Index.all, Index.all is updated
      --  on return. Return the node starting at Buf (Index.all) which will
      --  also contain all the children and subchildren.

      N : Node_Ptr;
      Q : Node_Ptr;
      Last_Child : Node_Ptr;
      Start : Natural;
   begin
      pragma Assert (Buf (Index.all) = '('); --'<'--

      Index.all := Index.all + 1;
      Skip_Blanks (Buf (Index.all .. Buf'Last), Index.all);
      Start := Index.all;
      if Buf (Start) = '(' then
         -- this is just a list so keep recursing
         N := Get_Node (Buf, Index);
      else
         -- this is the start of a Tag
         N := new Node;
         while Buf (Index.all) /= ' ' loop
            Index.all := Index.all + 1;
         end loop;
         declare
            Tag : constant String := Buf (Start .. Index.all);
         begin
            if Tag = ". " or Tag = ") " then
               N.Tag := To_Unbounded_String ("LIST");
            else
               N.Tag := To_Unbounded_String (Tag);
            end if;
         end;
         N.Tag := Trim (N.Tag, Ada.Strings.Right);

         --  Here we have to deal with the attributes of the form
         --  (tag (= attrib 'xyyzy') ( .. ) )
         Extract_Attrib (Buf (Index.all + 1 .. Buf'Last), Index, N.Attributes);
         Skip_Blanks (Buf (Index.all .. Buf'Last), Index.all);

         if Buf (Index.all) = '(' then  --'<'--
            --  Parse the children
            N.Child := Get_Node (Buf, Index);
            N.Child.Parent := N;
            Last_Child := N.Child;
            while Index.all <= Buf'Last and then Buf (Index.all) = '(' loop
               Q := Last_Child;
               Q.Next := Get_Node (Buf, Index);
               Q.Next.Parent := N;
               Last_Child := Q.Next;
            end loop;
         end if;
         Get_Buf (Buf, Index.all, ')', N.Value); --'</'--
         N.Value := Trim (N.Value, Ada.Strings.Right);
         pragma Debug (
         Text_Io.Put_Line ("VALUE:" & To_String (N.Tag) &
                                         " [" & To_String (N.Attributes) &
                                         "] " & To_String (N.Value)));
      end if;
      return N;
   exception
      when Constraint_Error =>
         --  Text_Io.Put_Line ("VALUE: [" & Buf (Index.all..Buf'Last) & "]" );
         --  Index.all := Index.all + 2;
         return N;  -- empty node, ignore
   end Get_Node;

   -----------
   -- Parse --
   -----------

   procedure Parse (Text : String; Root : out Tree) is
      Index : aliased Natural := Text'First;
   begin
      if Text (Index) = '(' then
         Root.N := Get_Node (Text, Index'Unchecked_Access);
      else
         Root.N := Get_Node ('(' & Text & "())", Index'Unchecked_Access);
      end if;
   end Parse;



   Comma_Image : constant array (Boolean) of Character :=
     (False => ' ', True => ',');

   procedure Callback (Root : in out Kb_Fact;
                       Tag, Value, Attributes : in String) is
      -- Must lower case tags and attribute names
      -- Keep TagValue in quotes
      -- AttributeValue should already be quoted
      function Attrib return String is
         A : String := Attributes;
         Inside_Quotes : Boolean := False;
      begin
         if Attributes = "" then
            return "";
         else
            -- Look only for spaces not enclosed in quotes
            -- Only the first space in a run of spaces should be
            -- replaced by a comma
            for I in A'Range loop
               if A (I) = '"' then  -- "
                  Inside_Quotes := not Inside_Quotes;
               end if;
               if not Inside_Quotes and A (I) = ' ' then
                  if A'Length > 1 and  A (I-1) /= ' ' then
                     A (I) := ',';
                  end if;
               end if;
            end loop;
            return A & ",";  -- Must have a non-empty Value following
         end if;
      end Attrib;
   begin
      if Tag = "" then
         Append (Root.Data, ")");
         Root.Comma := True;
      else
         Append (Root.Data, Comma_Image (Root.Comma) &
                              Tag & "(" & Attrib & Value);
         Root.Comma := False;
      end if;
   end Callback;

   function Get_Fact (Root : in Kb_Fact) return String is
   begin
      return To_String (Root.Data);
   end Get_Fact;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
end Pace.Xml_Tree.Kbase;
