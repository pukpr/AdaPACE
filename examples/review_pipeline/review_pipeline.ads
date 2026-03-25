with Pace;
with Ada.Strings.Unbounded;

package Review_Pipeline is
   pragma Elaborate_Body;
   --
   --  Review Pipeline -- Composer / Checker / Critic agent coordination
   --
   --  Implements the following typed agent coordination logic:
   --
   --    type Verdict = { verdict: bool, commentary: string, draft: string }
   --    type Review  = { score: int,  review: string,  draft: string }
   --
   --    let composer : !string  -> !string  = agent { ... }
   --    let checker  : !string  -> !Verdict = agent { ... }
   --    let critic   : !Verdict -> !Review  = agent { ... }
   --
   --    let main : !string -> !string = plumb(input, output) {
   --      input   ; composer ; checker
   --      checker ; filter(verdict = false)
   --              ; map({verdict, commentary}) ; composer
   --      checker ; filter(verdict = true) ; critic
   --      critic  ; filter(score < 85)
   --              ; map({score, review}) ; composer
   --      critic  ; filter(score >= 85).draft ; output
   --    }
   --
   --  All three message types live here so that each agent spec can be
   --  written with a single "with Review_Pipeline;" and no cross-agent
   --  dependencies.  Review_Pipeline.adb is the sole routing hub.
   --
   --  Pattern references (pace.pdf):
   --    Singleton / Agent (pragma Elaborate_Body, task Agent)
   --    Elaboration Order (pragma Elaborate_Body in every spec,
   --                       no with-deps in specs)
   --    Execute-Once / protected (Pipeline_Output)
   --    Notify / Rendezvous (task entry accept pattern)

   subtype Ustring is Ada.Strings.Unbounded.Unbounded_String;
   function "+" (S : String)  return Ustring
      renames Ada.Strings.Unbounded.To_Unbounded_String;
   function "-" (S : Ustring) return String
      renames Ada.Strings.Unbounded.To_String;

   --  -----------------------------------------------------------------------
   --  Message types
   --  -----------------------------------------------------------------------

   --  Input to Composer: the original topic or a revision request that
   --  carries feedback from Checker (verdict=false) or Critic (score<85).
   type Request is new Pace.Msg with record
      Prompt    : Ustring;
      Iteration : Natural := 0;
   end record;
   procedure Input (Obj : in Request);

   --  Output of Composer; input to Checker.
   --  Corresponds to the "!string" output of the composer agent.
   type Draft is new Pace.Msg with record
      Text      : Ustring;
      Iteration : Natural := 0;
   end record;
   procedure Input (Obj : in Draft);

   --  Output of Checker; input to Critic.
   --  Corresponds to the formal Verdict type.
   type Verdict is new Pace.Msg with record
      Passed     : Boolean := False;
      Commentary : Ustring;
      Draft_Text : Ustring;
      Iteration  : Natural := 0;
   end record;
   procedure Input (Obj : in Verdict);

   --  -----------------------------------------------------------------------
   --  Pipeline output
   --  Signals when the Critic approves a draft (score >= 85).
   --  -----------------------------------------------------------------------
   protected Pipeline_Output is
      procedure Publish (Text : in String);  --  called by Critic
      entry    Collect  (Text : out Ustring); --  blocks main until done
   private
      Ready  : Boolean := False;
      Result : Ustring;
   end Pipeline_Output;

end Review_Pipeline;
