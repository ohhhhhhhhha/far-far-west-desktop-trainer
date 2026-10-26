using System;
using System.Windows.Forms;

namespace FFWTrainerGui
{
    internal static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            string requestedRoot = null;
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--game-root" && i + 1 < args.Length) requestedRoot = args[++i];
                else
                {
                    MessageBox.Show("用法 / Usage:\nFFWTrainer.exe [--game-root \"game folder\"]", "Far Far West", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
            }
            try
            {
                var preferences = UserPreferences.Load(UserPreferences.DefaultPath);
                string root = requestedRoot == null
                    ? GamePaths.FindRoot(AppDomain.CurrentDomain.BaseDirectory, preferences.gameRoot, Environment.CurrentDirectory)
                    : GamePaths.FindRoot(requestedRoot);
                var controller = new TrainerController(GamePaths.CreateClient(root), CardCatalog.Load());
                controller.SetOfflineLanguage(preferences.offlineLanguage);
                using (var form = new MainForm(controller, root, preferences, UserPreferences.DefaultPath)) Application.Run(form);
            }
            catch (Exception e)
            {
                MessageBox.Show("无法打开工具 / Cannot open the trainer:\n" + e.Message, "Far Far West", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
