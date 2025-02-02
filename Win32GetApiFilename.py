#!/usr/bin/env python3
# -*- coding: utf-8 -*-

###################
#    This script calls the Win 32 API to print the OriginalFilename from PE executable.
#    Copyright (C) 2023, 2025  Maurice Lambert

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
###################

"""
This script calls the Win 32 API to print the OriginalFilename from PE executable.
"""

__version__ = "0.0.1"
__author__ = "Maurice Lambert"
__author_email__ = "mauricelambert434@gmail.com"
__maintainer__ = "Maurice Lambert"
__maintainer_email__ = "mauricelambert434@gmail.com"
__description__ = """
This script calls the Win 32 API to print the OriginalFilename from PE executable.
"""
__url__ = "https://github.com/mauricelambert/System32RenameBackdoor"

# __all__ = []

__license__ = "GPL-3.0 License"
__copyright__ = """
System32RenameBackdoor  Copyright (C) 2023, 2025  Maurice Lambert
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.
"""
copyright = __copyright__
license = __license__

print(copyright)

from ctypes import wintypes, windll, create_string_buffer, c_wchar_p, c_void_p, byref, c_wchar_p, wstring_at, string_at
from ctypes.wintypes import UINT
import struct

def get_original_filename(file_path: str) -> str:
    """
    This function returns the OriginalFilename
    """

    version_dll = windll.version
    size = version_dll.GetFileVersionInfoSizeW(file_path, None)
    if size == 0:
        return None

    buffer = create_string_buffer(size)
    if not version_dll.GetFileVersionInfoW(file_path, 0, size, buffer):
        return None

    sub_block = c_wchar_p("\\VarFileInfo\\Translation")
    ret_ptr = c_void_p()
    ret_len = wintypes.UINT()
    if not version_dll.VerQueryValueW(buffer, sub_block, byref(ret_ptr), byref(ret_len)):
        return None

    lang_and_codepage = struct.unpack('HH', string_at(ret_ptr.value, ret_len.value))
    lang, codepage = lang_and_codepage
    query = f"\\StringFileInfo\\{lang:04x}{codepage:04x}\\OriginalFilename"
    sub_block = c_wchar_p(query)
    if not version_dll.VerQueryValueW(buffer, sub_block, byref(ret_ptr), byref(ret_len)):
        return None

    original_filename = wstring_at(ret_ptr.value, ret_len.value - 1)
    return original_filename

if __name__ == "__main__":
    file_path = r"C:\Windows\System32\Magnify.exe"
    result = get_original_filename(file_path)
    if result:
        print(f"Original Filename: {result}")
    else:
        print("Failed to get Original Filename")
