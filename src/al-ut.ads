-- ----------------------------------------------------------------------------
------------------------------------------
-- ****************************************************************************
--****************************************
-- ----------------------------------------------------------------------------
------------------------------------------
--
-- PACKAGE NAME   - Alut
--(OpenALada - Ada binding to OpenAL)
--
-- DESCRIPTION    - This file implements the OpenAL "Alut.h" and "Aluttypes.h"
--headers.
--
-- REFERENCE      - For information about OpenAL visit: www.openAL.org
--
-- COPYRIGHT      - (C) 2005 Dr.Aurele Vitali, All Rights Reserved -
--www.OpenALada.com
--
--                   Revision |   Date    | Description
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.0    | 22 Jan 05 | Initial Release, Aurele Vitali
--<aurele.vitali@gmail.com>
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.0a   | 23 Jan 05 | Released under "GNAT-Modified GPL".
--                  ----------+-----------+------------------------------------
------------------------------------------
--                     1.1    | 03 Mar 05 | Changes by Martin Dowie
--<martin.dowie@btopenworld.com>
--                            |           |
--                            |           | a) Removed Pragma
--"Linker_Options(...)"
--                            |           | b) Included Pragma
--"Preelaborate(...)"
--                            |           | c) Removed "To_String" and
--"To_lpStr" functions
--                            |           | d) Removed package body (i.e. the
--"To_String" and "To_lpStr" functions)
--                            |           | e) Saved file as an Ada
--specification (.ads)
--                  ----------+-----------+------------------------------------
------------------------------------------
--                            |           |
--                  ----------+-----------+------------------------------------
------------------------------------------
--                            |           |
--                  ----------+-----------+------------------------------------
------------------------------------------
--
-- This program is free software; you can redistribute it and/or  modify  it
--under the  terms of the GNU General Public
-- License as published by the Free Software Foundation; either version 2 of
--the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
--ANY WARRANTY;  without  even the  implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more
-- details.
--
-- You should have received a copy of the  GNU  General  Public  License
--along with this program; if not, write to the
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
--02111-1307, USA.
--
-- ----------------------------------------------------------------------------
------------------------------------------
-- ****************************************************************************
--****************************************
-- ----------------------------------------------------------------------------
------------------------------------------

with Al;

package Al.ut is

   pragma Preelaborate (Al.ut);

   AL_PROVIDES_ALUT : constant := 1;

   -- -------------------------------------------------------------------------
   -------------------------------------------
   -- Alut API
   -- -------------------------------------------------------------------------
   -------------------------------------------

   procedure alutInit (argc : Al.lpALint; argv : access Al.lpALchar);

   procedure alutExit;

   procedure alutLoadWAVFile
     (file   : Al.lpALstr;
      format : Al.lpALenum;
      data   : access Al.lpALvoid;
      size   : Al.lpALsizei;
      freq   : Al.lpALsizei;
      sloop  : Al.lpALboolean);

   procedure alutLoadWAVMemory
     (memory : Al.lpALbyte;
      format : Al.lpALenum;
      data   : access Al.lpALvoid;
      size   : Al.lpALsizei;
      freq   : Al.lpALsizei;
      sloop  : Al.lpALboolean);

   procedure alutUnloadWAV
     (format : Al.ALenum;
      data   : Al.lpALvoid;
      size   : Al.ALsizei;
      freq   : Al.ALsizei);
private

   pragma Import (C, alutInit, "alutInit");
   pragma Import (C, alutExit, "alutExit");
   pragma Import (C, alutLoadWAVFile, "alutLoadWAVFile");
   pragma Import (C, alutLoadWAVMemory, "alutLoadWAVMemory");
   pragma Import (C, alutUnloadWAV, "alutUnloadWAV");

end Al.ut;
