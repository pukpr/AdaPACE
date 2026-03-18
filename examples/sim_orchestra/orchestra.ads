with Pace;

package Orchestra is

   -- 1. Producer -> Processor message
   type Raw_Data is new Pace.Msg with record
      Serial : Integer;
   end record;
   procedure Input (Obj : in Raw_Data);

   -- 2. Processor -> Consumer message
   type Refined_Data is new Pace.Msg with record
      Serial : Integer;
      Factor : Float;
   end record;
   procedure Input (Obj : in Refined_Data);

end Orchestra;
