with Pace.Log;
with Hal.Audio.Mixer;
with Vkb;

package body Uio.Mission_Audio_Alert is

   function Id is new Pace.Log.Unit_Id;

   Keep_Alerting : Boolean := True;

   task Agent is
      entry Input (Obj : Begin_Alert);
   end Agent;

   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);

      loop
         accept Input (Obj : Begin_Alert);
         loop
            declare
               use Vkb.Rules;
               Audio_Msg : Hal.Audio.Mixer.Play_Mix;
               V : Variables (1 .. 2);
            begin
               Vkb.Agent.Query ("mission_alert", V);
               Audio_Msg.File := V(1);
               Audio_Msg.Volume := Integer'Value (+V(2));
               Pace.Dispatching.Inout (Audio_Msg);
               Pace.Log.Wait (3.0);
               Pace.Dispatching.Inout (Audio_Msg);
            end;
            exit when not Keep_Alerting;
         end loop;
      end loop;

   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;

   procedure Input (Obj : Begin_Alert) is
   begin
      Keep_Alerting := True;
      Agent.Input (Obj);
   end Input;

   procedure Input (Obj : End_Alert) is
   begin
      Keep_Alerting := False;
   end Input;


end Uio.Mission_Audio_Alert;
