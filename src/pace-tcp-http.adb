with Pace.Strings;
with Pace.Log;

package body Pace.Tcp.Http is

   procedure Null_Call (Page : in String) is
   begin
      null;
   end Null_Call;

   function Null_Init return String is
   begin
      return "/";
   end Null_Init;

   --  Return the hostname portion of a "host" or "host:port" URL string.
   --  For example, "forecast.weather.gov:80" returns "forecast.weather.gov".
   --  IPv6 bracket notation (e.g. "[::1]:8080") is not used in this library.
   function Extract_Host (Url : String) return String is
   begin
      for I in Url'Range loop
         if Url (I) = ':' then
            return Url (Url'First .. I - 1);
         end if;
      end loop;
      return Url;
   end Extract_Host;

   function Discard_Header (S : Socket_Type) return Integer is
      Length : Integer := -1;
   begin
      loop
         declare
            Str : constant String := Get_Line (S);
         begin
            exit when Str = "";
            Pace.Log.Put_Line ("HTTP response: " & Str);
            if Pace.Strings.Select_Field (Str, 1) = "Content-Length:" then --! Ignore case
               Length := Integer'Value(Pace.Strings.Select_Field (Str, 2));
            end if;
         exception
            when E : others =>
               Pace.Log.Ex (E, "HTTP response header:" & Str);
         end;
      end loop;
      return Length;
   end Discard_Header;


   function Get_Data (S : Socket_Type;
                      Length : in Integer) return String is
      Buffer : String (1 .. Length);
   begin
      Physical_Receive (S, Buffer(1)'Address, Length);
      Shutdown (S);
      return Buffer;
   exception
      when Communication_Error =>
         Shutdown (S);
         return "";
   end Get_Data;

   function Get (Url : in String;
                 Item : in String;
                 Call : in Callback := Null_Call'Access;
                 Init : in Initialize := Null_Init'Access) return String is
      S : Socket_Type;
      Nothing : constant String (1 .. 1) := "" & Ascii.Nul;

      function Get_Line_Of_Data return String is
      begin
         return Get_Line (S);
      exception
         when Communication_Error =>
            Shutdown (S);
            return Nothing;
      end Get_Line_Of_Data;

      function Chomp (Page : in String) return String is
         Next : constant String := Get_Line_Of_Data;
      begin
         if Next = Nothing then
            return Page;
         else
            Call (Next);
            return Chomp (Page & Next & Ascii.Lf);
         end if;
      end Chomp;

      L : Integer;
   begin
      S := Establish_Connection (Url);
      Put_Line (S, "GET " & Init.all & Item & " HTTP/1.0");
      Put_Line (S, "Host: " & Extract_Host (Url));
      Put_Line (S, "User-Agent: AdaPACE/1.0");
      New_Line (S);
      L := Discard_Header (S);
      if L = 0 then
         Shutdown (S);
         return "";
      elsif L > 0 then
         return Get_Data (S, L);
      else
         return Chomp ("");
      end if;
   end Get;

   function Get (Host : in String;
                 Port : in Integer;
                 Item : in String;
                 Call : in Callback := Null_Call'Access;
                 Init : in Initialize := Null_Init'Access) return String is
   begin
      return Get (Url => Host & ":" & Pace.Strings.Trim (Port),
                  Item => Item,
                  Call => Call,
                  Init => Init);
   end Get;

   procedure Get (Url : in String;
                  Item : in String;
                  Call : in Callback := Null_Call'Access;
                  Init : in Initialize := Null_Init'Access) is
      Str : constant String := Get (Url, Item, Call, Init);
   begin
      null;
   end Get;

   procedure Get (Host : in String;
                  Port : in Integer;
                  Item : in String;
                  Call : in Callback := Null_Call'Access;
                  Init : in Initialize := Null_Init'Access) is
      Str : constant String := Get (Host, Port, Item, Call, Init);
   begin
      null;
   end Get;

   procedure Parse_Get (Page : in String) is
      use Pace.Strings;
      Nf : Integer := Count_Fields (Page, Ascii.Lf);
   begin
      for I in 1 .. Nf loop
         Parse_Line (Select_Field (Page, I, Ascii.Lf));
      end loop;
   end Parse_Get;

   function Binary_Get (Host : in String;
                        Port : in Integer;
                        Item : in String;
                        Header_Discard : in Boolean := False) return String is

      S : Socket_Type;
      L : Integer := -1;

      Buflen : constant := 5000;  -- smaller values require more recursion

      function Get_Data (Length : in Integer := Buflen) return String is
         Buffer : String (1 .. Length);
         C : Character;
         Index : Integer;
      begin
         for Nstore in Buffer'Range loop
            Physical_Receive (S, C'Address, 1);
            Index := Nstore;
            Buffer (Nstore) := C;
         end loop;
         return Buffer & Get_Data (S, Length => 2 * Length);
      exception
         when Communication_Error =>
            Shutdown (S);
            return Buffer (1 .. Index);
      end Get_Data;

   begin
      S := Establish_Connection (Host & ":" & Pace.Strings.Trim (Port));
      Put_Line (S, "GET " & Item & " HTTP/1.0");
      Put_Line (S, "Host: " & Host);
      Put_Line (S, "User-Agent: AdaPACE/1.0");
      New_Line (S);
      if Header_Discard then
         L := Discard_Header (S);
      end if;
      if L = 0 then
         Shutdown (S);
         return "";
      elsif L > 0 then
         return Get_Data (S, L);
      else
         return Get_Data;
      end if;
   end Binary_Get;

   function Post (Url : in String;
                  Item : in String;
                  Raw_Data : in String;
                  Content_Type : in String := "text/xml") return String is
      S : Socket_Type;
      Nothing : constant String (1 .. 1) := "" & Ascii.Nul;

      function Get_Line_of_Data return String is
      begin
         return Get_Line (S);
      exception
         when Communication_Error =>
            Shutdown (S);
            return Nothing;
      end Get_Line_of_Data;

      function Chomp (Page : in String) return String is
         Next : constant String := Get_Line_of_Data;
      begin
         if Next = Nothing then
            return Page;
         else
            return Chomp (Page & Next & Ascii.Lf);
         end if;
      end Chomp;

      Item_Slash : String := "/" & Item;
      L : Integer;
   begin

      S := Establish_Connection (Url);
      Pace.Log.Put_Line ("connection established to " & Url);
      if Item (Item'First) /= '/' then
         Put_Line (S, "POST " & Item_Slash & " HTTP/1.0");
         Pace.Log.Put_Line ("posting action " & Item_Slash);
      else
         Put_Line (S, "POST " & Item & " HTTP/1.0");
         Pace.Log.Put_Line ("posting action " & Item);
      end if;
      Put_Line (S, "Host: " & Extract_Host (Url));
      Put_Line (S, "User-Agent: AdaPACE/1.0");
      Put_Line (S, "CONTENT-TYPE: " & Content_Type);
      Put_Line (S, "CONTENT-LENGTH: " & Integer'Image (Raw_Data'Length));
      New_Line (S);
      Put_Line (S, Raw_Data);
      Pace.Log.Put_Line ("posting data " & Raw_Data);
      L := Discard_Header (S);
      if L = 0 then
         Shutdown (S);
         return "";
      elsif L > 0 then
         return Get_Data (S, L);
      else
         return Chomp ("");
      end if;
   end Post;

end Pace.Tcp.Http;
