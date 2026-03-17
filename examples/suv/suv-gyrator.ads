with Pace.Notify;
-- Ada Synchronized Notification Pattern
--
-- Ada Singleton Object Pattern
--

package Suv.Gyrator is

    type Status_Type is (Halted, Moving);
    --
    -- Ada Command Pattern Operation Specs
    --
    --
    -- Inputting a Start msg with Go=True will start the object

    type Start is new Pace.Notify.Subscription with
	record
	    Go : Boolean := False;
	end record;
    -- Semantics: Ada Synchronized Notification Pattern, flushed first
    --
    -- Inputting a Move msg will start a motion
    type Move is new Pace.Msg with null record;

    procedure Input (Obj : in Move);
    -- Semantics: Guarded/Protected, Blocking
    --
    -- Requesting a Get_Status will indicate if in motion

    type Get_Status is new Pace.Msg with
	record
	    Value : Status_Type;
	end record;

    procedure Output (Obj : out Get_Status);
    -- Semantics: Guarded/Protected, Non-Blocking
    --
    -- Inputting a Halt msg will stop a motion

    type Halt is new Pace.Msg with
	record
	    Final : Boolean;
	end record;

    procedure Output (Obj : out Halt);

    procedure Input (Obj : in Halt);
    -- Semantics: Guarded/Protected, Blocking
    --
    -- Anyone want to subscribe?

    type Pub is new Pace.Msg with
	record
	    Value : Status_Type;
	end record;

    procedure Input (Obj : in Pub);      -- Semantics: Ada Publisher Pattern
					 --
					 -- Response with callback

    type Response is new Pace.Msg with
	record
	    Callback : Pace.Channel_Msg;
	end record;

    procedure Input (Obj : in Response); -- Semantics: Callback

    -- Text Stream pattern
    type Date is new Pace.Msg with
	record
	    Str : String (1 .. 100);
	end record;
    procedure Inout (Obj : in out Date);
    procedure Input (Obj : in Date);
    function To_String (Obj : in Date) return String;
    procedure From_String (Text : in String; Obj : out Date);

private
    pragma Inline (Input);
end Suv.Gyrator;
