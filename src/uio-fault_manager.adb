with Pace.Log;
with Pace.Semaphore;
with Pace.Server;
with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Ada.Strings.Unbounded;
with Pace.Strings;

package body Uio.Fault_Manager is

   use Pace.Strings;

   use Pace.Server.Dispatch;
   use Pace.Server.Xml;
   use Ada.Strings.Unbounded;

   function Id is new Pace.Log.Unit_Id;

   -- As software exceptions are logged they are stored in an xml format
   -- in this unbounded_string.
   Logged_Exceptions_Xml : Ada.Strings.Unbounded.Unbounded_String;

   -- used as a lock on Logged_Exceptions_Xml
   My_Mutex : aliased Pace.Semaphore.Mutex;


   type Update_Exceptions is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Update_Exceptions);
   procedure Inout (Obj : in out Update_Exceptions) is
      Xml_Output : Unbounded_String;
      Data_Lock : Pace.Semaphore.Lock (My_Mutex'Access);
   begin
      Pace.Server.Xml.Put_Content (Default_Stylesheet =>
                                     "eng/fault/exceptions.xsl");
      Append (Xml_Output, S2u (Begin_Doc));
      Append (Xml_Output, Item ("software_exceptions", U2s (Logged_Exceptions_Xml)));
      Append (Xml_Output, S2u (End_Doc));
      Pace.Server.Put_Data (U2s (Xml_Output));
      Pace.Log.Trace (Obj);
   end Inout;


   type Report_Exception is new Pace.Msg with
      record
         Log : Ada.Strings.Unbounded.Unbounded_String;
      end record;
   procedure Input (Obj : in Report_Exception);
   procedure Input (Obj : in Report_Exception) is
      Data_Lock : Pace.Semaphore.Lock (My_Mutex'Access);
   begin
      Append (Logged_Exceptions_Xml,
              Item ("exception", Item ("time", Duration'Image (Pace.Now)) &
                                   Item ("data", U2s (Obj.Log))));
      Pace.Log.Trace (Obj);
   end Input;


   task Agent is pragma Task_Name (Pace.Log.Name); end Agent;
   task body Agent is
   begin
      Pace.Log.Agent_Id (Id);
      loop
         declare
            Exception_Log : String := Pace.Log.Wait_For_Ex;
            Msg : Report_Exception;
         begin
            Msg.Log := S2u (Exception_Log);
            Pace.Dispatching.Input (Msg);
         end;
      end loop;
   exception
      when E: others =>
         Pace.Log.Ex (E);
         Pace.Log.Put_Line ("**** ERROR in Fault Manager Agent: " & Id);
   end Agent;

begin
   Save_Action (Update_Exceptions'(Pace.Msg with Set => Default));
end Uio.Fault_Manager;
