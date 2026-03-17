package PBM.NABK is


   type UTM is
      record
         E, N : Float;
         Alt : Float := 0.0; -- Don't care
      end record;

   function Is_Using_NABK_Server return Boolean;
         
   procedure FM (Projo, Fuze, Unit, Vehicle: in String;
                 Zone : in Integer;
                 SW_Extent, NE_Extent : in UTM;
                 Src, Tgt : in UTM;
                 El, Az : out Float;
                 Prop : out Integer;
                 Setting : out Duration;
                 Charge : out Integer);
                 


end PBM.NABK;
