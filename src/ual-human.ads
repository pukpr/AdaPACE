with Pace;
with Ada.Containers.Ordered_Multisets;
with Hal.Sms;
with Hal;

-- provides functionality common to human activities
package Ual.Human is

   type Active_Human is private;
   type Active_Human_Ptr is access Active_Human;

   -- replaces pace.log.wait for human activities to allow the human to be
   --interrupted
   procedure Activity (Person : in out Active_Human; Length : Duration);

   -- interrupt a human this way
   procedure Interrupt_Activity
     (Person   : in out Active_Human;
      To_Do    : Pace.Channel_Msg;
      Priority : Integer);

   procedure Wait_Until_Interrupted (Person : in out Active_Human);

   use Hal;

   -- translation that checks for interrupts
   procedure Translation
     (Person  : in out Active_Human;
      Name    : in String;
      Start   : in Position;
      Final   : in out Position;
      Time    : in Duration;
      Stopped : out Boolean);

   -- rotation that checks for interrupts
   procedure Rotation
     (Person  : in out Active_Human;
      Name    : in String;
      Start   : in Orientation;
      Final   : in out Orientation;
      Time    : in Duration;
      Stopped : out Boolean);

private

   type Interrupt is record
      Priority : Integer;
      To_Do    : Pace.Channel_Msg;
   end record;

   function "=" (L, R : Interrupt) return Boolean;
   function "<" (L, R : Interrupt) return Boolean;

   -- use multisets to allow more than one interrupt with the same priority
   --level
   package Interrupt_Set_Package is new Ada.Containers.Ordered_Multisets (Element_Type => Interrupt,
                                                                          "<" => "<",
                                                                          "=" => "=");
   type Active_Human is record
      Interrupt_Set : Interrupt_Set_Package.Set;
   end record;

end Ual.Human;
