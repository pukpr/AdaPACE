with Hal.Sms;

private generic
   -- Position and orientation and name of fixed base segment,
   --   linked segments appended with labels "-1", "-2", etc.
   Base : in Hal.Sms.Proxy.Coordinate;

   -- Vector (size and direction) of base segment
   Segment : in Hal.Position;

   -- Amount to flex subsequent segments from starting link number
   --   - use link to identify current segment for stiffness adjustment
   --   - otherwise current provides a context for goal seeking
   with function Flex (Link : Integer; Current : Hal.Position)
                      return Hal.Orientation;

   -- Number of segment links
   Links : in Integer;

   Time_Delta : in Duration;
   
package Hal.Sms_Lib.Ribbon is

   -- Step the ribbon into new position
   procedure Step (Number : in Integer := 1;
                   Relative_Orientation_Per_Link : in Boolean := True);

   procedure Initialize;
   
   function Calculate_Deflection (Relative_Orientation_Per_Link : in Boolean := True) 
      return Hal.Position;

-- $ID: hal-sms-ribbon.ads,v 1.2 10/28/2003 17:18:58 pukitepa Exp $
end Hal.Sms_Lib.Ribbon;
