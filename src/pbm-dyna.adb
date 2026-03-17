with System;
package body PBM.Dyna is

   procedure read
     (fname     : in String;
      maxvisobj : in Integer := N;
      nvisobj   : out Integer;
      visobj    : out VisObj_Array;
      iecode    : out Integer)
   is

      procedure dyna4rtvis0_read
        (fname     : in System.Address;
         maxvisobj : in Integer;
         nvisobj   : out Integer;
         visobj    : out VisObj_Array;
         iecode    : out Integer);                        -- dynaAPI.h:8
      pragma Import (C, dyna4rtvis0_read, 
                      "dyna4rtvis0_read");       -- dynaAPI
                                                                     --.h:8
--      pragma Import (C, dyna4rtvis0_read, "dvis_read");       -- dynaAPI

      Name : constant String := fname & ASCII.NUL;
   begin
      dyna4rtvis0_read
        (Name (Name'First)'Address,
         maxvisobj,
         nvisobj,
         visobj,
         iecode);
   end read;

end Pbm.Dyna;
