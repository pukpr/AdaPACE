package Pace.Socket.Publisher is
   ----------------------------------------------------------
   -- PUBLISHER -- Publish/Subscribe pattern, using dispatch
   ----------------------------------------------------------
   pragma Elaborate_Body;

   subtype Subscription is Pace.Msg;
   -- Server derives from Pace.Msg (Subscription is convenience renaming)
   -- Client subclasses from Server msg, and overrides Pace.Input.

   type Subscription_List (Subscribers : Natural := 1) is private;

   procedure Subscribe (List : in out Subscription_List;
                        Client : in Subscription'Class);
   procedure Publish (List : in Subscription_List;
                      Server : in Subscription'Class);

   --
   -- "Subscribe" saves the client msg. "Publish" will iterate through
   -- this list by copying "Server" and then dispatching to "Input"
   --

   function Empty_List (Subscribers : Natural := 1) return Subscription_List;

   function Is_Local (Obj : in Subscription'Class) return Boolean;

private
   type Subscription_List_Imp (Subscribers : Natural);
   type Subscription_List_Access is access Subscription_List_Imp;

   type List_Type is array (Natural range <>) of Pace.Channel;

   protected type Subscription_List_Imp (Subscribers : Natural) is
      procedure Add (Subscriber : in Pace.Msg'Class);
      procedure Publish_All (Server : in Subscription'Class);
   private
      Count : Natural := 0;
      Internal_List : List_Type (1 .. Subscribers);
   end Subscription_List_Imp;

   type Subscription_List (Subscribers : Natural := 1) is
      record
         Ref : Subscription_List_Access :=
           new Subscription_List_Imp (Subscribers);
      end record;

------------------------------------------------------------------------------
-- $id: pace-socket-publisher.ads,v 1.2 11/04/2002 22:35:53 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Socket.Publisher;
