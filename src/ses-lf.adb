with Ada.Tags;
with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Fixed;
with Unchecked_Conversion;

package body Ses.Lf is

   type Channel is access all Action'Class;

   function Head (Item : String; 
                  Field_Separator : Character) return String is
      Finish : Integer := Item'First;
   begin
      Finish := Ada.Strings.Fixed.Index (Item, (1 => Field_Separator), Finish) - 1;
      if Finish < 0 then
         return "";
      else
         return Ada.Strings.Fixed.Head (Item, Finish);
      end if;
   end;

   function Tail (Item : String; 
                  Field_Separator : Character) return String is
      Finish : Integer := Item'First;
   begin
      Finish := Item'Last - Ada.Strings.Fixed.Index (Item, (1 => Field_Separator), Finish);
      if Finish = Item'Last then
         return "";
      else
         return Ada.Strings.Fixed.Tail (Item, Finish);
      end if;
   end;

   package Table is
      procedure Set (K : Ada.Tags.Tag; E : Channel);
      function Get (K : Ada.Tags.Tag) return Channel;
   end Table;

   package body Table is

      function Hash (Key : Ada.Tags.Tag) return Ada.Containers.Hash_Type is
         function To_Hash is new Unchecked_Conversion (
                               Ada.Tags.Tag,
                               Ada.Containers.Hash_Type);
      begin
         return To_Hash (Key);
      end Hash;

      package Maps is new Ada.Containers.Indefinite_Hashed_Maps 
           (Ada.Tags.Tag, Channel, Hash, Ada.Tags."=");

      M : Maps.Map;
      
      procedure Set (K : Ada.Tags.Tag; E : Channel) is
      begin
         if Maps.Contains (M, K) then
            Maps.Replace (M, K, E);
         else
            Maps.Insert (M, K, E);
         end if;
      end Set;

      function Get (K : Ada.Tags.Tag) return Channel is
      begin
         if Maps.Contains (M, K) then
            return Maps.Element (M, K);
         else
            return null;
         end if;
      end Get;
   end Table;
   

   protected Db is
      procedure Save_Action (Obj : in Action'Class);
      -- Saves the Class-wide object for later processing.
      procedure Dispatch_To_Action (Text : in String; Quit : out Boolean);
   end Db;

   protected body Db is

      procedure Save_Action (Obj : in Action'Class) is
      begin
         Table.Set (Obj'Tag, new Action'Class'(Obj));
      end Save_Action;

      procedure Dispatch_To_Action (Text : in String; Quit : out Boolean) is
         Full_Name  : constant String :=
            Ada.Characters.Handling.To_Upper (Text);
         Msg        : constant String := Head (Full_Name, ' ');
         Cmd        : constant String := Tail (Text, ' ');
         Action_Obj : Channel;
         function Test_Factory return Channel is
         begin
            return Table.Get (Ada.Tags.Internal_Tag (Msg & ".A"));
         exception
            when Ada.Tags.Tag_Error =>
               return null;
         end Test_Factory;
      begin
         Quit       := False;
         Action_Obj := Test_Factory;
         if Action_Obj = null then
            Action_Obj := Table.Get (Ada.Tags.Internal_Tag (Msg));
            if Action_Obj = null then
               raise Not_Registered;
            end if;
         end if;
         Input (Action_Obj.all, Cmd);
      exception
         when End_Processing =>
            Quit := True;
      end Dispatch_To_Action;
   end Db;

   procedure Dispatch_To_Action (Text : in String; Quit : out Boolean) is
   begin
      Db.Dispatch_To_Action (Text, Quit);
   end Dispatch_To_Action;

   procedure Initialize (Obj : in out Action) is
   begin
      Db.Save_Action (Obj);
   end Initialize;

   package body Factory is

      procedure Input (Obj : in A; Cmd : in String) is
         Quit : Boolean;
      begin
         Process (Cmd, Quit);
         if Quit then
            raise End_Processing;
         end if;
      end Input;

      Registered_A : A;
   end Factory;

   ----------------------------------------------------------------------------
   -- $Id: ses-lf.adb,v 1.4 2006/04/14 23:14:15 pukitepa Exp $
   ----------------------------------------------------------------------------
end Ses.Lf;
