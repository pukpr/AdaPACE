with Ada.Strings.Unbounded;
with Hal.Audio.Mixer;

package Aho is

    pragma Elaborate_Body;

    function Make_Audio (Key : in String) return Hal.Audio.Mixer.Play_Mix;

   -- $Id: aho.ads,v 1.4 2004/09/20 22:18:10 pukitepa Exp $

end Aho;

