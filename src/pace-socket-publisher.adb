with Ada.Tags;
with Pace.Log;
with System;

package body Pace.Socket.Publisher is

   procedure Publish (Obj : in Pace.Msg'Class; Subscriber : in Pace.Channel);
   -- Publishes to Message attached to channel. If channel is
   -- null, then quietly ignores. Subscriber must be subclass of Obj.

   Publish_Error : exception;

   protected body Subscription_List_Imp is
      procedure Add (Subscriber : in Pace.Msg'Class) is
      begin
         if Count >= Subscribers then
            Pace.Display ("WARNING: Too many subscribers, can't add " &
                          Pace.Tag (Subscriber));
         else
            for I in 1 .. Count loop
               if Pace.Tag (Internal_List (I).all) = Pace.Tag (Subscriber) and
                  Internal_List (I).Slot = Subscriber.Slot then
                  return;  -- Subscriber Message already in the list
               end if;
            end loop;
            Count := Count + 1;
            Internal_List (Count) := Pace.Flow (Subscriber);
         end if;
      end Add;
      procedure Publish_All (Server : in Subscription'Class) is
      begin
         for I in 1 .. Count loop
            Publish (Obj => Server, Subscriber => Internal_List (I));
         end loop;
      end Publish_All;
   end Subscription_List_Imp;


   procedure Publish (List : in Subscription_List;
                      Server : in Subscription'Class) is
   begin
      List.Ref.Publish_All (Server);
   end Publish;

   procedure Subscribe (List : in out Subscription_List;
                        Client : in Subscription'Class) is
   begin
      if Client.Send = Async then
         Publish (List, Client);
      else
         List.Ref.Add (Client);
      end if;
   end Subscribe;


   function Empty_List (Subscribers : Natural := 1) return Subscription_List is
      List : Subscription_List (Subscribers);
   begin
      return List;
   end Empty_List;

   function Is_Local (Obj : in Subscription'Class) return Boolean is
   begin
      return Pace.Is_Local (Obj.Slot);
   end Is_Local;

   procedure Publish (Obj : in Pace.Msg'Class; Subscriber : in Pace.Channel) is
      Slot : Node_Slot;
      use type Ada.Tags.Tag;
      Clone : Pace.Msg'Class := Obj;
      Tag_of_Clone : System.Address; -- Corresponding to Ada.Tags.Tag 
      for Tag_Of_Clone'Address use Clone'Address;  -- Tag is 1st position in classwide type
   begin
      if Subscriber /= null then
         Slot := Subscriber.Slot;
         if Pace.Is_Local (Slot) and Obj'Tag = Subscriber.all'Tag then
            return;  -- to avoid infinite loop on self dispatching calls
         end if;
         declare
            -- pragma Suppress (Tag_Check);  -- This is the key !!!
            Tag_Of_Sub : System.Address;
            for Tag_Of_Sub'Address use Subscriber.all'Address;
         begin
            -- Subscriber.all := Obj; -- this preserves the tag but overwrites data
            Tag_of_Clone := Tag_Of_Sub;
         end;
         -- Subscriber.Slot := Slot;
         -- Send (Subscriber.all, Ack => False);
         Clone.Slot := Subscriber.Slot;
         Send (Clone, Ack => False);
      end if;
   exception
      when E: others =>
         Pace.Log.Ex (E, "Msg not published to a subscriber");
         raise Publish_Error;
   end Publish;

------------------------------------------------------------------------------
-- $id: pace-socket-publisher.adb,v 1.2 11/04/2002 22:35:50 pukitepa Exp $
------------------------------------------------------------------------------
end Pace.Socket.Publisher;

