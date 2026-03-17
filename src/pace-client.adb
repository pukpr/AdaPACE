
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with Ada.Characters.Handling;

with Pace.Strings;
with Pace.Tcp.Http;
with Pace.Semaphore;

package body Pace.Client is

   type Action_Data is
      record
         -- the callback is needed to trigger the initial publish upon subscribing
         Callback : Modified_Callback;
         Server_Set : Pace.Strings.Bstr_Hashset.Set;
      end record;

   package Push_Action_To_Server_Pkg is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type => String,
      Element_Type => Action_Data,
      Hash => Ada.Strings.Hash,
      Equivalent_Keys => "=",
      "=" => "=");

   Action_To_Server_Map : Push_Action_To_Server_Pkg.Map;
   Subscribe_Mutex : aliased Pace.Semaphore.Mutex;

   procedure Add_Action (Action : String; Callback : Modified_Callback) is
      Action_Element : Action_Data := (Callback, Pace.Strings.Bstr_Hashset.Empty_Set);
   begin
      Action_To_Server_Map.Insert (Action,
                                   Action_Element);
   end Add_Action;

   procedure Default_Modified_Callback is
   begin
      null;
   end Default_Modified_Callback;

   function Action_Form (Action : String) return String is
      Upper_Action : constant String := Ada.Characters.Handling.To_Upper (Action);
   begin
      if Upper_Action (Upper_Action'First) = '/' then
         return Upper_Action (Upper_Action'First + 1 .. Upper_Action'Last);
      else
         return Upper_Action;
      end if;
   end Action_Form;

   function Has_Action (Action : String) return Boolean is
      My_Action : String := Action_Form (Action);
   begin
      return Action_To_Server_Map.Contains (My_Action);
   end Has_Action;

   procedure Subscribe_To_Action (Action : String; Host : String; Port : String) is
      L : Pace.Semaphore.Lock (Subscribe_Mutex'Access);
      My_Action : String := Action_Form (Action);
   begin
      if Action_To_Server_Map.Contains (My_Action) then
         declare
            use Pace.Strings;
            use Pace.Strings.Bstr;
            Action_Element : Action_Data := Action_To_Server_Map.Element (My_Action);
         begin
            Action_Element.Server_Set.Include (S2b (Host & ":" & Port));
            -- overwrites existing
            Action_To_Server_Map.Include (My_Action, Action_Element);
            -- do initial publish!
            Action_Element.Callback.all;
         end;
      end if;
   end Subscribe_To_Action;

   procedure Publish (Action : String; Data : String; Content_Type : String := "text/xml") is
   begin
      if Action_To_Server_Map.Contains (Action) then
         declare
            use Pace.Strings;
            use Pace.Strings.Bstr;
            use Pace.Strings.Bstr_Hashset;
            Action_Element : Action_Data := Action_To_Server_Map.Element (Action);
            Iter : Cursor := Action_Element.Server_Set.First;
         begin
            while Iter /= No_Element loop
               declare
                  Response : String := Pace.Tcp.Http.Post (B2s (Element (Iter)),
                                                           Action,
                                                           Data,
                                                           Content_Type);
               begin
                  null;
               end;
               Next (Iter);
            end loop;
         end;
      end if;
   end Publish;

end Pace.Client;
