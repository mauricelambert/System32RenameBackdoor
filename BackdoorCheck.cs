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
            } else if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "sethc.exe"))) {
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
