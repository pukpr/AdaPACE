with Pace.Server.Dispatch;
with Pace.Notify;
with Str;
package Uio.Route is
   pragma Elaborate_Body;

   -- moved to spec so that a route can be loaded through the url pattern
   -- or simply by calling Inout on a Load_Route
   type Load_Route is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Load_Route);

   -- moved to spec so that a route can be loaded through the url pattern
   -- or simply by calling Inout on a Load_Route
   type Load_Target is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Load_Target);

   type Update_Move_Plan is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Update_Move_Plan);

   type Get_Current_Route is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Current_Route);

   -- so the task in sim-interface knows to send the Waypoint_Acknowledge message
   -- back to c4isr
   type Waypoint_Acknowledge_Signal is new Pace.Notify.Subscription with
      record
         Plan_Id : Str.Bstr.Bounded_String;
         Waypoint : Natural;
      end record;

   -- $Id: uio-route.ads,v 1.10 2004/09/30 19:28:57 ludwiglj Exp $
end Uio.Route;
