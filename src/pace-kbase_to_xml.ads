with Pace.Rule_Process;
with Ada.Strings.Unbounded;

function Pace.Kbase_To_Xml (Agent : in Pace.Rule_Process.Agent_Type;
                            Query : in Ada.Strings.Unbounded.Unbounded_String;
                            Is_Xml_Tree : Boolean) return String;
-- if Xml_Tree is true then return string in a hierarchy format, and
-- if it is false then return string in a list format
