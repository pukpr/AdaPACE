with Pace.Socket.Publisher;

package body Status_Publisher is

    Max_Subs : Integer := 100;

    Subscriber_List : Pace.Socket.Publisher.Subscription_List (Max_Subs);

    procedure Input (Obj : in Toms_Status) is
    begin
	Pace.Socket.Publisher.Subscribe (Subscriber_List, Obj);
    end Input;

    procedure Publish (Obj : in Toms_Status) is
    begin
	Pace.Socket.Publisher.Publish (Subscriber_List, Obj);
    end Publish;

end Status_Publisher;
