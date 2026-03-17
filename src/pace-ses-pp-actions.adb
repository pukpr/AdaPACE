with Pace.Server.Dispatch;
with Pace.Strings;

package body Pace.Ses.Pp.Actions is

   use Pace.Strings;

   type Pp_Cmd is new Pace.Server.Dispatch.Action with null record;
   for Pp_Cmd'External_Tag use "RAW";
   procedure Inout (Obj : in out Pp_Cmd);

   use Pace.Server.Dispatch;

   procedure Inout (Obj : in out Pp_Cmd) is
      S : constant String := U2s(Obj.Set);
   begin
      Obj.Set := S2u(Raw_Parse ("16#" & Pace.Strings.Select_Field (S, 1) & "#",
                                Pace.Strings.Select_Field (S, 2)));
      Pace.Server.Put_Data (U2s(Obj.Set));
   end Inout;

begin
   Save_Action (Pp_Cmd'(Pace.Msg with Set => Pace.Server.Dispatch.Default));
   -- $Id: ses-pp-actions.adb,v 1.2 2006/04/14 23:14:15 pukitepa Exp $
end Pace.Ses.Pp.Actions;
