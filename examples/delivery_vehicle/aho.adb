
with Pace.Server.Dispatch;
with Vkb;

package body Aho is

   -- this only applies to the volume within the Inventory Handling
   Volume_On : Boolean := False;

    function Make_Audio (Key : in String) return Hal.Audio.Mixer.Play_Mix is
       use Ada.Strings.Unbounded;
       Audio_Msg : Hal.Audio.Mixer.Play_Mix;
    begin
       if Volume_On then
          declare
             use Vkb.Rules;
             V : Variables (1 .. 2);
          begin
             Vkb.Agent.Query (Key, V);
             Audio_Msg.File := V(1);
             Audio_Msg.Volume := Integer'Value (+V(2));
          end;
       else
          Audio_Msg.File := To_Unbounded_String ("eject.wav");  -- a dummy noise.. smallest wav file
          Audio_Msg.Volume := 0;
       end if;
       return Audio_Msg;
    end Make_Audio;


   type Toggle_Volume is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Toggle_Volume);
   procedure Inout (Obj : in out Toggle_Volume) is
   begin
      Volume_On := not Volume_On;
   end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Toggle_Volume'(Pace.Msg with Set => Default));
end Aho;
