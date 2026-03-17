with Hal.Sms_Lib.Ribbon;
with Hal.Sms;
with Pace;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Hal.Sms_Lib.Antenna is

   Wheel : Boolean := Pace.Getenv ("wheel", 0) = 1;

   Amt : Float := 0.0;
   Pi2 : constant Float := 2.0 * Ada.Numerics.Pi;
   G : Ada.Numerics.Float_Random.Generator;

   function Flex (Link : Integer; Current : Hal.Position)
                 return Hal.Orientation is
   begin
      if Wheel then
         if Link = 1 then
            Amt := 0.0;
         else
            Amt := Pi2 / 20.0 +
                     (Ada.Numerics.Float_Random.Random (G) - 0.5) / 100.0;
         end if;
         return (0.0, 0.0, Amt);
      else
         if Link > 4 and Link < 16 then
            return (Amt, 0.0, Amt);
         else
            return (0.0, Amt, 0.0);
         end if;
      end if;
   end Flex;

   package Rod is new Hal.Sms_Lib.Ribbon (Base => (Pace.Msg with
                                                   Assembly => Hal.Sms.To_Name ("link"),
                                                   Pos => (0.0, 0.0, 0.0),
                                                   Rot => (0.0, 0.0, 0.0),
                                                   Entity => Hal.Sms.To_Name ("")),
                                          Segment => (1.0, 0.0, 0.0),
                                          Flex => Flex,
                                          Links => 20,
                                          Time_Delta => 0.03);


   Counter : Float := 0.0;


   procedure Step (Number : in Integer := 1) is
      use Ada.Numerics.Elementary_Functions;
   begin
      Counter := Counter + 0.1;
      Amt := 0.2 * Sin ((1.0 + Counter / 100.0) * Counter) *
               Exp (-Counter / 50.0);

      Rod.Step (Number);
   end Step;


end Hal.Sms_Lib.Antenna;

