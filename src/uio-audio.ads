with Pace.Notify;
with Ada.Strings.Unbounded;

package Uio.Audio is

   type Signal is new Pace.Notify.Subscription with
      record
         Text : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   -- User triggers on Input
   -- Player waits on Inout
   -- If text has audio file extension then file is played

   -- convenience functions
   function U (T : String) return Ada.Strings.Unbounded.Unbounded_String
     renames Ada.Strings.Unbounded.To_Unbounded_String;
   function S (T : Ada.Strings.Unbounded.Unbounded_String) return String
     renames Ada.Strings.Unbounded.To_String;

-- $id: uio-audio.ads,v 1.4 11/04/2002 22:25:43 pukitepa Exp $
end Uio.Audio;
