with Pace.Tcp;
with Pace.Strings;
with Ada.Strings.Unbounded;

package Pace.Server is

   ----------------------------------------------------------
   -- SERVER - Creates a multiple http web server environment
   ----------------------------------------------------------
   -- A server session has a unique host:port assignment,
   -- which is assigned to a dedicated task.
   --
   --   Note: The default session is used for convenience. It is set when
   --   processing commences for a given thread. As long as
   --   the thread of control is not transferred when a URL request is
   --   made, the session context becomes implicit.
   --
   pragma Elaborate_Body;

   use Pace.Strings;

   -- the HTTP response codes that are supported. start with R since enum can't start with a number
   type Response_Code is (R200, R204, R304, R404);

   Communication_Error : exception renames Pace.Tcp.Communication_Error;

   procedure Put_Content (Content : in String := "text/html"; Code : Response_Code := R200);
   procedure Push_Content;

   procedure Put_Data (Text : in String; -- Data to put
                       More_Follows : in Boolean := True; -- More to put
                       Raw : Boolean := False); -- Includes a NL
   function Active_Session return Boolean;
   procedure Close_Session;
   
   procedure Send_Data (Text : in String); -- Finished put

   function Get_Bin return String; -- the CGI bin name

   function Is_Index return Boolean;  -- True if an Isindex request made.

   function Value (Key : in String) return String;
   function Key_Exists (Key : in String) return Boolean;
   function Value_Count (Key : in String) return Natural;
   function Get_Client return Integer;
   function Get_Method return String;

   package Keys is
      --------------------------------------------------------------------
      -- KEYS -- Convenience for retrieving keys, default if not available
      --------------------------------------------------------------------
      function Value (Key : in String; Default : in String) return String;
      function Value (Key : in String; Default : in Integer) return Integer;
      function Value (Key : in String; Default : in Float) return Float;

   end Keys;

   --
   -- Checks to see if file Name has the extension
   --
   function Check_Extension
     (Name : in String; Extension : in String) return Boolean;

   --
   -- Session Instancing: each server has its own thread
   --
   type Session_Type is abstract tagged limited private;

   procedure Get_Data (Session : access Session_Type; Text : in String) is
     abstract;

   type Session_Access is access all Session_Type'Class;

   task type Reader (Session : access Session_Type'Class; Size : Integer) is
      pragma Storage_Size (Size);
   end Reader;

   type Reader_Access is access Reader;

   generic  -- simple atomic accessors
      type Item is private;
   package Atom is
      procedure Set (Obj : in Item);
      function Get return Item;
   end;

   function To_Http_Date (The_Time : Duration) return String;

private

      -- Actual explicit sessions.  These are attached to threads so
      -- we normally don't have to worry about getting the right context.

   procedure Set_Default_Session (Session : in Session_Access);
   function Default_Session return Session_Access;

   procedure Put_Content (Session : access Session_Type;
                          Content : in String := "text/html";
                          Code : Response_Code := R200);

   procedure Push_Content (Session : access Session_Type); -- Netscape only

   procedure Put_Data (Session : access Session_Type;
                       Text : in String; -- Data to put
                       More_Follows : in Boolean := True; -- More to put
                       Raw : Boolean := False); -- includes a new_line

   procedure Send_Data (Session : access Session_Type;
                        Text : in String); -- Finished put

   function Get_Bin (Session : access Session_Type)
                     return String; -- the CGI bin name

   function Is_Index (Session : access Session_Type)
                      return Boolean;  -- True if an Isindex request made.

   function Value
     (Session : access Session_Type; Key : in String) return String;
   function Key_Exists
     (Session : access Session_Type; Key : in String) return Boolean;
   function Value_Count
     (Session : access Session_Type; Key : in String) return Natural;

   procedure Set_Port (Session : access Session_Type; Port : in Integer);

   function Get_Client (Session : access Session_Type) return Integer;

   function Get_Method (Session : access Session_Type) return String;

   procedure Set_Etag (Session : access Session_Type; Etag : Long_Integer);

   function Active_Session (Session : access Session_Type) return Boolean;
   procedure Close_Session (Session : access Session_Type);

   function Decode (S : String) return String;

   --
   -- Data for session
   --

   use Pace.Tcp;

   type Session_Type is abstract tagged limited
      record
         Fd : Socket_Type;
         Content_Placed : Boolean := False;
         Request : Ada.Strings.Unbounded.Unbounded_String;
         Port : Integer := 0; -- If want to use a different port number
         This : Session_Access := Session_Type'Unchecked_Access;
         Server_Push : Boolean := False;
         Client_Handle : Integer := 0;
         Etag : Pace.Strings.Bstr.Bounded_String := S2b("");
         Is_Conditional_Get : Boolean := False;
         If_Match : Pace.Strings.Bstr.Bounded_string := S2b("");
         User_Agent : Ada.Strings.Unbounded.Unbounded_String;
         Host : Ada.Strings.Unbounded.Unbounded_String;
      end record;

   ------------------------------------------------------------------------------
   -- $id: pace-server.ads,v 1.2 11/15/2002 23:14:09 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Server;
