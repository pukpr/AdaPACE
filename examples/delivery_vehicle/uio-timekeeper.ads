with Pace.Server.Dispatch;

package Uio.Timekeeper is
   pragma Elaborate_Body;

-- URL action requests

   type Get_Time is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Time);
   -- if set="actual", returns wall-clock time

   type Get_Day is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Day);

-- Non action requests

   type Reset_Time is new Pace.Msg with null record;
   procedure Input (Obj : in Reset_Time);

end Uio.Timekeeper;
