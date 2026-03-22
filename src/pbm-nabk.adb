with Pace.Tcp.Http;
with Pace.Xml;
with Pace.Strings;
with Pace.Log;
with Ada.Numerics.Elementary_Functions;

package body PBM.NABK is

   Server : constant String := Pace.Getenv ("NABK", "");
   Port : constant Integer := Pace.Getenv ("NABK_Port", 5651); --5651
   
   function Is_Using_NABK_Server return Boolean is
   begin
      return Server /= "";
   end Is_Using_NABK_Server;
   
   
   function ToF (S : String) return Float is
   begin
      begin
         return Float'Value (S);
      exception
         when others =>
            return Float(Integer'Value(S));
      end;
   exception
      when others =>
         Pace.Log.Put_Line ("! Format error on numeric conversion: " & S);
         return 0.0;
   end ToF;          


   procedure FM (Projo, Fuze, Unit, Vehicle: in String;
                 Zone : in Integer;
                 SW_Extent, NE_Extent : in UTM;
                 Src, Tgt : in UTM;
                 El, Az : out Float;
                 Prop : out Integer;
                 Setting : out Duration;
                 Charge : out Integer) is
   begin
      if Is_Using_NABK_Server then
         declare      
            use Pace.XML;

            FM_Cmd : constant String := 
               "NATO_ABK.DISPATCHER.FM?set=" & T("xml", 
                                                T("projo", Projo) &
                                                T("fuze", Fuze) &
                                                T("unit", Unit) &
                                                T("vehicle", Vehicle) &
                                                T("zone", Zone) &
                                                T("extent",
                                                  T("sw_easting", SW_Extent.E) &
                                                  T("sw_northing", SW_Extent.N) &
                                                  T("ne_easting", NE_Extent.E) &
                                                  T("ne_northing", NE_Extent.N)) &
                                                T("src",
                                                  T("source_easting", Src.E) &
                                                  T("source_northing", Src.N) &
                                                  T("source_altitude", Src.Alt)) &
                                                T("tgt",
                                                  T("target_easting", Tgt.E) &
                                                  T("target_northing", Tgt.N) &
                                                  T("target_altitude", Tgt.Alt)) 
                                                );
         begin
            Pace.Log.Put_Line ("GETTING BALLISTIC SOLUTION");
            Pace.Log.Put_Line (FM_Cmd);
            declare
               S : constant String :=  Pace.Tcp.Http.Get
                   (Host => Server,
                    Port => Port,
                    Item => FM_Cmd);
            begin
               Pace.Log.Put_Line ("RESULT:" & S);
               El := ToF (Pace.Xml.Search_Xml(S, "el"));
               Az := ToF (Pace.Xml.Search_Xml(S, "az"));
               Prop := Integer'Value (Pace.Xml.Search_Xml(S, "prop"));
               Setting := Duration (ToF (Pace.Xml.Search_Xml(S, "setting")));
               Charge := Integer'Value (Pace.Xml.Search_Xml(S, "charge"));
            end;
            Pace.Log.Put_Line ("E" & El'Img);
            Pace.Log.Put_Line ("A" & Az'Img);
            Pace.Log.Put_Line ("P" & Prop'Img);
            Pace.Log.Put_Line ("S" & Setting'Img);
            Pace.Log.Put_Line ("C" & Charge'Img);
         end;
      else
         El := 0.0;
         Az := 0.0;
         Prop := 231;
         Setting := 0.0;
         Charge := 0;
      end if;
   end;
                 

end PBM.NABK;
