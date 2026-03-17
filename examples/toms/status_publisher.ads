with Pace;

package Status_Publisher is

    type Toms_Status is new Pace.Msg with
	record
	    Toms_Count : Integer := 0;
	end record;

    procedure Input (Obj : in Toms_Status);

    procedure Publish (Obj : in Toms_Status);

end Status_Publisher;
