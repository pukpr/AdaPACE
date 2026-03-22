package PBM.Solver is


   type UTM is
      record
         E, N : Float;
         Alt : Float := 0.0; -- Don't care
      end record;

   function Is_Using_External_Server return Boolean;
         
   procedure Compute (Item_Type, Mode, Unit, Vehicle: in String;
                      Zone : in Integer;
                      SW_Extent, NE_Extent : in UTM;
                      Src, Tgt : in UTM;
                      El, Az : out Float;
                      Config_Value : out Integer;
                      Setting : out Duration;
                      Power_Level : out Integer);
                  


end PBM.Solver;
