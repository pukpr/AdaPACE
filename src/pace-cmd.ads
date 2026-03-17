with Ada.Streams;

package Pace.Cmd is

   subtype St is Ada.Streams.Root_Stream_Type;

   type Msg is new Pace.Msg with null record;
   
   procedure Write (S : access St'Class; Message : in Msg);
   for Msg'Write use Write;
   procedure Read (S : access St'Class; Message : out Msg);
   for Msg'Read use Read;
   procedure Class_Output (S : access St'Class; Message : in Msg'Class);
   for Msg'Class'Output use Class_Output;
   function Class_Input (S : access St'Class) return Msg'Class;
   for Msg'Class'Input use Class_Input;

   -- For streaming decoding/encoding   
   -- procedure Skip_Tag (S : access St'Class; Ending : in Character := '>');
   function Get_Value (Xml_Stream : access St'Class) return String;
   function Get_Value (Xml_Stream : access St'Class) return Integer;
   function Get_Value (Xml_Stream : access St'Class) return Float;
   function Get_Value (Xml_Stream : access St'Class) return Long_Float;
   function Get_Value (Xml_Stream : access St'Class) return Boolean;
   procedure Put_Value(Xml_Stream : access St'Class; 
                       Value : in String);

   function Item (Tag_Name, Value : in String) return String;
   function Item (Tag_Name : in String; Value : in Integer) return String;
   function Item (Tag_Name : in String; Value : in Float) return String;
   function Item (Tag_Name : in String; Value : in Long_Float) return String;
   function Item (Tag_Name : in String; Value : in Boolean) return String;

   procedure Ignore (Str : in String); -- ignores a string return value

end Pace.Cmd;
