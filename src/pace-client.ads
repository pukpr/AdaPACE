
package Pace.Client is

   pragma Elaborate_Body;

   type Modified_Callback is access procedure;

   procedure Default_Modified_Callback;

   -- the callback is needed to trigger the initial publish upon subscribing
   procedure Add_Action (Action : String; Callback : Modified_Callback);

   function Has_Action (Action : String) return Boolean;

   procedure Subscribe_To_Action (Action : String; Host : String; Port : String);

   procedure Publish (Action : String; Data : String; Content_Type : String := "text/xml");

end Pace.Client;
