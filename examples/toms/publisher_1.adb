with Pace.Log;
with Status_Publisher;

package body Publisher_1 is

    function Id is new Pace.Log.Unit_Id;

    task Publisher_One;

    task body Publisher_One is

	Start_Time : Duration := Pace.Now;
	Toms_Status_Msg : Status_Publisher.Toms_Status;

    begin

	Pace.Log.Agent_Id (Id);
	Pace.Log.Put_Line ("PUBLISHER_1 : wait for start");
	Pace.Log.Wait_Until (Start_Time + 10.0);
	Pace.Log.Put_Line ("PUBLISHER_1 : Go!");

	for I in 1 .. Integer'Last loop
	    Pace.Log.Put_Line ("PUBLISHER_1: Publish Count = " &
			       Integer'Image (I));

	    Toms_Status_Msg.Toms_Count := I;
	    Status_Publisher.Publish (Toms_Status_Msg);

	    Pace.Log.Wait (5.0);

	end loop;


    end Publisher_One;

end Publisher_1;
