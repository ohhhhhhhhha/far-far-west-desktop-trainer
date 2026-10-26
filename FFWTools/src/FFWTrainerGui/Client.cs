using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

namespace FFWTrainerGui
{
    public sealed class FileBridgeClient : IDisposable
    {
        readonly string directory;
        readonly Func<double> clock;
        readonly JavaScriptSerializer json = new JavaScriptSerializer();
        readonly Mutex slotMutex;
        bool readable, heartbeatHealthy, disposed;
        double lastHeartbeat = Double.NegativeInfinity;
        public BridgeState State { get; private set; }
        public BridgeCommand Pending { get; private set; }
        public string ClientId { get; private set; }
        public Notice Notice { get; private set; }
        public Notice ConnectionProblem { get; private set; }
        public string SelectedCardId { get; set; }
        public string DirectoryPath { get { return directory; } }
        public bool IsConnected
        {
            get { return !disposed && readable && heartbeatHealthy && State != null && State.connected &&
                State.protocol == 1 && !String.IsNullOrWhiteSpace(State.session) &&
                clock() - State.updatedAt <= 6 && clock() - State.updatedAt >= -2; }
        }
        public FileBridgeClient(string directory, Func<double> clock, string clientId)
        {
            this.directory = Path.GetFullPath(directory);
            this.clock = clock;
            ClientId = clientId;
            string hash;
            using (var sha = SHA256.Create())
                hash = BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(this.directory.ToUpperInvariant()))).Replace("-", "");
            slotMutex = new Mutex(false, "Local\\FFWTrainer-" + hash);
        }
        public static double UnixNow()
        {
            return (DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds;
        }
        public void SetNotice(string zh, string en, bool error) { Notice = new Notice(zh, en, error); }
        public void Poll()
        {
            if (disposed) return;
            double now = clock();
            try
            {
                string path = Path.Combine(directory, "state.json");
                if (File.Exists(path))
                {
                    var next = json.Deserialize<BridgeState>(File.ReadAllText(path, Encoding.UTF8));
                    if (next == null || next.protocol != 1 || String.IsNullOrWhiteSpace(next.session) ||
                        (next.language != "zh" && next.language != "en") || Double.IsNaN(next.updatedAt) || Double.IsInfinity(next.updatedAt))
                        throw new InvalidDataException("Unsupported bridge state.");
                    next.entries = next.entries ?? new List<ProgressEntry>();
                    State = next;
                    readable = true;
                }
                else readable = false;
                ConnectionProblem = null;
            }
            catch (Exception)
            {
                readable = false;
                ConnectionProblem = new Notice("无法读取游戏状态。请检查连接组件和目录权限。", "Cannot read game state. Check the connection component and folder permissions.", true);
            }
            if (now - lastHeartbeat >= 2 || now < lastHeartbeat)
            {
                try
                {
                    Directory.CreateDirectory(directory);
                    var heartbeat = new Dictionary<string, object> { { "protocol", 1 }, { "clientId", ClientId }, { "updatedAt", now } };
                    if (!String.IsNullOrEmpty(SelectedCardId)) heartbeat.Add("selectedCardId", SelectedCardId);
                    AtomicWrite("client.json", json.Serialize(heartbeat));
                    lastHeartbeat = now;
                    heartbeatHealthy = true;
                }
                catch (Exception)
                {
                    heartbeatHealthy = false;
                    ConnectionProblem = new Notice("无法写入连接文件。请检查游戏目录权限。", "Cannot write the connection file. Check game-folder permissions.", true);
                }
            }
            if (Pending == null) return;
            if (State != null && State.session != Pending.session)
                CancelPending("游戏会话已变更；未重发上次操作。", "Game session changed; the previous action was not resent.");
            else if (!IsConnected)
                CancelPending("连接中断；上次操作结果未确认，未重发。", "Connection lost; the previous result is unconfirmed and was not resent.");
            else if (State.lastResult != null && State.lastResult.requestId == Pending.requestId)
            {
                Notice = new Notice(State.lastResult.messageZh, State.lastResult.messageEn, !State.lastResult.success);
                Pending = null;
            }
            else if (now - Pending.createdAt > 10 || now < Pending.createdAt - 2)
                CancelPending("操作等待超时；结果未确认，未重发。", "Action timed out; its result is unconfirmed and it was not resent.");
        }
        public bool Send(string action, Dictionary<string, object> payload)
        {
            if (!IsConnected) { SetNotice("请先连接游戏。", "Connect to the game first.", true); return false; }
            if (Pending != null) { SetNotice("请等待当前操作完成。", "Wait for the current action to finish.", true); return false; }
            if (!ValidPayload(action, payload)) { SetNotice("操作参数无效。", "Invalid action parameters.", true); return false; }
            bool entered = false;
            try
            {
                try { entered = slotMutex.WaitOne(0); }
                catch (AbandonedMutexException) { entered = true; }
                if (!entered) { SetNotice("另一个工具正在提交操作，请稍后重试。", "Another tool is submitting an action. Try again shortly.", true); return false; }
                string path = Path.Combine(directory, "command.json");
                if (File.Exists(path))
                {
                    var previous = json.Deserialize<BridgeCommand>(File.ReadAllText(path, Encoding.UTF8));
                    bool acknowledged = previous != null && State.lastResult != null && previous.requestId == State.lastResult.requestId;
                    bool obsolete = previous != null && (previous.session != State.session || clock() - previous.createdAt > 10);
                    if (!acknowledged && !obsolete)
                    {
                        SetNotice("已有操作正在等待游戏确认，请稍后重试。", "An action is waiting for the game to confirm it. Try again shortly.", true);
                        return false;
                    }
                }
                var command = new BridgeCommand { protocol = 1, clientId = ClientId, session = State.session,
                    requestId = Guid.NewGuid().ToString("N"), createdAt = clock(), action = action, payload = payload };
                AtomicWrite("command.json", json.Serialize(command));
                Pending = command;
                SetNotice("已提交，等待游戏确认…", "Submitted; waiting for the game…", false);
                return true;
            }
            catch (Exception)
            {
                SetNotice("无法提交操作。请检查连接文件和目录权限。", "Cannot submit the action. Check connection files and folder permissions.", true);
                return false;
            }
            finally { if (entered) slotMutex.ReleaseMutex(); }
        }
        static bool ValidPayload(string action, Dictionary<string, object> payload)
        {
            if (payload == null) return false;
            object id, value;
            if (action == "setUnlimited") return payload.Count == 1 && payload.TryGetValue("enabled", out value) && value is bool;
            if (!payload.TryGetValue("id", out id) || !(id is string) || String.IsNullOrWhiteSpace((string)id)) return false;
            if (action == "spawn") return payload.Count == 1;
            return action == "setProgress" && payload.Count == 2 && payload.TryGetValue("value", out value) && value is string;
        }
        void AtomicWrite(string name, string contents)
        {
            string path = Path.Combine(directory, name);
            string temporary = path + "." + ClientId + ".tmp";
            try
            {
                File.WriteAllText(temporary, contents, new UTF8Encoding(false));
                if (File.Exists(path)) File.Replace(temporary, path, null);
                else File.Move(temporary, path);
            }
            finally { if (File.Exists(temporary)) File.Delete(temporary); }
        }
        void CancelPending(string zh, string en)
        {
            var cancelled = Pending;
            Pending = null;
            SetNotice(zh, en, true);
            if (cancelled == null) return;
            bool entered = false;
            try
            {
                try { entered = slotMutex.WaitOne(0); }
                catch (AbandonedMutexException) { entered = true; }
                if (!entered) return;
                string path = Path.Combine(directory, "command.json");
                if (!File.Exists(path)) return;
                var stored = json.Deserialize<BridgeCommand>(File.ReadAllText(path, Encoding.UTF8));
                if (stored != null && stored.clientId == ClientId && stored.requestId == cancelled.requestId) File.Delete(path);
            }
            catch (Exception) { }
            finally { if (entered) slotMutex.ReleaseMutex(); }
        }
        public void Dispose()
        {
            if (disposed) return;
            CancelPending("窗口已关闭，未重发操作。", "Window closed; no action was resent.");
            try
            {
                string path = Path.Combine(directory, "client.json");
                if (File.Exists(path))
                {
                    var heartbeat = json.Deserialize<Dictionary<string, object>>(File.ReadAllText(path, Encoding.UTF8));
                    object owner;
                    if (heartbeat != null && heartbeat.TryGetValue("clientId", out owner) && String.Equals(owner as string, ClientId, StringComparison.Ordinal)) File.Delete(path);
                }
            }
            catch (Exception) { }
            disposed = true;
            slotMutex.Dispose();
        }
    }
    public sealed class EditorBinding
    {
        public string Id { get; internal set; }
        public string Session { get; internal set; }
        public string Language { get; internal set; }
    }
    public sealed class TrainerController
    {
        public readonly FileBridgeClient Client;
        public readonly List<CardEntry> Catalog;
        public EditorBinding Binding { get; private set; }
        public string SelectedCardId { get; private set; }
        public string Search { get; private set; }
        public string Language { get; private set; }
        string offlineLanguage = "zh", session;
        bool connected;
        public TrainerController(FileBridgeClient client, List<CardEntry> catalog)
        {
            Client = client; Catalog = catalog; Language = offlineLanguage; Search = "";
        }
        public void Refresh()
        {
            bool live = Client != null && Client.IsConnected;
            string nextSession = live ? Client.State.session : null;
            string nextLanguage = live ? Client.State.language : offlineLanguage;
            if (connected != live || session != nextSession || Language != nextLanguage) ClearSelection();
            connected = live; session = nextSession; Language = nextLanguage;
        }
        public void ClearSelection()
        {
            Binding = null; SelectedCardId = null;
            if (Client != null) Client.SelectedCardId = null;
        }
        public void SelectProgress(string id)
        {
            ClearSelection();
            if (Client == null || Client.State == null) return;
            var entry = Client.State.entries.FirstOrDefault(e => e.id == id);
            if (entry != null) Binding = new EditorBinding { Id = id, Session = session, Language = Language };
        }
        public void SetSearch(string query) { Search = query ?? ""; ClearSelection(); }
        public void SetOfflineLanguage(string language)
        {
            offlineLanguage = language == "en" ? "en" : "zh";
            Refresh();
        }
        public bool Apply(EditorBinding binding, string value)
        {
            if (binding == null || !Object.ReferenceEquals(binding, Binding) || Client == null || !Client.IsConnected ||
                !Client.State.canApply || binding.Session != Client.State.session || binding.Language != Language)
                return Reject("选择当前项目并重新输入目标值。", "Select a current entry and enter the target value again.");
            var entry = Client.State.entries.FirstOrDefault(e => e.id == binding.Id);
            if (entry == null || !entry.available) return Reject("当前项目不可修改。", "This entry is currently unavailable.");
            string input = (value ?? "").Trim();
            long number;
            if (input.Length == 0 || input.Any(c => c < '0' || c > '9') || !Int64.TryParse(input, NumberStyles.None, CultureInfo.InvariantCulture, out number) || number < entry.min || number > entry.max)
                return Reject("请输入范围内的整数：" + entry.min + "–" + entry.max + "。", "Enter a whole number from " + entry.min + " to " + entry.max + ".");
            return Client.Send("setProgress", new Dictionary<string, object> { { "id", binding.Id }, { "value", input } });
        }
        bool Reject(string zh, string en) { if (Client != null) Client.SetNotice(zh, en, true); return false; }
        public List<CardEntry> FindCards(string query)
        {
            string q = (query ?? "").Trim();
            return Catalog.Where(c => Matches(c.id, q) || Matches(c.nameZh, q) || Matches(c.nameEn, q)).ToList();
        }
        public static bool Matches(string value, string query) { return (value ?? "").IndexOf(query ?? "", StringComparison.OrdinalIgnoreCase) >= 0; }
        public void SelectCard(string id)
        {
            ClearSelection();
            if (!Catalog.Any(c => c.id == id)) return;
            SelectedCardId = id;
            if (Client != null) Client.SelectedCardId = id;
        }
        public bool Spawn()
        {
            if (Client == null || !Client.IsConnected || !Client.State.canSpawn || SelectedCardId == null || !Catalog.Any(c => c.id == SelectedCardId))
                return Reject("连接游戏并选择一张卡牌。", "Connect to the game and select a card.");
            return Client.Send("spawn", new Dictionary<string, object> { { "id", SelectedCardId } });
        }
        public bool SetUnlimited(bool enabled, string expectedSession)
        {
            if (Client == null || !Client.IsConnected || Client.State.session != expectedSession)
                return Reject("连接已变更，请重新选择开关。", "The connection changed. Choose the setting again.");
            return Client.Send("setUnlimited", new Dictionary<string, object> { { "enabled", enabled } });
        }
    }
}
