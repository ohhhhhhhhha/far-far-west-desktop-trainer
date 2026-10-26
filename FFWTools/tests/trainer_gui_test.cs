using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using System.Web.Script.Serialization;
using FFWTrainerGui;

internal static class TrainerGuiTests
{
    static readonly JavaScriptSerializer Json = new JavaScriptSerializer();
    static int passed, failed;
    static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    static void Test(string name, Action body)
    {
        try { body(); passed++; Console.WriteLine("PASS " + name); }
        catch (Exception e) { failed++; Console.WriteLine("FAIL " + name + ": " + e.Message); }
    }
    sealed class Fixture : IDisposable
    {
        public readonly string Path = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "FFWTrainerGui-tests-" + Guid.NewGuid().ToString("N"));
        public double Now = 1000;
        public readonly FileBridgeClient Client;
        public readonly TrainerController Controller;
        public Fixture()
        {
            Directory.CreateDirectory(Path);
            Client = new FileBridgeClient(Path, delegate { return Now; }, "test-client");
            Controller = new TrainerController(Client, new List<CardEntry> {
                new CardEntry { id="joker_fire", nameZh="烈焰", nameEn="Wild Fire", descriptionZh="火焰伤害", descriptionEn="Fire damage" },
                new CardEntry { id="joker_ice", nameZh="寒冰", nameEn="Cold Front", descriptionZh="冰霜伤害", descriptionEn="Ice damage" }
            });
        }
        public void State(string session, string language, string resultId)
        {
            var state = new BridgeState { protocol=1, session=session, updatedAt=Now, language=language,
                connected=true, canApply=true, canSpawn=true, messageZh="可修改", messageEn="Ready",
                entries=new List<ProgressEntry> {
                    new ProgressEntry { id="gold",category="resource",nameZh="金币",nameEn="Gold",min=0,max=9999999,value=25,available=true },
                    new ProgressEntry { id="souls",category="resource",nameZh="灵魂",nameEn="Souls",min=0,max=9999999,value=7,available=true },
                    new ProgressEntry { id="magic",category="magic",nameZh="法术",nameEn="Magic",min=1,max=100,available=false }
                }, unlimited=new UnlimitedState { enabled=false,active=false,messageZh="关闭",messageEn="Off" },
                lastResult=resultId == null ? null : new CommandResult {requestId=resultId,success=true,messageZh="已保存",messageEn="Saved"}
            };
            File.WriteAllText(System.IO.Path.Combine(Path,"state.json"), Json.Serialize(state));
        }
        public void Poll() { Client.Poll(); Controller.Refresh(); }
        public Dictionary<string, object> Read(string name) { return Json.Deserialize<Dictionary<string, object>>(File.ReadAllText(System.IO.Path.Combine(Path,name))); }
        public void Dispose() { Client.Dispose(); if (Directory.Exists(Path)) Directory.Delete(Path,true); }
    }
    static void CreateHandles(Control control)
    {
        IntPtr handle=control.Handle;
        foreach(Control child in control.Controls) CreateHandles(child);
    }
    [STAThread]
    static int Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Test("real file heartbeat is spaced by two seconds", delegate {
            using(var f=new Fixture()) {
                f.Client.SelectedCardId="joker_fire"; f.Poll();
                Check(File.Exists(System.IO.Path.Combine(f.Path,"client.json")),"first poll must write heartbeat");
                var first=f.Read("client.json");
                Check((string)first["clientId"]=="test-client" && Convert.ToInt32(first["protocol"])==1,"heartbeat identity");
                Check((string)first["selectedCardId"]=="joker_fire","selected card heartbeat");
                f.Now=1001; f.Poll(); Check(Convert.ToDouble(f.Read("client.json")["updatedAt"])==1000,"heartbeat should not write every tick");
                f.Now=1002; f.Poll(); Check(Convert.ToDouble(f.Read("client.json")["updatedAt"])==1002,"heartbeat must refresh at two seconds");
            }
        });
        Test("state freshness disables writes and preserves unknown values", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll();
                Check(f.Client.IsConnected,"fresh state should connect");
                Check(f.Client.State.entries[2].value==null,"unknown must remain absent");
                f.Controller.SelectProgress("magic"); Check(!f.Controller.Apply(f.Controller.Binding,"5"),"unavailable entry must reject writes");
                f.Now=1007; f.Poll(); Check(!f.Client.IsConnected,"state older than six seconds must disconnect");
                f.Controller.SelectProgress("gold"); Check(!f.Controller.Apply(f.Controller.Binding,"50"),"stale state must reject writes");
                Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"invalid operation must not produce command");
            }
        });
        Test("command identity and single pending slot survive repeated clicks", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectProgress("gold");
                var binding=f.Controller.Binding; Check(f.Controller.Apply(binding,"42"),"explicit apply should write");
                var cmd=f.Read("command.json"); var payload=(Dictionary<string,object>)cmd["payload"];
                Check((string)cmd["session"]=="session-a" && (string)cmd["clientId"]=="test-client","command must bind session and client");
                Check((string)cmd["action"]=="setProgress" && (string)payload["id"]=="gold" && payload["value"] is string && (string)payload["value"]=="42","narrow string payload");
                string request=(string)cmd["requestId"]; Check(!f.Controller.Apply(binding,"43"),"second pending apply must fail");
                Check((string)f.Read("command.json")["requestId"]==request,"pending file must not be overwritten");
                f.Now++; f.State("session-a","en",request); f.Poll(); Check(f.Client.Pending==null,"matching acknowledgment clears pending");
                f.Now++; f.State("session-a","en",request); f.Poll(); Check(f.Client.Pending==null,"acknowledgment never resends command");
            }
        });
        Test("new session cancels old action and invalidates old editor binding", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectProgress("gold");
                var oldBinding=f.Controller.Binding; Check(f.Controller.Apply(oldBinding,"42"),"initial apply"); string oldRequest=f.Client.Pending.requestId;
                f.Now++; f.State("session-b","en",oldRequest); f.Poll(); Check(f.Client.Pending==null,"session replacement cancels pending");
                Check(!f.Controller.Apply(oldBinding,"43"),"old editor cannot apply in new session");
                f.Controller.SelectProgress("gold"); Check(f.Controller.Apply(f.Controller.Binding,"44"),"new explicit apply allowed");
                string newRequest=f.Client.Pending.requestId; f.Now++; f.State("session-b","en",oldRequest); f.Poll();
                Check(f.Client.Pending!=null && f.Client.Pending.requestId==newRequest,"old acknowledgment cannot clear current pending command");
                Check((string)f.Read("command.json")["session"]=="session-b","new command must use current session");
            }
        });
        Test("expired pending action is never replayed", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectProgress("gold");
                Check(f.Controller.Apply(f.Controller.Binding,"42"),"initial apply");
                f.Now=1011; f.State("session-a","en",null); f.Poll(); Check(f.Client.Pending==null,"pending command must expire");
                Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"own expired command must be removed");
                f.Now=1012; f.State("session-a","en",null); f.Poll(); Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"poll must not retry an expired mutation");
            }
        });
        Test("disconnect cancels command without replay on reconnect", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectProgress("gold");
                Check(f.Controller.Apply(f.Controller.Binding,"42"),"initial apply"); f.Now=1007; f.Poll();
                Check(f.Client.Pending==null,"disconnection cancels pending");
                f.Now=1008; f.State("session-a","en",null); f.Poll(); Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"reconnection must not restore cancelled command");
            }
        });
        Test("selection search and language changes invalidate target input", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectProgress("gold"); var gold=f.Controller.Binding;
                f.Controller.SelectProgress("souls"); Check(!f.Controller.Apply(gold,"99"),"gold draft must not apply to souls");
                var souls=f.Controller.Binding; f.Controller.SetSearch("gold"); Check(!f.Controller.Apply(souls,"99"),"filter change must invalidate old editor");
                f.Controller.SelectProgress("gold"); var english=f.Controller.Binding; f.Now++; f.State("session-a","zh",null); f.Poll();
                Check(!f.Controller.Apply(english,"99"),"game language change must invalidate old editor");
                Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"stale input must never write");
            }
        });
        Test("catalog searches both names and IDs while offline", delegate {
            using(var f=new Fixture()) {
                Check(f.Controller.FindCards("烈焰").Count==1,"Chinese name searchable");
                Check(f.Controller.FindCards("WILD").Count==1,"English name searchable ignoring case");
                Check(f.Controller.FindCards("JOKER_ICE")[0].id=="joker_ice","ID searchable ignoring case");
                f.Controller.SelectCard("joker_fire"); Check(!f.Controller.Spawn(),"offline card selection must not spawn");
                Check(!File.Exists(System.IO.Path.Combine(f.Path,"command.json")),"offline catalog is read only");
            }
        });
        Test("card spawn needs an explicit current selection", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll(); f.Controller.SelectCard("joker_fire"); f.Controller.SetSearch("ice");
                Check(!f.Controller.Spawn(),"search must clear old card selection");
                f.Controller.SelectCard("joker_ice"); Check(f.Controller.Spawn(),"explicit spawn of current selection");
                var cmd=f.Read("command.json"); Check((string)cmd["action"]=="spawn" && (string)((Dictionary<string,object>)cmd["payload"])["id"]=="joker_ice","spawn must use selected card ID");
            }
        });
        Test("live command from another client is not overwritten", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll();
                File.WriteAllText(System.IO.Path.Combine(f.Path,"command.json"),"{\"protocol\":1,\"clientId\":\"other\",\"session\":\"session-a\",\"requestId\":\"busy\",\"createdAt\":1000,\"action\":\"spawn\",\"payload\":{\"id\":\"joker_fire\"}}");
                f.Controller.SelectProgress("gold"); Check(!f.Controller.Apply(f.Controller.Binding,"42"),"live slot must not be overwritten");
                Check((string)f.Read("command.json")["requestId"]=="busy","other pending command remains unchanged");
            }
        });
        Test("malformed state cannot enable writes", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll();
                File.WriteAllText(System.IO.Path.Combine(f.Path,"state.json"),"{broken"); f.Poll(); Check(!f.Client.IsConnected,"malformed state must disconnect");
                f.Controller.SelectProgress("gold"); Check(!f.Controller.Apply(f.Controller.Binding,"42"),"malformed state cannot authorize apply");
            }
        });
        Test("game root discovery walks ancestors without accepting an unrelated folder", delegate {
            using(var f=new Fixture()) {
                string root=System.IO.Path.Combine(f.Path,"game");
                string mods=System.IO.Path.Combine(root,"FarFarWest","Binaries","Win64","ue4ss","Mods");
                Directory.CreateDirectory(mods);
                string executableFolder=System.IO.Path.Combine(root,"FFWTools","bin"); Directory.CreateDirectory(executableFolder);
                Check(GamePaths.FindRoot(executableFolder)==root,"executable ancestor must identify actual game root");
                Check(GamePaths.FindRoot(f.Path)==null,"unrelated directory must not be accepted");
                Check(GamePaths.FindRoot(f.Path,root)==root,"remembered explicit root must be usable");
            }
        });
        Test("budget toggle writes only the explicit boolean setting", delegate {
            using(var f=new Fixture()) { f.State("session-a","en",null); f.Poll();
                Check(!f.Controller.SetUnlimited(true,"previous-session"),"old settings selection must be rejected");
                Check(f.Controller.SetUnlimited(true,"session-a"),"explicit current toggle must write");
                var cmd=f.Read("command.json"); var payload=(Dictionary<string,object>)cmd["payload"];
                Check((string)cmd["action"]=="setUnlimited" && payload.Count==1 && (bool)payload["enabled"],"toggle must not allocate any attributes");
            }
        });
        Test("changing the game connection binds UI actions to the new client", delegate {
            using(var original=new Fixture()) using(var replacement=new Fixture()) {
                original.State("original","en",null); original.Poll(); replacement.State("replacement","en",null); replacement.Poll();
                using(var form=new MainForm(original.Controller,original.Path,new UserPreferences {offlineLanguage="en"},System.IO.Path.Combine(original.Path,"preferences.json"))) {
                    CreateHandles(form);
                    typeof(MainForm).GetMethod("ReplaceController",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(form,new object[] {replacement.Client});
                    typeof(MainForm).GetMethod("Poll",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(form,null);
                    var list=(ListView)form.Controls.Find("entryList",true)[0]; list.Items[0].Selected=true;
                    var input=(TextBox)form.Controls.Find("targetValue",true)[0]; input.Text="99";
                    Check(input.Enabled,"new connection selection must enable its editor");
                    typeof(Button).GetMethod("OnClick",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(form.Controls.Find("applyProgress",true)[0],new object[] {EventArgs.Empty});
                    Check(replacement.Client.Pending!=null && replacement.Client.Pending.session=="replacement","UI action must reach replacement connection");
                    Check(original.Client.Pending==null,"previous connection must not receive UI actions");
                }
            }
        });
        Console.WriteLine(passed + " passed; " + failed + " failed"); return failed==0 ? 0 : 1;
    }
}
