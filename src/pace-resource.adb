package body Pace.Resource is

   type Index_Availability is array (Index_Type) of Boolean;
   None : constant Index_Availability := (others => False);

   protected Index_Resource is
      entry Get (Index : out Index_Type;
                 Oldest : in Boolean := False);
      --
      -- Get an unused Index
      --
      procedure Free (Index : in Index_Type);
      --
      -- Free an Index for re-use
      --
      function Is_Available return Boolean;
      --
      -- Is
      --
   private
      Available : Index_Availability := None;
      Old : Index_Type := Index_Type'First;
      --
      -- Availability of Indices
      --
   end Index_Resource;


   protected body Index_Resource is
      entry Get (Index : out Index_Type;
                 Oldest : in Boolean := False) when Available /= None is
      begin
         if Oldest then
            loop
               -- Find the Free Index
               for I in Old .. Index_Type'Last loop
                  if Available (I) then
                     Available (I) := False;
                     Index := I;
                     if I = Index_Type'Last then
                        Old := Index_Type'First;
                     else
                        Old := Index_Type'Succ (I);
                     end if;
                     return;
                  end if;
               end loop;
               Old := Index_Type'First;
            end loop;
         else
            -- Find the Free Index
            for I in Index_Type loop
               if Available (I) then
                  Available (I) := False;
                  Index := I;
                  return;
               end if;
            end loop;
            -- Should never get here
            raise Resource_Error;
         end if;
      end Get;

      procedure Free (Index : in Index_Type) is
      begin
         Available (Index) := True;
      end Free;

      function Is_Available return Boolean is
      begin
         return Available /= None;
      end Is_Available;
   end Index_Resource;

   function Get (Oldest : Boolean := False) return Index_Type is
      Index : Index_Type;
   begin
      Index_Resource.Get (Index, Oldest);
      return Index;
   end Get;

   procedure Free (Index : in Index_Type) is
   begin
      Index_Resource.Free (Index);
   end Free;

   function Is_Available return Boolean is
   begin
      return Index_Resource.Is_Available;
   end Is_Available;

   ------------------------------------------------------------------------------
   -- $id: pace-resource.adb,v 1.1 09/16/2002 18:18:36 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Resource;
