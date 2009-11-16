{- Copyright (C) 2009 John Millikin <jmillikin@gmail.com>
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
-}

{-# LANGUAGE ForeignFunctionInterface #-}
#include <gnome-keyring.h>
{# context prefix = "gnome_keyring_" #}

module Gnome.Keyring.Misc where
import Gnome.Keyring.Types (CancellationKey (..))

-- Import unqualified for c2hs
import Foreign
import Foreign.C

--available :: IO Bool
{# fun unsafe is_available as available
	{} -> `Bool' toBool #}

unpackKey :: CancellationKey -> Ptr ()
unpackKey (CancellationKey x) = x

{# fun cancel_request as cancel
	{ unpackKey `CancellationKey'
	} -> `()' id #}
