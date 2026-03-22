with Ada.Strings.Unbounded;
with Hal.Audio.Mixer;

package Aho is

    pragma Elaborate_Body;

    function Make_Audio (Key : in String) return Hal.Audio.Mixer.Play_Mix;

end Aho;

