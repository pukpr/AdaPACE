separate (Hal.Ctdb)
procedure Linkage is
   -- Location of archive files relative to typical build location
   CTDB_DIR : constant String := "Common/utils/geography/ctdb/lib/Linux";
   
   -- Location of archive files relative to typical build location
   pragma Linker_Options ("-L../../../../" & CTDB_DIR);
   -- and atypical build location(s)
   pragma Linker_Options ("-L../../../../../" & CTDB_DIR);
   pragma Linker_Options ("-L../../../../../../" & CTDB_DIR);

   pragma Linker_Options ("-lctdb");
   pragma Linker_Options ("-lm");
--   pragma Linker_Options ("-lgcs");
   pragma Linker_Options ("-lgtrs");
   pragma Linker_Options ("-lworld");
   pragma Linker_Options ("-lcoordinates");
   pragma Linker_Options ("-lgcs");
--   pragma Linker_Options ("-lgeotrans");
   pragma Linker_Options ("-lgeometry");
   pragma Linker_Options ("-lreader");
   pragma Linker_Options ("-lvecmat");
--   pragma Linker_Options ("-lm");
   pragma Linker_Options ("-lz");
   pragma Linker_Options ("-lcmdline");
begin
   null;
end;
