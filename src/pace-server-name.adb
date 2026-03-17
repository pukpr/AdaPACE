with Ada.Strings.Unbounded;
with Pace.Tcp.Http;
with Pace.Ports;
with Pace.Semaphore;
with Pace.Server.Dispatch;
with Pace.Server.Html;

package body Pace.Server.Name is

   --
   -- Name Service for identifying IP ports from logical nodes
   --

   use Ada.Strings.Unbounded, Pace.Server.Html, Pace.Ports;

   Node : constant String := "node";
   None : constant String := "(none)";
   Unone : constant Unbounded_String := To_Unbounded_String (None);

   subtype Node_Type is Integer range 0 .. 20; -- MAGIC, change if # > Nodes

   type Port_Type is
      record
         Msg : Unbounded_String;
         Web : Unbounded_String;
      end record;

   type Port_Array is array (Node_Type) of Port_Type;

   Ports : Port_Array := (others => (Msg => Unone, Web => Unone));

   M : aliased Pace.Semaphore.Mutex;

   procedure Service is
      function Integer_Value (Key : String) return Integer is
      begin
         return Integer'Value (Value (Key));
      end Integer_Value;

      function String_Value (Key : String) return Unbounded_String is
      begin
         return To_Unbounded_String (Value (Key));
      end String_Value;

      Port : Port_Type;
      Crlf : constant String := Ascii.Cr & Ascii.Lf;
      L : Pace.Semaphore.Lock (M'Access);
   begin
      if Key_Exists (Put_Msg_Port) then
         Ports (Integer_Value (Node)).Msg := String_Value (Put_Msg_Port);
         Pace.Display (Value (Node) & "=>" & Value (Put_Msg_Port));

      elsif Key_Exists (Get_Msg_Port) then
         Port := Ports (Integer_Value (Node));
         Pace.Display (Value (Node) & "=>" & To_String (Port.Msg));
         Pace.Server.Put_Data (To_String (Port.Msg) & Crlf);

      elsif Key_Exists (Put_Web_Port) then
         Ports (Integer_Value (Node)).Web := String_Value (Put_Web_Port);
         Pace.Display (Value (Node) & "=>" & Value (Put_Web_Port));

      elsif Key_Exists (Get_Web_Port) then
         Port := Ports (Integer_Value (Node));
         Pace.Display (Value (Node) & "=>" & To_String (Port.Web));
         Pace.Server.Put_Data (To_String (Port.Web) & Crlf);

      elsif Key_Exists ("show_ports") then
         Pace.Server.Put_Data (Header ("Node Msg Web") & Paragraph);
         Pace.Server.Put_Data (Table (Border => True));
         for I in Node_Type loop
            Pace.Server.Put_Data (Row & Cell (Integer'Image (I)));
            Pace.Server.Put_Data (Cell (To_String (Ports (I).Msg)));
            Pace.Server.Put_Data
              (Cell (Anchor ("http://" & To_String (Ports (I).Web)) &
                     To_String (Ports (I).Web & Anchor_End)));
         end loop;
         Pace.Server.Put_Data (End_Table);
      elsif Key_Exists ("reset_ports_exit") then
         for I in Node_Type loop
            declare
               Name : constant String := To_String (Ports (I).Web);
            begin
               if Name /= None then
                  Ports (I).Web := To_Unbounded_String (None);
                  Ports (I).Msg := To_Unbounded_String (None);
                  Pace.Tcp.Http.Get (Name, "exit");
               end if;
            exception
               when E: others =>
                  Pace.Error ("Error killing " & Name, Pace.X_Info (E));
            end;
         end loop;
         Pace.Server.Put_Data (End_Table);
      end if;
   exception
      when E: others =>
         Pace.Error (Pace.X_Info (E));
   end Service;

   type Name_Service is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Name_Service);
   for Name_Service'External_Tag use "NAME_SERVICE";

   procedure Inout (Obj : in out Name_Service) is
   begin
      Service;
   end Inout;


   use Pace.Server.Dispatch;
begin
   Save_Action (Name_Service'(Pace.Msg with
                              Set => Pace.Server.Dispatch.Default));
------------------------------------------------------------------------------
-- $Id: pace-server-name.adb,v 1.8 2006/04/14 23:14:13 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Server.Name;
