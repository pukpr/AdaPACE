package Hal.Sms_Lib.Mesh is
   --
   -- For generating an array of 6DOF's to send
   --

   type SixDof is
      record
         P : Position;
         R : Orientation;
      end record;
   type SD is array (Positive range <>) of SixDof;

   procedure Send (Name : in String; -- Each 6DOF member suffixed by Array Index
                   Msg : in SD);     -- "Name-<I>"


   -- $Id: hal-sms_lib-mesh.ads,v 1.1 2006/05/25 19:01:18 ludwiglj Exp $
end;
