with Pace.Tcp.Http;
with Pace.Xml;
with Pace.Strings;
with Pace.Log;
with Ada.Numerics.Elementary_Functions;

package body PBM.Solver is

   Server : constant String := Pace.Getenv ("TRAJ_SERVER", "");
   Port : constant Integer := Pace.Getenv ("TRAJ_SERVER_PORT", 5651);

   function Is_Using_External_Server return Boolean is
   begin
      return Server /= "";
   end Is_Using_External_Server;


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


   procedure Compute (Item_Type, Mode, Unit, Vehicle: in String;
                      Zone : in Integer;
                      SW_Extent, NE_Extent : in UTM;
                      Src, Tgt : in UTM;
                      El, Az : out Float;
                      Config_Value : out Integer;
                      Setting : out Duration;
                      Power_Level : out Integer) is
   begin
      if Is_Using_External_Server then
         declare
            use Pace.XML;

            -- External server API endpoint and XML field names below must remain
            -- unchanged for compatibility with the remote trajectory calculation server.
            Query_Cmd : constant String :=
               "NATO_ABK.DISPATCHER.FM?set=" & T("xml",
                                                T("projo", Item_Type) &
                                                T("fuze", Mode) &
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
            Pace.Log.Put_Line (Query_Cmd);
            declare
               S : constant String :=  Pace.Tcp.Http.Get
                   (Host => Server,
                    Port => Port,
                    Item => Query_Cmd);
            begin
               Pace.Log.Put_Line ("RESULT:" & S);
               El := ToF (Pace.Xml.Search_Xml(S, "el"));
               Az := ToF (Pace.Xml.Search_Xml(S, "az"));
               Config_Value := Integer'Value (Pace.Xml.Search_Xml(S, "prop"));
               Setting := Duration (ToF (Pace.Xml.Search_Xml(S, "setting")));
               Power_Level := Integer'Value (Pace.Xml.Search_Xml(S, "charge"));
            end;
            Pace.Log.Put_Line ("E" & El'Img);
            Pace.Log.Put_Line ("A" & Az'Img);
            Pace.Log.Put_Line ("P" & Config_Value'Img);
            Pace.Log.Put_Line ("S" & Setting'Img);
            Pace.Log.Put_Line ("C" & Power_Level'Img);
         end;
      else
         El := 0.0;
         Az := 0.0;
         Config_Value := 231;
         Setting := 0.0;
         Power_Level := 0;
      end if;
   end;


end PBM.Solver;
