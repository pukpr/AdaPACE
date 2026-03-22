with Pace.Server.Dispatch;
package Uio.Dbw is

    pragma Elaborate_Body;

    function Get_Loc_Xml return String;

    type Get_All_Gauges is new Pace.Server.Dispatch.Action with null record;
    procedure Inout (Obj : in out Get_All_Gauges);

    type Start_Engine is new Pace.Server.Dispatch.Action with null record;
    procedure Inout (Obj : in out Start_Engine);

private
    pragma Inline (Inout);
end Uio.Dbw;
