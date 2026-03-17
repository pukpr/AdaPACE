with Ada.Strings.Fixed;
with Pace.Log;
with Hal.Audio.Mixer;
with Hal.Audio;
with Pace.Server.Dispatch;
with Pace.Strings;

package body Uio.Audio.Player is

   use Pace.Strings;

   function Id is new Pace.Log.Unit_Id;

   task Agent is pragma Task_Name (Pace.Log.Name);
   end Agent;

   task body Agent is
      Msg : Signal;
   begin
      Pace.Log.Agent_Id (Id);
      loop
         Inout (Msg);

         declare
            Text : constant String := S (Msg.Text);
            File : Boolean := Ada.Strings.Fixed.Index (Text, ".aiff") > 0;
         begin
            -- check for .wav extension too
            if not File then
               File := Ada.Strings.Fixed.Index (Text, ".wav") > 0;
            end if;
            if File then
               Hal.Audio.Play (Text);
            else
               Hal.Audio.Mixer.Say (Text);
            end if;
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
   end Agent;


   type Message is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Message);

   procedure Inout (Obj : in out Message) is
      Msg : Signal;
   begin
      Msg.Text := Obj.Set;
      Input (Msg);
      Pace.Log.Trace (Obj);
   end Inout;

   use Pace.Server.Dispatch;
begin

   Save_Action (Message'(Pace.Msg with S2u ("comms check")));

------------------------------------------------------------------------------
-- $id: uio-audio-player.adb,v 1.3 04/03/2003 21:14:21 pukitepa Exp $
------------------------------------------------------------------------------
end Uio.Audio.Player;
