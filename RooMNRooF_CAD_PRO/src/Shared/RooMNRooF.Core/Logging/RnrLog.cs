using System;
using System.IO;
using System.Text.RegularExpressions;

namespace RooMNRooF.Core.Logging
{
    /// <summary>
    /// Thread-safe file logger writing %APPDATA%\RooMNRooF\Logs\RooMNRooF.log (rolls at 5 MB).
    /// Messages are scrubbed of anything that looks like a password/token.
    /// </summary>
    public static class RnrLog
    {
        static readonly object Gate = new();
        static readonly Regex Secret = new(@"(?i)(password|pwd|token|secret|apikey)\s*[=:]\s*\S+");
        public static string LogDirectory { get; set; } =
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "RooMNRooF", "Logs");
        public static string LogFile => Path.Combine(LogDirectory, "RooMNRooF.log");
        public const long MaxBytes = 5 * 1024 * 1024;

        public static void Info(string msg) => Write("INFO", msg);
        public static void Warn(string msg) => Write("WARN", msg);
        public static void Error(string msg, Exception? ex = null) => Write("ERROR", ex == null ? msg : $"{msg} :: {ex.GetType().Name}: {ex.Message}\n{ex.StackTrace}");
        public static void Command(string name, string outcome) => Write("CMD", $"{name} -> {outcome}");

        public static string Scrub(string s) => Secret.Replace(s, m => m.Groups[1].Value + "=***");

        static void Write(string level, string msg)
        {
            try
            {
                lock (Gate)
                {
                    Directory.CreateDirectory(LogDirectory);
                    var f = new FileInfo(LogFile);
                    if (f.Exists && f.Length > MaxBytes)
                    {
                        var old = LogFile + ".1";
                        if (File.Exists(old)) File.Delete(old);
                        File.Move(LogFile, old);
                    }
                    File.AppendAllText(LogFile, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} [{level}] {Scrub(msg)}{Environment.NewLine}");
                }
            }
            catch
            {
                // logging must never crash AutoCAD
            }
        }
    }
}
