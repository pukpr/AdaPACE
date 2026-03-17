with AHD;

package Suv.Assembly is

   type Step is new Ahd.Transaction with 
      record
         Last : Float;
      end record;
   procedure Inout (Obj : in out Step);
   procedure Input (Obj : in Step);

   type Step1 is new Ahd.Transaction with 
      record
         Last : Float;
      end record;
   procedure Inout (Obj : in out Step1);
   procedure Input (Obj : in Step1);

end;
