with Hal.Audio.Mixer;
with Pace.Strings;

procedure UIO.Play is
   Msg : Hal.Audio.Mixer.Play_Mix;
begin
   Msg.File := Pace.Strings.S2u (File);
   Pace.Dispatching.Inout (Msg);
end UIO.Play;


