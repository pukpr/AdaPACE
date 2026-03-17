with Pace;
with Pace.Server.Dispatch;
with Gnu.Jif;

package UIO.Kbase is

   pragma Elaborate_Body;

   function Get_String (Name : in String) return String;
   function Get_String (Name : in String; Id : in String) return String;
   function Get_String (Name : in STring; Id, Aux : in String) return String;
   
   procedure Load (Obj : in Pace.Server.Dispatch.Action'Class);

   procedure Get_File (Obj : in out Pace.Server.Dispatch.Action'Class);

   procedure Get_String (Obj : in out Pace.Server.Dispatch.Action'Class);

   package Img renames Gnu.Jif;
   
   type Stored_Image is new Img.Image with null record;
   procedure Callback (Obj : in out Stored_Image;
                       Data : in String);
   procedure Serve_Image (Obj : in out Stored_Image'Class;
                          Send : in Boolean := True);
   
end UIO.Kbase;
