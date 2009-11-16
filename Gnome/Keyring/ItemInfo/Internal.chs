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
{-# LANGUAGE MultiParamTypeClasses #-}
#include <gnome-keyring.h>
{# context prefix = "gnome_keyring_" #}

module Gnome.Keyring.ItemInfo.Internal where
import Data.Text.Lazy (Text)
import Control.Exception (bracket)
import Foreign
import Foreign.C
import Gnome.Keyring.FFI

{# enum GnomeKeyringItemType as RawType {} deriving (Show) #}

data ItemType
	= ItemGenericSecret
	| ItemNetworkPassword
	| ItemNote
	| ItemChainedKeyringPassword
	| ItemEncryptionKeyPassword
	| ItemPublicKeyStorage
	deriving (Show, Eq)

fromItemType :: ItemType -> CInt
fromItemType = fromIntegral . fromEnum . toRaw where
	toRaw ItemGenericSecret = ITEM_GENERIC_SECRET
	toRaw ItemNetworkPassword = ITEM_NETWORK_PASSWORD
	toRaw ItemNote = ITEM_NOTE
	toRaw ItemChainedKeyringPassword = ITEM_CHAINED_KEYRING_PASSWORD
	toRaw ItemEncryptionKeyPassword = ITEM_ENCRYPTION_KEY_PASSWORD
	toRaw ItemPublicKeyStorage = ITEM_PK_STORAGE

toItemType :: RawType -> ItemType
toItemType ITEM_GENERIC_SECRET = ItemGenericSecret
toItemType ITEM_NETWORK_PASSWORD = ItemNetworkPassword
toItemType ITEM_NOTE = ItemNote
toItemType ITEM_CHAINED_KEYRING_PASSWORD = ItemChainedKeyringPassword
toItemType ITEM_ENCRYPTION_KEY_PASSWORD = ItemEncryptionKeyPassword
toItemType ITEM_PK_STORAGE = ItemPublicKeyStorage
toItemType x = error $ "Unknown item type: " ++ show x

-- | Note: setting mtime and ctime will not affect the keyring
data ItemInfo = ItemInfo
	{ itemType        :: ItemType
	, itemSecret      :: Text
	, itemDisplayName :: Text
	, itemMTime       :: Integer -- TODO: TimeOfDay
	, itemCTime       :: Integer -- TODO: TimeOfDay
	}
	deriving (Show, Eq)

peekItemInfo :: Ptr () -> IO ItemInfo
peekItemInfo info = do
	cType <- {# call item_info_get_type #} info
	secret <- stealText =<< {# call item_info_get_secret #} info
	name <- stealText =<< {# call item_info_get_display_name #} info
	mtime <- toInteger `fmap` {# call item_info_get_mtime #} info
	ctime <- toInteger `fmap` {# call item_info_get_ctime #} info
	let type' = toItemType . toEnum . fromIntegral $ cType
	return $ ItemInfo type' secret name mtime ctime

stealItemInfo :: Ptr (Ptr ()) -> IO ItemInfo
stealItemInfo ptr = bracket (peek ptr) freeItemInfo peekItemInfo

freeItemInfo :: Ptr () -> IO ()
freeItemInfo = {# call item_info_free #}

foreign import ccall "gnome-keyring.h &gnome_keyring_item_info_free"
	finalizeItemInfo :: FunPtr (Ptr a -> IO ())

withItemInfo :: ItemInfo -> (Ptr () -> IO a) -> IO a
withItemInfo info io = do
	fptr <- newForeignPtr finalizeItemInfo =<< {# call item_info_new #}
	withForeignPtr fptr $ \ptr -> do
	{# call item_info_set_type #} ptr . fromItemType . itemType $ info
	withText (itemSecret info) $ {# call item_info_set_secret #} ptr
	withText (itemDisplayName info) $ {# call item_info_set_display_name #} ptr
	io ptr
