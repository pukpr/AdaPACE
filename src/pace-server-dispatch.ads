with Pace.Strings;
with Pace.Server.Http_Caching;
with Pace.Client;

package Pace.Server.Dispatch is

   -------------------------------------------
   -- DISPATCH -- The server pattern
   -------------------------------------------
   -- "Name" inputs look like the following:
   --     http://host:port/CC.OBJ.OP?set="<xml>xml_data_string</xml>"

   pragma Elaborate_Body;  -- Elaboration before anyone else registers

   Not_Registered : exception;

   type Action is abstract new Pace.Msg with
      record
         Set : Pace.Strings.Us;
      end record;
   procedure Inout (Obj : in out Action) is abstract;
   procedure Append (Obj : in out Action; Text : in String);

   -- Saves the Class-wide object for later processing.
   -- setting get_etag turns on caching for this action request
   -- set publish_callback for those action requests that support publish
   procedure Save_Action (Obj : in Action'Class;
                          Publish_Callback : Pace.Client.Modified_Callback := Pace.Client.Default_Modified_Callback'Access;
                          Counter : Pace.Server.Http_Caching.Cache_Counter_Ptr := Pace.Server.Http_Caching.Null_Cache_Counter_Ptr);

   Default : constant Pace.Strings.Us;
   Xml_Set : constant Pace.Strings.Us;

   function Dispatch_To_Action (Name : in String) return Boolean;
   function Dispatch_To_Action (Name : in String) return String;


-- self inspection

   type Show_All is new Action with null record;
   procedure Inout (Obj : in out Show_All);
   -- Display all Actions registered (saved)

   -- expects set=<time>0.5</time> as input
   -- calls pace.log.wait with the time as the value
   type Wait is new Action with null record;
   procedure Inout (Obj : in out Wait);

   -- Encoding function for tags, use to generate default XML for forms
   function X (Name, Value : in String) return String;

private
   Default : constant Pace.Strings.Us :=
     Pace.Strings.Ustr.Null_Unbounded_String;
   Xml_Set : constant Pace.Strings.Us :=
     Pace.Strings.Ustr.To_Unbounded_String ("(xml output)");

------------------------------------------------------------------------------
------------------------------------------------------------------------------
end Pace.Server.Dispatch;
