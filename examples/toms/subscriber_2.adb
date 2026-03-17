with Pace;
with Pace.Log;
with Status_Publisher;
with Pace.Socket;

package body Subscriber_2 is

    Local_Status : Integer := 0;
    Prior_Status : Integer := 0;

    type Toms_Status_Type is new Status_Publisher.Toms_Status with null record;

    procedure Input (Obj : in Toms_Status_Type);
    procedure Input (Obj : in Toms_Status_Type) is
    begin

	Local_Status := Obj.Toms_Count;

    end Input;

    function Id is new Pace.Log.Unit_Id;

    task Subscriber_Two;

    task body Subscriber_Two is

	procedure Subscribe is new Pace.Socket.Observer
				      (Remote => Status_Publisher.Toms_Status,
				       Local => Toms_Status_Type);
--    toms_status_msg : toms_status_type;
    begin

	Pace.Log.Agent_Id (Id);
	Pace.Log.Put_Line ("SUBSCRIBER_2 : Waking Up");
	Subscribe;
--    status_publisher.input (status_publisher.toms_status (toms_status_msg));

	loop

	    Pace.Log.Put_Line ("SUBSCRIBER_2 : Wait for published data");

	    Pace.Log.Wait (1.0);

	    Pace.Log.Put_Line ("SUBSCRIBER_2 : Local_Status = " &
			       Integer'Image (Local_Status));

	    if Local_Status = 10 then

		Pace.Log.Put_Line ("SUBSCRIBER_2 : Exiting Subscriber_2");
--          exit;

	    elsif Local_Status /= Prior_Status then

		Prior_Status := Local_Status;

	    end if;

	end loop;

    end Subscriber_Two;

end Subscriber_2;
