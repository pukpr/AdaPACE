with Suv.Gyrator;
with Pace.Socket;  -- Ada Proxy Pattern
with Pace.Signals.Buffers; -- Ada Synchronized Buffered Command Pattern
with Pace.Log;  -- Instrumentation and Discrete Event Simulation
with Pace.Fault;

package body Suv.Controller is

    --
    --  Ada Package Identification Pattern
    --
    function ID is new Pace.Log.Unit_ID;

    type Callback is new Pace.Msg with null record;
    procedure Input (Obj : Callback);

    procedure Call_Start is
	--
	--  Ada Command Pattern inheriting from Notify Pattern
	--
        Msg : Suv.Gyrator.Start;
    begin
        Msg.Go := True;
        Pace.Log.Put_Line ("Send a Start command");
	--
	--  Ada Proxy Pattern
	--
        Pace.Socket.Send (Msg);
        Pace.Log.Put_Line ("Finished Sending Start command");
    end Call_Start;

    procedure Call_Move is
	--
	--  Ada Command Pattern
	--
        Msg : Suv.Gyrator.Move;
    begin
        Pace.Log.Put_Line ("Send a Move command");
	--
	--  Ada Proxy Pattern
	--
        Pace.Socket.Send (Msg);
        Pace.Log.Put_Line ("Finished Sending Move command");
    end Call_Move;

    function Call_Status return Suv.Gyrator.Status_Type is
	--
	--  Ada Command Pattern
	--
        Msg : Suv.Gyrator.Get_Status;
    begin
	--
	--  Ada Proxy Pattern
	--
        Pace.Socket.Send_Out (Msg);
        Pace.Log.Put_Line ("Status is " & Suv.Gyrator.Status_Type'Image (Msg.Value));
        return Msg.Value;
    end Call_Status;

    procedure Call_Halt is
	--
	--  Ada Command Pattern
	--
        Msg : Suv.Gyrator.Halt;
    begin
        Pace.Log.Put_Line ("Send a Halt command");
	--
	--  Ada Proxy Pattern
	--
        Pace.Socket.Send_Out (Msg);
        Pace.Log.Put_Line ("Finished sending Halt command");
    end Call_Halt;

    Current_Status : Suv.Gyrator.Status_Type;

    --
    --  Ada Command Pattern as private body encapsulation
    --
    type Starter is new Pace.Msg with
        record
            Num_Loops : Integer;
        end record;

    --
    --  Ada Synchronized Buffered Command Pattern
    --
    Buffer : Pace.Signals.Buffers.Buffer;  -- Contains Queued Class-wide data

    --
    --  Ada Publisher Pattern
    --
    type My_Status is new Suv.Gyrator.Pub with null record;
    procedure Input (Obj : in My_Status);

    Value : Suv.Gyrator.Status_Type := Suv.Gyrator.Halted;
    procedure Input (Obj : in My_Status) is
	use type Suv.Gyrator.Status_Type;
    begin 
        -- Display the data if it is new
        if Value /= Obj.Value then
            Pace.Log.Put_Line ("Pub RX <= " & Suv.Gyrator.Status_Type'Image (Obj.Value));
        end if;
        Value := Obj.Value;
    end Input;

    --
    --  Ada Active Object (aka Agent) Pattern
    --
    Storage : constant Integer := Pace.Log.Task_Storage(ID);
    task Agent is
       pragma Storage_Size (Storage);
    end Agent;
    task body Agent is
	--
	--  Synchronized Buffered Command Pattern
	--
        Data : Pace.Channel_Msg;  -- Class-wide data
	Num_Loops : Integer := 0;
	use type Pace.Channel_Msg;

	--
	--  Ada Publisher Pattern
	--
        Msg : My_Status;

	use type Suv.Gyrator.Status_Type;
    begin
        --
	--  Ada Package Identification Pattern
	--
        Pace.Log.Agent_ID (ID);

	--
	--  Synchronized Buffered Command Pattern
	--
        Pace.Signals.Buffers.Get (Buffer, Data);
	Num_Loops := Starter (+Data).Num_Loops; -- dereference class-wide data
        Pace.Log.Put_Line ("Num_Loops =" & Integer'Image(Num_Loops));

	--
	--  Ada Publisher Pattern
	--
        Suv.Gyrator.Input (Suv.Gyrator.Pub (Msg));  -- Subscribe to published data

        --
	-- Discrete Event Wait (Simulated or Real or Off)
	--
        Call_Start;
        Pace.Log.Wait (1.0);

        Call_Move;
        Pace.Log.Wait (0.1);

        Current_Status := Call_Status;
        Pace.Log.Wait (1.0);

        Call_Halt;
        for I in 1 .. Num_Loops loop
            exit when Call_Status = Suv.Gyrator.Halted;
            Pace.Log.Wait (0.5);
        end loop;

        Pace.Log.Put_Line ("Finished Agent: Detected that it " & 
	                  Suv.Gyrator.Status_Type'Image (Call_Status));

        --
        -- Command Callback pattern
        --
        declare
           Cb : Callback;
           Msg : Suv.Gyrator.Response;
        begin
           Msg.Callback := Pace.To_Callback(Cb); -- setting callback node
           Pace.Socket.Send (Msg);
        end;
        
        declare
           Msg : Pace.Fault.ID;
        begin
           Pace.Socket.Send_Out (Msg);
           Pace.Log.Put_Line ("Fault = " & Pace.Fault.To_Str (Msg.Name));
        end;
        
        
    exception
        when E: others =>
            --
	    --  Ada Logging Exception Pattern
	    --
            Pace.Log.Ex (E, "Found error in Agent");
    end Agent;

    --
    --  Ada Command Pattern bodies
    --
    procedure Input (Obj : Start_Control) is
        S : Starter;
    begin
	--
	--  Ada Synchronized Buffered Command Pattern
	--
        S.Num_Loops := 1000;
        Pace.Signals.Buffers.Put (Buffer, S);
        --
	-- Ada Command Instrumentation Pattern
	--
        Pace.Log.Trace (Obj);
    end Input;


    --
    -- Command Callback pattern
    --
    procedure Input (Obj : Callback) is
    begin
        Pace.Log.Put_Line ("Suv.Controller callback received");
    end;

end Suv.Controller;
