with System;
with Hal.Sms;
package Hal.Sms_Lib.C is


private

   procedure Smspos (Assembly : Hal.Sms.Name; X, Y, Z : Float);
   pragma Export (C, Smspos, "smsPos");

   procedure Smsrot (Assembly : Hal.Sms.Name; A, B, C : Float);
   pragma Export (C, Smsrot, "smsRot");

   procedure Smscoord (Assembly : Hal.Sms.Name; X, Y, Z, A, B, C : Float);
   pragma Export (C, Smscoord, "smsCoord");

   procedure Smsevent (Assembly, Event : Hal.Sms.Name);
   pragma Export (C, Smsevent, "smsEvent");

   procedure Smsstart (Argc : Integer; Argv : in out System.Address);
   pragma Export (C, Smsstart, "smsStart");

   procedure Smslink (Parent, Child : Hal.Sms.Name);
   pragma Export (C, Smslink, "smsLink");

   procedure Smsunlink (Assembly : Hal.Sms.Name);
   pragma Export (C, Smsunlink, "smsUnlink");

   procedure SmsProjMagSet (Value : Float);
   pragma Export (C, SmsProjMagSet, "smsProjMagSet");

   procedure SmsPropMagSet (Value : Float);
   pragma Export (C, SmsPropMagSet, "smsPropMagSet");

end Hal.Sms_Lib.C;
