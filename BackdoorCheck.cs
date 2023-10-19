// This file implements a check on System32 executable
// files for backdoor by renamed file

/*
    Copyright (C) 2023  Maurice Lambert
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

using System;
using System.IO;
using System.Diagnostics;
using System.Text.RegularExpressions;

namespace BackdoorCheck
{
    public class BackdoorCheck
    {
        public static string GetCompiledFilename(string filename)
        {
            filename = FileVersionInfo.GetVersionInfo(filename).OriginalFilename;
            if (filename == null)
            {
                return "";
            }
            return filename;
        }

        private static string SanitizeFileName(string filename)
        {
            string invalidCharacters = Regex.Escape(new string(System.IO.Path.GetInvalidFileNameChars()));
            string invalidRegex = string.Format(@"([{0}]*\.+$)|([{0}]+)", invalidCharacters);
            return Regex.Replace(filename, invalidRegex, "");
        }

        private static bool CompareFilename(string filename1, string filename2)
        {
            filename2 = Path.GetFileNameWithoutExtension(SanitizeFileName(filename2)).ToUpper();
            filename1 = Path.GetFileNameWithoutExtension(SanitizeFileName(filename1)).ToUpper();
            return filename1.Contains(filename2) || filename2.Contains(filename1);
        }

        public static bool FileIsBackdoored(string filename)
        {
            return !CompareFilename(GetCompiledFilename(filename), Path.GetFileName(filename));
        }

        public static bool System32IsBackdoored()
        {
            DirectoryInfo system32_folder = new DirectoryInfo(Environment.SystemDirectory);

            foreach (FileInfo file in system32_folder.GetFiles("*.exe"))
            {
                if (FileIsBackdoored(file.FullName))
                {
                    return true;
                }
            }

            return false;
        }

        public static bool CmdIsBackdoored()
        {

            if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "cmd.exe"))) {
                return true;
            } else if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "utilman.exe"))) {
                return true;
            }

            return FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "osk.exe"));
        }

        static void Main(string[] args)
        {
            if (CmdIsBackdoored()) {
                Console.WriteLine("This system is backdoored !");
            } else {
                Console.WriteLine("This system is not backdoored.");
            }
        }
    }
}
