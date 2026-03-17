generic
   type Connections is range <>;  -- Number of message connections

package Pace.Event_Io is
   pragma Elaborate_Body;

   procedure Send (Obj : in String; Ack : in Boolean := False);  -- Synchronized
   procedure Await (Obj : in String;
                    Obj_Received : out Boolean;  -- If no Wait
                    Wait : in Boolean := True);  -- Synchronized
   procedure Flush (Obj : in String);
end Pace.Event_Io;

