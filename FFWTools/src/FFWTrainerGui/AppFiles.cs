using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;
using System.Web.Script.Serialization;

namespace FFWTrainerGui
{
    public static class GamePaths
    {
        public static string Mods(string root) { return Path.Combine(root, "FarFarWest", "Binaries", "Win64", "ue4ss", "Mods"); }
        public static string Data(string root) { return Path.Combine(Mods(root), "FFWTrainer", "Data"); }
        public static string FindRoot(params string[] candidates)
        {
            foreach (string candidate in candidates)
            {
                if (String.IsNullOrWhiteSpace(candidate)) continue;
                try
                {
                    var current = new DirectoryInfo(Path.GetFullPath(candidate));
                    while (current != null)
                    {
                        if (Directory.Exists(Mods(current.FullName))) return current.FullName;
                        current = current.Parent;
                    }
                }
                catch (Exception) { }
            }
            return null;
        }
        public static FileBridgeClient CreateClient(string root)
        {
            if (root == null || !Directory.Exists(Path.Combine(Mods(root), "FFWTrainer"))) return null;
            return new FileBridgeClient(Data(root), FileBridgeClient.UnixNow, Guid.NewGuid().ToString("N"));
        }
    }
    public sealed class UserPreferences
    {
        public string gameRoot { get; set; }
        public string offlineLanguage { get; set; }
        public static string DefaultPath
        {
            get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "FFWTools", "trainer-user.json"); }
        }
        public static UserPreferences Load(string path)
        {
            UserPreferences result = null;
            try { if (File.Exists(path)) result = new JavaScriptSerializer().Deserialize<UserPreferences>(File.ReadAllText(path, Encoding.UTF8)); }
            catch (Exception) { }
            result = result ?? new UserPreferences();
            if (result.offlineLanguage != "zh" && result.offlineLanguage != "en")
                result.offlineLanguage = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "zh" ? "zh" : "en";
            return result;
        }
        public void Save(string path)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            string temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
            try
            {
                File.WriteAllText(temporary, new JavaScriptSerializer().Serialize(this), new UTF8Encoding(false));
                if (File.Exists(path)) File.Replace(temporary, path, null); else File.Move(temporary, path);
            }
            finally { if (File.Exists(temporary)) File.Delete(temporary); }
        }
    }
    public static class CardCatalog
    {
        public static List<CardEntry> Load()
        {
            using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("FFWTrainerGui.catalog.json"))
            {
                if (stream == null) throw new InvalidDataException("The embedded card catalog is missing.");
                using (var reader = new StreamReader(stream, Encoding.UTF8))
                    return new JavaScriptSerializer().Deserialize<List<CardEntry>>(reader.ReadToEnd());
            }
        }
    }
}
