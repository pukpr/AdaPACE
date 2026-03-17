with Pace.Server.Dispatch;
with Pace.Server.Xml;
with Unchecked_Conversion;

package body Hal.Joystick.Dispatcher is

   procedure Input (Obj : in Device_Update) is
      Msg : Data_Update;
   begin
      Msg.Joy_Id := Obj.Joy_Id;
      Msg.Data := Obj.Data;
      Msg.Ack := False; -- don't wait
      Pace.Dispatching.Input (Msg);
   end Input;


   type Button_Array is array (0 .. 31) of Boolean;
   for Button_Array'Size use 32;
   pragma Pack (Button_Array);
   
   function To_Integer is new Unchecked_Conversion (Button_Array, Integer);

   type Get_Data is new Pace.Server.Dispatch.Action with null record;
   procedure Inout (Obj : in out Get_Data);

   procedure Inout (Obj : in out Get_Data) is
      use Pace.Server.Xml;
      Msg : Data_Update;
      All_Bits : constant Boolean := Pace.Server.Key_Exists ("bits");

      function Get_Button return String is
         B : Button_Array;
         Val : Integer;
      begin
         if All_Bits then
            return
               Item("b0", Msg.Data.Buttons (0)) &
               Item("b1", Msg.Data.Buttons (1)) &
               Item("b2", Msg.Data.Buttons (2)) &
               Item("b3", Msg.Data.Buttons (3)) &
               Item("b4", Msg.Data.Buttons (4)) &
               Item("b5", Msg.Data.Buttons (5)) &
               Item("b6", Msg.Data.Buttons (6)) &
               Item("b7", Msg.Data.Buttons (7)) &
               Item("b8", Msg.Data.Buttons (8)) &
               Item("b9", Msg.Data.Buttons (9)) &
               Item("b10", Msg.Data.Buttons (10)) &
               Item("b11", Msg.Data.Buttons (11)) &
               Item("b12", Msg.Data.Buttons (12)) &
               Item("b13", Msg.Data.Buttons (13)) &
               Item("b14", Msg.Data.Buttons (14)) &
               Item("b15", Msg.Data.Buttons (15)) &
               Item("b16", Msg.Data.Buttons (16)) &
               Item("b17", Msg.Data.Buttons (17)) &
               Item("b18", Msg.Data.Buttons (18)) &
               Item("b19", Msg.Data.Buttons (19)) &
               Item("b20", Msg.Data.Buttons (20)) &
               Item("b21", Msg.Data.Buttons (21)) &
               Item("b22", Msg.Data.Buttons (22)) &
               Item("b23", Msg.Data.Buttons (23)) &
               Item("b24", Msg.Data.Buttons (24)) &
               Item("b25", Msg.Data.Buttons (25));
         else
            B := (others => False);
            for I in 0 .. Num_Buttons-1 loop
               B(I) := Msg.Data.Buttons(I);
            end loop;
            Val := To_Integer(B);
            return Item("b", Val);
         end if;
      end;

   begin
      Pace.Dispatching.Inout (Msg);
      declare
         S : constant String := Item ("js", 
                                      Item("axes",
                                            Item("a0", Msg.Data.Axes (0)) &
                                            Item("a1", Msg.Data.Axes (1)) &
                                            Item("a2", Msg.Data.Axes (2)) &
                                            Item("a3", Msg.Data.Axes (3)) &
                                            Item("a4", Msg.Data.Axes (4)) &
                                            Item("a5", Msg.Data.Axes (5)) &
                                            Item("a6", Msg.Data.Axes (6)) &
                                            Item("a7", Msg.Data.Axes (7))
                                       ) &
                                      Item("buttons", Get_Button)
                                    );
      begin
         Pace.Server.Put_Data (S);
      end;                                            
   end Inout;

   use Pace.Server.Dispatch;

begin
   Save_Action (Get_Data'(Pace.Msg with Set => Default));

end Hal.Joystick.Dispatcher;
