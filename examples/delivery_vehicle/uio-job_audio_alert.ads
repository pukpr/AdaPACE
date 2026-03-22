with Pace;

package Uio.Job_Audio_Alert is

   pragma Elaborate_Body;

   type Begin_Alert is new Pace.Msg with null record;
   procedure Input (Obj : Begin_Alert);

   type End_Alert is new Pace.Msg with null record;
   procedure Input (Obj : End_Alert);

private
   pragma Inline (Input);
end Uio.Job_Audio_Alert;
