with Hal.Sms;

package Hal.Sms_Lib.Aggregator is

   pragma Elaborate_Body;

   procedure Send_Coord (Assembly : Hal.Sms.Name;
                         X, Y, Z : Float;
                         A, B, C : Float;
                         Entity : Hal.Sms.Name);
   pragma Export (C, Send_Coord, "send_coord");

   procedure Send_Coord (Assembly : String;
                        Pos : Position;
                        Ori : Orientation;
                        Entity : String);

end Hal.Sms_Lib.Aggregator;
