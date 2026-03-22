generic
   N : in Integer;
package PBM.Dyna is

   type VisObj_Array is array (Positive range 1 .. N) of Integer;

   procedure read
     (fname     : in String;
      maxvisobj : in Integer := N;
      nvisobj   : out Integer;
      visobj    : out VisObj_Array;
      iecode    : out Integer);                        -- dynaAPI.h:8

   procedure init (iecode : out Integer);                            -- dynaAPI
                                                                     --.h:14

   type DOF6 is record
      X, Y, Z, A, B, C : Long_Float;
   end record;
   type VisOwn_Array is array (Positive range 1 .. N) of DOF6;

   --             0, 1, 2, 3, 4,      5, 6, 7
   type Input is (S0,S1,S2,S3,S4, Azimuth, Elevation, Launch);
   type drivers is array (Input) of Long_Float;

   procedure run
     (time         : in Long_Float;
      driver       : in drivers;
      visOwnship   : out VisOwn_Array;
      event_iecode : out Integer;
      iecode       : out Integer);                    -- dynaAPI.h:16

   procedure xit (iecode : out Integer);                          -- dynaAPI.h:
                                                                  --26

private
--   pragma Import (C, init, "dyna4rtvis0_init");     -- dynaAPI.h:14
--   pragma Import (C, run, "dyna4rtvis0_run");       -- dynaAPI.h:16
--   pragma Import (C, xit, "dyna4rtvis0_exit");     -- dynaAPI.h:26
   pragma Import (C, init, "dyna4rtvis0_init");     -- dynaAPI.h:14
   pragma Import (C, run, "dyna4rtvis0_run");       -- dynaAPI.h:16
   pragma Import (C, xit, "dyna4rtvis0_exit");     -- dynaAPI.h:26
end Pbm.Dyna;
