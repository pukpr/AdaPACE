with Pace;

package Gyrator is
   pragma Elaborate_Body; -- Singleton Object

   type Status_Type is (Halted, Moving);

   -- Inputting a Move msg will start a motion
   type Move is new Pace.Msg with null record;
   procedure Input (Obj : in Move);
   -- Semantics: Guarded/Protected, Blocking

   -- Requesting a Get_Status will indicate if in motion
   type Get_Status is new Pace.Msg with record
      Value : Status_Type;
   end record;
   procedure Output (Obj : out Get_Status);
   -- Semantics: Guarded/Protected, Non-Blocking

   -- Inputting a Halt msg will stop a motion
   type Halt is new Pace.Msg with null record;
   procedure Input (Obj : in Halt);
   -- Semantics: Guarded/Protected, Blocking

end Gyrator;
