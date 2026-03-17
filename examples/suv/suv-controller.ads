
with Pace;
                                       --
                                       -- Ada Singleton Object Pattern
                                       --

package Suv.Controller is
                                       --
                                       -- Ada Command Pattern Operation Spec
                                       --
   
   type Start_Control is new Pace.Msg with null record;

   procedure Input(Obj : Start_Control);

end Suv.Controller;
