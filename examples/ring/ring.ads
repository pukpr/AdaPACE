with Pace;
package Ring is

    type Token is new Pace.Msg with
	record
	    Value : Integer;
	    Color : Integer;
	end record;
    procedure Input (Obj : in Token);

end Ring;
