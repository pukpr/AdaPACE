with System;
package C.Libgcc is
   -- extern "C" { 
   -- void __gnat_install_locks (void (*lock) (void), void (*unlock) (void)) 
   -- {
   -- }
   procedure Locks (Lock, Unlock : System.Address);
   pragma Export (C, Locks, "__gnat_install_locks");
end;
