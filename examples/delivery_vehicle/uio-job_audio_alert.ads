with Pace;

package Uio.Job_Audio_Alert is

   pragma Elaborate_Body;

   type Begin_Alert is new Pace.Msg with null record;
   procedure Input (Obj : Begin_Alert);

   type End_Alert is new Pace.Msg with null record;
   procedure Input (Obj : End_Alert);

private
   pragma Inline (Input);
   -- $Id: uio-job_audio_alert.ads,v 1.3 2004/09/20 22:18:13 pukitepa Exp $
end Uio.Job_Audio_Alert;
