with Pace.Socket.Publisher;  -- Ada Publish/Subscribe Pattern
with Pace.Log;  -- Instrumentation and Discrete Event Simulation
with Pace.Server.Dispatch; -- Command Pattern for Web Server
with Pace.Persistent;  -- Persistent Command Pattern
with Pace.Fault; -- Fault Command Pattern
with Ada.Strings.Unbounded;
with Pace.Strings;
with Gnu.Xml_Tree;
with Uio.Kbase;
with Gnu.Jif;
with Ada.Numerics.Discrete_Random;
with Pace.Stream;

--
-- Ada Singleton Object Pattern
--
package body Suv.Gyrator is

    --
    --  Ada Package Identification Pattern
    --
    function Id is new Pace.Log.Unit_Id;

    --
    --  Ada Protected Data Pattern
    --
    type Command_Type is (Start_Move, Stop, None);

    protected State is
	procedure Set_Command (Cmd : in Command_Type);
	function Get_Command return Command_Type;
	procedure Set_Status (Status : in Status_Type);
	function Get_Status return Status_Type;
    private
	Current_Command : Command_Type := None;
	Current_Status : Status_Type := Halted;
    end State;

    protected body State is
	procedure Set_Command (Cmd : in Command_Type) is
	begin
	    Current_Command := Cmd;
	end Set_Command;
	function Get_Command return Command_Type is
	begin
	    return Current_Command;
	end Get_Command;
	procedure Set_Status (Status : in Status_Type) is
	begin
	    Current_Status := Status;
	end Set_Status;
	function Get_Status return Status_Type is
	begin
	    return Current_Status;
	end Get_Status;
    end State;

    --
    -- Pace Fault Pattern
    --
    procedure Stop_Fault is
	function Where is new Pace.Log.Unit_Id;
	Msg : Pace.Fault.Id;
    begin
	Msg.Name := Pace.Fault.To_Name (Where);
	Pace.Socket.Send (Msg);
    end Stop_Fault;

    --
    --  Ada Publish/Subscribe Pattern
    --
    List : Pace.Socket.Publisher.Subscription_List;

    --
    -- Debug Pattern
    --
    type M is mod 1000;
    Debug_Value : M := 0;
    for Debug_Value'Size use 32;
    -- pragma Export (C, Debug_Value);

    --
    --  Ada Active Object (aka Agent) Pattern
    --
    task Agent;
    task body Agent is
	Cmd : Command_Type;
	X : Float := 0.0; -- Simplistic position value
	Starter : Start;
	Local_Status : Pub; -- update the locally persistent state information. 
    begin
	--
	--  Ada Package Identification Pattern
	--
	Pace.Log.Agent_Id (Id);
	--
	--  Ada Synchronized Notification Pattern
	--
	Inout (Starter);  -- Wait to be notified
	Pace.Log.Put_Line ("Server Started => " & Boolean'Image (Starter.Go));

	loop
	    Debug_Value := Debug_Value + 1;
	    --
	    -- Ada Protected Data Pattern
	    --
	    if X > 10_000.0 then
		State.Set_Status (Halted);
		State.Set_Command (None);
	    end if;
	    Pace.Log.Wait (0.01);
	    Cmd := State.Get_Command;
	    case Cmd is
		when Start_Move =>
		    X := X + 0.1;
		    State.Set_Status (Moving);
		when Stop =>
		    Pace.Log.Put_Line ("Server Reached" & Float'Image (X));
		    State.Set_Status (Halted);
		    State.Set_Command (None);
		    Stop_Fault;
		when None =>
		    null;
	    end case;
	    --
	    --  Ada Publish/Subscribe Pattern
	    --
	    Local_Status.Value := State.Get_Status;
	    Pace.Socket.Publisher.Publish (List, Local_Status);
	end loop;
    end Agent;

    --
    --  Ada Command Pattern bodies
    --
    procedure Input (Obj : in Move) is
    begin
	--
	-- Discrete Event Wait (Simulated or Real or Off)
	--
	Pace.Log.Wait (0.1);
	--
	-- Ada Protected Data
	--
	State.Set_Command (Start_Move);
    end Input;

    procedure Output (Obj : out Get_Status) is
    begin
	--
	-- Ada Protected Data
	--
	Obj.Value := State.Get_Status;
	--
	-- Ada Command Instrumentation Pattern
	--
	Pace.Log.Trace (Obj);
    end Output;

    procedure Output (Obj : out Halt) is
    begin
	Pace.Log.Wait (0.01);
	--
	-- Ada Protected Data
	--
	State.Set_Command (Stop);
	--
	-- Ada Command Instrumentation Pattern
	--
	Pace.Log.Trace (Obj);
	Pace.Log.Put_Line ("RECEIVED HALT");
	Obj.Final := True;
    end Output;

    procedure Input (Obj : in Halt) is
    begin
	Pace.Log.Put_Line ("RECEIVED HALT 2");
    end Input;

    procedure Input (Obj : in Pub) is
    begin
	--
	--  Ada Publish/Subscribe Pattern
	--
	Pace.Socket.Publisher.Subscribe (List, Obj);
    end Input;

    --
    -- Ada Command Pattern for Web Server
    --

    type Xt is new Gnu.Xml_Tree.Tree with null record;
    procedure Callback (Root : in out Xt; Tag, Value, Attributes : in String);
    procedure Callback (Root : in out Xt; Tag, Value, Attributes : in String) is
    begin
	Pace.Server.Put_Data (Tag & " :: " & Value);
    end Callback;

    use Pace.Server.Dispatch;

    type Monitor is new Pace.Server.Dispatch.Action with null record;
    procedure Inout (Obj : in out Monitor);
    procedure Inout (Obj : in out Monitor) is
	Tree : Xt;
	use Pace.Strings;
    begin
	begin
	    Parse (U2s(Obj.Set), Tree);
	    Search (Tree);
	exception
	    when others =>
		Pace.Log.Put_Line ("XML failed");
	end;
	-- This loads a page corresponding to 
	Uio.Kbase.Load (Obj);
	Pace.Log.Trace (Obj);
    end Inout;

    --
    -- Dynamic Gif Server Push pattern
    --

    Color_Value : Boolean := False;
    subtype Speckle is Integer range 1 .. 100;
    package Speckler is new Ada.Numerics.Discrete_Random (Speckle);
    Sg : Speckler.Generator;

    procedure Draw_Gauge (Finish : Boolean) is
	use Uio.Kbase;
	G : constant Img.Rgb := (0, 255, 0);
	B : constant Img.Rgb := (0, 0, 255);
	R : constant Img.Rgb := (255, 0, 0);
	Pic : Stored_Image (100, 80);
	Green : Img.Color := Image_Color_Allocate (Pic, G);  
	Blue : Img.Color := Image_Color_Allocate (Pic, B);  
	Red : Img.Color := Image_Color_Allocate (Pic, R);  
    begin
	Image_Color_Transparent (Pic, Green);
	if Color_Value then
	    Image_Line (Pic, (50, 80), (Speckler.Random (Sg), 1), Blue);
	else
	    Image_Line (Pic, (50, 80), (Speckler.Random (Sg), 1), Red);
	end if;
	Color_Value := not Color_Value;
	Uio.Kbase.Serve_Image (Pic, Finish);
    end Draw_Gauge;

    type Gauge is new Pace.Server.Dispatch.Action with null record;
    procedure Inout (Obj : in out Gauge);

    procedure Inout (Obj : in out Gauge) is
    begin
	Pace.Server.Push_Content;
	loop
	    Draw_Gauge (Finish => False);
	    delay 0.1;
	end loop;
	Pace.Log.Trace (Obj);
    end Inout;

    --
    -- File-based Gif Server Pull pattern
    --

    Switch_Value : Boolean := False;

    type Switch is new Pace.Server.Dispatch.Action with null record;
    procedure Inout (Obj : in out Switch);
    procedure Inout (Obj : in out Switch) is
        use Pace.Strings;
    begin
	if Switch_Value then
	    Obj.Set := s2u("off");
	else  
	    Obj.Set := s2u("on");
	end if;
	Uio.Kbase.Get_File (Obj);
	Switch_Value := not Switch_Value;
	Pace.Log.Trace (Obj);
    end Inout;

    --
    --  Ada Callback Pattern
    --
    procedure Input (Obj : in Response) is
	use type Pace.Channel_Msg;
	Copy : Response;
    begin
	--
	-- Ada Persistent Command Pattern
	--
	Pace.Persistent.Put (Obj);
	Pace.Persistent.Get (Copy);

	Pace.Socket.Send (+Copy.Callback); -- send back to where it originated
    end Input;


    function To_String (Obj : in Date) return String is
    begin
	Pace.Log.Put_Line ("to_string:" & Obj.Str);
	return Obj.Str;
    end To_String;

    procedure From_String (Text : in String; Obj : out Date) is
    begin
	Pace.Log.Put_Line ("from_string:" & Text & Integer'Image (Text'Length));
	Obj.Str (Text'Range) := Text;
	Pace.Stream.Inout_Protocol (Obj);
    end From_String;

    procedure Inout (Obj : in out Date) is
    begin
	Pace.Log.Put_Line (Obj.Str);
	Obj.Str (1 .. 3) := "bye";
    end Inout;

    procedure Input (Obj : in Date) is
    begin
	Pace.Log.Put_Line ("INPUT DATE:" & Obj.Str);
	-- Obj.Str (1..3) := "bib"; 
    end Input;

    package Tdate is new Pace.Stream.Text (Date, To_String, From_String, 50);

begin
    Save_Action (Monitor'(Pace.Msg with Set =>  
                 Pace.Strings.s2u("<xml><view>on</view></xml>")));
    Save_Action (Switch'(Pace.Msg with Set => Default));
    Save_Action (Gauge'(Pace.Msg with Set => Default));
end Suv.Gyrator;

