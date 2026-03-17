with Pace.Socket;
with Ses.Pp;
with Pace.Log;
with Hal.Sms;
with Hal.Sms_Lib.Proj_Mag;
with Hal.Sms_Lib.Prop_Mag;
package body Hal.Sms_Lib.C is

   procedure Smspos (Assembly : Hal.Sms.Name; X, Y, Z : Float) is
      Msg : Hal.Sms.Proxy.Translate;
   begin
      Msg.Assembly := Assembly;
      Msg.Pos := (X, Y, Z);
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsPos");
   end Smspos;

   procedure Smsrot (Assembly : Hal.Sms.Name; A, B, C : Float) is
      Msg : Hal.Sms.Proxy.Rotate;
   begin
      Msg.Assembly := Assembly;
      Msg.Rot := (A, B, C);
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsRot");
   end Smsrot;

   procedure Smscoord (Assembly : Hal.Sms.Name; X, Y, Z, A, B, C : Float) is
      Msg : Hal.Sms.Proxy.Coordinate;
   begin
      Msg.Assembly := Assembly;
      Msg.Pos := (X, Y, Z);
      Msg.Rot := (A, B, C);
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsCoord");
   end Smscoord;

   procedure Smsevent (Assembly, Event : Hal.Sms.Name) is
      Msg : Hal.Sms.Proxy.Set_Event;
   begin
      Msg.Assembly := Assembly;
      Msg.Event := Event;
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsEvent");
   end Smsevent;

   procedure Adainit;
   pragma Import (C, Adainit, "smscommsinit");

   Gnat_Argc : Integer;
   pragma Import (C, Gnat_Argc, "gnat_argc");

   Gnat_Argv : System.Address;
   pragma Import (C, Gnat_Argv, "gnat_argv");


   procedure Smsstart (Argc : Integer; Argv : in out System.Address) is
   begin
      Gnat_Argc := Argc;
      Gnat_Argv := Argv'Address;
      Adainit;
      Ses.Pp.Default_Task;
   end Smsstart;

   procedure Smslink (Parent, Child : Hal.Sms.Name) is
      Msg : Hal.Sms.Proxy.Set_Link;
   begin
      Msg.Parent := Parent;
      Msg.Child := Child;
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsLink");
   end Smslink;

   procedure Smsunlink (Assembly : Hal.Sms.Name) is
      Msg : Hal.Sms.Proxy.Set_Unlink;
   begin
      Msg.Assembly := Assembly;
      Pace.Socket.Send (Msg, Ack => False);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsUnlink");
   end Smsunlink;

   procedure SmsProjMagSet (Value : Float) is
   begin
      Hal.Sms_Lib.Proj_Mag.Set_Mag (Value);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsProjMagSet");
   end SmsProjMagSet;

   procedure SmsPropMagSet (Value : Float) is
   begin
      Hal.Sms_Lib.Prop_Mag.Set_Mag (Value);
   exception
      when E: others =>
         Pace.Log.Ex (E, "smsPropMagSet");
   end SmsPropMagSet;


end Hal.Sms_Lib.C;
