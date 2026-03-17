with Ada.Tags.Generic_Dispatching_Constructor;
with Text_IO;
with Pace.XML;

package body Pace.Cmd is

   External_Tag_Size : constant Integer := Getenv ("PACE_TAG_SIZE", 1000);

   procedure Skip_Tag
     (S      : access St'Class;
      Ending : in     Character := '>') is
      --  Skip the next tag on stream S, returns when Ending is found
      Ch : Character;
   begin
      loop
         Character'Read (S, Ch);
         exit when Ch = Ending;
      end loop;
   end Skip_Tag;


   function Get_Val (Xml_Stream : access St'Class;
                     Str : in String := "") return String is
      Ch : Character;
   begin
      Character'Read (Xml_Stream, Ch);
      if Ch /= '<' then
         -- Ada.Text_IO.Put (Ch);
         return Get_Val (Xml_Stream, Str & Ch);
      else
         -- Ada.Text_IO.New_Line;
         return Str;
      end if;
   end Get_Val;

   function Get_Value (Xml_Stream : access St'Class) return String is
   begin
      Skip_Tag (Xml_Stream);
      declare
         Str : constant String := Get_Val (Xml_Stream);
      begin
         Skip_Tag (Xml_Stream);
         return Str;
      end;
   end Get_Value;

   function Get_Value (Xml_Stream : access St'Class) return Integer is
   begin
      return Integer'Value (Get_Value(Xml_Stream));
   end Get_Value;
   function Get_Value (Xml_Stream : access St'Class) return Float is
   begin
      return Float'Value (Get_Value(Xml_Stream));
   end Get_Value;
   function Get_Value (Xml_Stream : access St'Class) return Long_Float is
   begin
      return Long_Float'Value (Get_Value(Xml_Stream));
   end Get_Value;
   function Get_Value (Xml_Stream : access St'Class) return Boolean is
   begin
      return Boolean'Value (Get_Value(Xml_Stream));
   end Get_Value;


   function Class_Input (S : access St'Class) return Msg'Class is
      function Dispatching_Input is
         new Ada.Tags.Generic_Dispatching_Constructor
           (T           => Msg,
            Parameters  => St'Class,
            Constructor => Msg'Input);
      Input     : String (1 .. External_Tag_Size);
      Input_Len : Natural := 0;
   begin
      --  On the stream we have , we want to get "tag_name"
      --  Read first character, must be '<'
      Character'Read (S, Input (1));
      if Input (1) /= '<' then
         raise Ada.Tags.Tag_Error with "starting with " & Input (1);
      end if;

      --  Read the tag name, this writes over the '<' already read in at Input(1)
      Input_Len := 0;
      for I in Input'range loop
         Character'Read (S, Input (I));
         Input_Len := I;
         exit when Input (I) = '>';
      end loop;

      --  Check ending tag
      if Input (Input_Len) /= '>' or else Input_Len <= 1 then -- Empty tag
         raise Ada.Tags.Tag_Error with "empty tag or tag too large" & 
                                       Integer'Image(Input_Len);
      else
         Input_Len := Input_Len - 1;
      end if;

      declare
         External_Tag : constant String := Input (1 .. Input_Len);
         Message      : constant Msg'Class := Dispatching_Input
                          (Ada.Tags.Internal_Tag (External_Tag), S);
         --  Dispatches to appropriate Msg'Input depending on the tag name.
      begin
         --  Skip closing object tag
         Skip_Tag (S);
         -- Skip_Tag (S, ASCII.LF);
         return Message;
      end;
   end Class_Input;

   procedure Class_Output
     (S : access St'Class; Message : in Msg'Class) is
   begin
      --  Write the opening tag
      Character'Write (S, '<');
      String'Write (S, Ada.Tags.External_Tag (Message'Tag));
      Character'Write (S, '>'); -- & ASCII.LF);

      --  Write the object, dispatching call to Point/Pixel'Write
      Msg'Output (S, Message);

      -- Write the closing tag
      String'Write (S, "</");
      String'Write (S, Ada.Tags.External_Tag (Message'Tag));
      Character'Write (S, '>'); -- & ASCII.LF);
      -- String'Write (S, "" & ASCII.LF);
   end Class_Output;


   procedure Put_Value (Xml_Stream : access St'Class; 
                        Value : in String) is
   begin
      for I in Value'Range loop
         Character'Write (Xml_Stream, Value(I));
      end loop;
   end Put_Value;

   procedure Write (S : access St'Class; Message : in Msg) is
   begin
      Put_Value (S, Item ("slot", Node_Slot'Image(Message.Slot)) &
                    Item ("id",   Image(Message.Id)) &
                    Item ("send", Synchronization'Image(Message.Send)) &
                    Item ("enum", Delivery'Image(Message.Enum)) &
                    Item ("time", Duration'Image(Art.To_Duration(Message.Time))) &
                    Item ("wait", Duration'Image(Art.To_Duration(Message.Wait))));
   end Write;

   procedure Read (S : access St'Class; Message : out Msg) is
   begin
      -- Ada.Text_IO.Put_Line ("PACE READ :" & Tag(Message));
      Message.Slot := Node_Slot'Value (Get_Value (S));
      Ignore (Get_Value (S));
      Message.Send := Synchronization'Value (Get_Value (S));
      Message.Enum := Delivery'Value (Get_Value (S));
      Message.Time := Art.To_Time_Span (Duration'Value (Get_Value (S)));
      Message.Wait := Art.To_Time_Span (Duration'Value (Get_Value (S)));
   end Read;

   procedure Ignore (Str : in String) is
   begin
      null;
   end Ignore;

   function Item (Tag_Name, Value : in String) return String is
   begin
      return "<" & Tag_Name & ">" & Value & "</" & Tag_Name & ">";
   end Item;

   function Item (Tag_Name : in String; Value : in Integer) return String is
   begin
      return Item (Tag_Name, Integer'Image (Value));
   end Item;
   function Item (Tag_Name : in String; Value : in Float) return String is
   begin
      return Item (Tag_Name, Float'Image (Value));
   end Item;
   function Item (Tag_Name : in String; Value : in Long_Float) return String is
   begin
      return Item (Tag_Name, Long_Float'Image (Value));
   end Item;
   function Item (Tag_Name : in String; Value : in Boolean) return String is
   begin
      return Item (Tag_Name, Boolean'Image (Value));
   end Item;

end Pace.Cmd;
