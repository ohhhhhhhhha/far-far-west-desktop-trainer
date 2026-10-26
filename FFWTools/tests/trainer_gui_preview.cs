using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using FFWTrainerGui;

internal static class TrainerGuiPreview
{
    static void Handles(Control control) { IntPtr handle=control.Handle; foreach(Control child in control.Controls) Handles(child); }
    static void Click(MainForm form,string name)
    {
        typeof(Button).GetMethod("OnClick",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(form.Controls.Find(name,true)[0],new object[] {EventArgs.Empty});
    }
    static void Save(MainForm form,string output)
    {
        form.PerformLayout();
        using(var image=new Bitmap(form.Width,form.Height)) { form.DrawToBitmap(image,new Rectangle(Point.Empty,form.Size)); image.Save(output,ImageFormat.Png); }
        Console.WriteLine(output);
    }
    [STAThread]
    static int Main(string[] args)
    {
        Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
        string output=Path.GetFullPath(args[0]); Directory.CreateDirectory(output);
        string fixture=Path.Combine(Path.GetTempPath(),"FFWTrainerGui-preview-"+Guid.NewGuid().ToString("N")); Directory.CreateDirectory(fixture);
        try {
            foreach(string lang in new string[] {"zh","en"}) {
                double now=FileBridgeClient.UnixNow();
                var state=new BridgeState {protocol=1,session="preview-session",updatedAt=now,language=lang,connected=true,canApply=true,canSpawn=true,
                    messageZh="已进入酒馆，可修改进度",messageEn="In the saloon. Progress changes are available.",
                    entries=new List<ProgressEntry> {
                        new ProgressEntry {id="gold",category="resource",nameZh="金币",nameEn="Gold",min=0,max=9999999,value=2480,available=true},
                        new ProgressEntry {id="souls",category="resource",nameZh="灵魂",nameEn="Souls",min=0,max=9999999,value=125,available=true},
                        new ProgressEntry {id="blueprints",category="resource",nameZh="蓝图",nameEn="Blueprints",min=0,max=9999999,value=34,available=true},
                        new ProgressEntry {id="heroLevel",category="level",nameZh="角色等级",nameEn="Character level",min=1,max=100,value=12,available=true},
                        new ProgressEntry {id="magicLevel",category="magic",nameZh="魔法等级",nameEn="Magic level",min=1,max=100,value=7,available=true}
                    },unlimited=new UnlimitedState {enabled=false,active=false,messageZh="总点数限制：已启用原版限制",messageEn="Total point budget: original limit is active"}};
                File.WriteAllText(Path.Combine(fixture,"state.json"),new JavaScriptSerializer().Serialize(state));
                var client=new FileBridgeClient(fixture,delegate {return now;},Guid.NewGuid().ToString("N")); client.Poll();
                var controller=new TrainerController(client,CardCatalog.Load()); controller.SetOfflineLanguage(lang); controller.Refresh();
                using(var form=new MainForm(controller,"E:\\SteamLibrary\\steamapps\\common\\FarFarWest",new UserPreferences {offlineLanguage=lang},Path.Combine(fixture,"preferences.json"))) {
                    form.ShowInTaskbar=false; Handles(form);
                    var list=(ListView)form.Controls.Find("entryList",true)[0]; list.Items[0].Selected=true;
                    ((TextBox)form.Controls.Find("targetValue",true)[0]).Text="5000";
                    Save(form,Path.Combine(output,"preview-"+lang+"-resources.png"));
                    Click(form,"nav_cards"); list.Items[0].Selected=true;
                    Save(form,Path.Combine(output,"preview-"+lang+"-cards.png"));
                    Click(form,"nav_settings"); Save(form,Path.Combine(output,"preview-"+lang+"-settings.png"));
                }
            }
            return 0;
        }
        finally { if(Directory.Exists(fixture)) Directory.Delete(fixture,true); }
    }
}
