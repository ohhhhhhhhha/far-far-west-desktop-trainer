using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace FFWTrainerGui
{
    public sealed class MainForm : Form
    {
        static readonly Color Slate = ColorTranslator.FromHtml("#173447");
        static readonly Color Surface = ColorTranslator.FromHtml("#F2F4F6");
        static readonly Color Divider = ColorTranslator.FromHtml("#CCD5DC");
        static readonly Color Amber = ColorTranslator.FromHtml("#A66C22");
        static readonly Color Ink = ColorTranslator.FromHtml("#182733");
        static readonly Color Muted = ColorTranslator.FromHtml("#526675");
        TrainerController controller;
        readonly UserPreferences preferences;
        readonly string preferenceFile;
        string gameRoot, section = "resource", renderedLanguage, listSignature, settingsSession, lastSession;
        EditorBinding displayedBinding;
        Notice localNotice;
        bool refreshing, settingsDirty, wasPending;
        readonly Timer timer = new Timer { Interval = 1000 };
        readonly Dictionary<string, Button> navigation = new Dictionary<string, Button>();
        readonly Label subtitle = LabelOf(10), connection = LabelOf(10), connectionDetail = LabelOf(9), languageLabel = LabelOf(9), languageValue = LabelOf(10);
        readonly ComboBox language = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
        readonly Label sectionTitle = LabelOf(17), searchLabel = LabelOf(9), listSummary = LabelOf(9), result = LabelOf(10);
        readonly TextBox search = new TextBox { Dock = DockStyle.Fill, Name = "search", ImeMode = ImeMode.NoControl };
        readonly ListView list = new ListView { Dock = DockStyle.Fill, Name = "entryList", View = View.Details,
            FullRowSelect = true, HideSelection = false, MultiSelect = false, BorderStyle = BorderStyle.None, HeaderStyle = ColumnHeaderStyle.Nonclickable };
        readonly TableLayoutPanel content = Grid(1), editorGrid = Grid(2), progressEditor = Grid(1), cardEditor = Grid(1), settings = Grid(1);
        readonly Panel detailHost = new Panel { Dock = DockStyle.Fill, BackColor = Color.White, Margin = new Padding(10, 0, 0, 0) };
        readonly Label progressName = LabelOf(15), progressId = LabelOf(9), currentValue = LabelOf(14), targetLabel = LabelOf(10), range = LabelOf(9), progressHelp = LabelOf(10);
        readonly TextBox target = new TextBox { Dock = DockStyle.Fill, Name = "targetValue", ImeMode = ImeMode.NoControl, MaxLength = 16 };
        readonly Button apply = ActionButton("applyProgress"), spawn = ActionButton("spawnCard"), applySetting = ActionButton("applyUnlimited"), browse = ActionButton("browseGame");
        readonly Label cardName = LabelOf(15), cardOtherName = LabelOf(10), cardId = LabelOf(9);
        readonly TextBox cardDescription = new TextBox { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true,
            BorderStyle = BorderStyle.None, BackColor = Color.White, ScrollBars = ScrollBars.Vertical, Name = "cardDescription" };
        readonly Label settingTitle = LabelOf(14), settingHelp = LabelOf(10), settingState = LabelOf(10), folderLabel = LabelOf(10), folderHelp = LabelOf(9);
        readonly CheckBox unlimited = new CheckBox { Dock = DockStyle.Fill, Name = "unlimitedBudget", AutoSize = false, UseVisualStyleBackColor = true };
        readonly TextBox folder = new TextBox { Dock = DockStyle.Fill, ReadOnly = true, BackColor = Color.White, Name = "gameFolder" };

        public MainForm(TrainerController initialController, string gameRoot, UserPreferences preferences, string preferenceFile)
        {
            this.controller = initialController; this.gameRoot = gameRoot; this.preferences = preferences; this.preferenceFile = preferenceFile;
            AutoScaleDimensions = new SizeF(96, 96); AutoScaleMode = AutoScaleMode.Dpi;
            Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Regular);
            ForeColor = Ink; BackColor = Surface; ClientSize = new Size(1080, 720); MinimumSize = new Size(980, 680);
            StartPosition = FormStartPosition.CenterScreen; KeyPreview = true; Name = "FFWTrainer";
            BuildLayout();
            language.Items.AddRange(new object[] { "中文", "English" });
            language.SelectedIndexChanged += delegate {
                if (refreshing || IsLive) return;
                preferences.offlineLanguage = language.SelectedIndex == 1 ? "en" : "zh";
                controller.SetOfflineLanguage(preferences.offlineLanguage); SavePreferences(); RefreshView(true);
            };
            search.TextChanged += delegate { if (!refreshing) { controller.SetSearch(search.Text); RefreshView(true); } };
            list.SelectedIndexChanged += delegate {
                if (refreshing) return;
                if (list.SelectedItems.Count == 0) controller.ClearSelection();
                else if (section == "cards") controller.SelectCard((string)list.SelectedItems[0].Tag);
                else controller.SelectProgress((string)list.SelectedItems[0].Tag);
                RefreshDetails();
            };
            list.Resize += delegate { SizeColumns(); };
            target.TextChanged += delegate { if (!refreshing) RefreshButtons(); };
            target.KeyDown += delegate(object sender, KeyEventArgs e) {
                if (e.KeyCode == Keys.Enter && apply.Enabled) { apply.PerformClick(); e.Handled = true; e.SuppressKeyPress = true; }
            };
            apply.Click += delegate { localNotice = null; controller.Apply(target.Tag as EditorBinding, target.Text); RefreshView(false); };
            spawn.Click += delegate { localNotice = null; controller.Spawn(); RefreshView(false); };
            unlimited.CheckedChanged += delegate {
                if (refreshing) return;
                settingsDirty = true; settingsSession = IsLive ? controller.Client.State.session : null; RefreshButtons();
            };
            applySetting.Click += delegate { localNotice = null; controller.SetUnlimited(unlimited.Checked, settingsSession); RefreshView(false); };
            browse.Click += delegate { BrowseFolder(); };
            KeyDown += delegate(object sender, KeyEventArgs e) {
                if (e.Control && e.KeyCode == Keys.F && section != "settings") { search.Focus(); search.SelectAll(); e.SuppressKeyPress = true; }
            };
            timer.Tick += delegate { Poll(); };
            Shown += delegate { Poll(); timer.Start(); };
            FormClosed += delegate { timer.Stop(); if (controller.Client != null) controller.Client.Dispose(); };
            if (gameRoot != null && preferences.gameRoot != gameRoot) { preferences.gameRoot = gameRoot; SavePreferences(); }
            controller.Refresh(); RefreshView(true);
        }
        bool IsLive { get { return controller.Client != null && controller.Client.IsConnected; } }
        bool IsPending { get { return controller.Client != null && controller.Client.Pending != null; } }
        string L(string zh, string en) { return controller.Language == "zh" ? zh : en; }
        static Label LabelOf(float size)
        {
            return new Label { Dock = DockStyle.Fill, AutoEllipsis = true, TextAlign = ContentAlignment.MiddleLeft,
                Font = new Font("Microsoft YaHei UI", size), Margin = new Padding(0), UseMnemonic = false };
        }
        static TableLayoutPanel Grid(int columns)
        {
            return new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = columns, Margin = new Padding(0), Padding = new Padding(0) };
        }
        static Button ActionButton(string name)
        {
            var button = new Button { Name = name, Dock = DockStyle.Fill, FlatStyle = FlatStyle.Flat,
                BackColor = Slate, ForeColor = Color.White, Margin = new Padding(0, 5, 0, 5), UseVisualStyleBackColor = false };
            button.FlatAppearance.BorderColor = Slate;
            return button;
        }
        static void Row(TableLayoutPanel panel, Control control, float height)
        {
            int index = panel.RowCount++;
            panel.RowStyles.Add(new RowStyle(height < 0 ? SizeType.Percent : SizeType.Absolute, height < 0 ? 100 : height));
            panel.Controls.Add(control, 0, index);
        }
        void BuildLayout()
        {
            var root = Grid(1); root.RowCount = 4;
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, 78)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 56));
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 64));
            Controls.Add(root);
            var header = Grid(1); header.BackColor = Slate; header.Padding = new Padding(22, 9, 22, 9);
            var title = LabelOf(21); title.Text = "Far Far West"; title.ForeColor = Color.White;
            subtitle.ForeColor = Color.FromArgb(221, 232, 238);
            Row(header, title, 36); Row(header, subtitle, -1); root.Controls.Add(header, 0, 0);

            var strip = Grid(4); strip.BackColor = Color.White; strip.Padding = new Padding(22, 11, 22, 8);
            strip.RowCount = 1; strip.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            strip.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 116)); strip.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            strip.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 119)); strip.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 105));
            connection.Font = new Font("Microsoft YaHei UI", 10, FontStyle.Bold); connectionDetail.ForeColor = Muted;
            var languageHost = new Panel { Dock = DockStyle.Fill, Margin = new Padding(0) }; languageHost.Controls.Add(language); languageHost.Controls.Add(languageValue);
            strip.Controls.Add(connection, 0, 0); strip.Controls.Add(connectionDetail, 1, 0); strip.Controls.Add(languageLabel, 2, 0); strip.Controls.Add(languageHost, 3, 0);
            root.Controls.Add(strip, 0, 1);

            var body = Grid(2); body.Padding = new Padding(18, 15, 18, 10);
            body.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 176)); body.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100)); root.Controls.Add(body, 0, 2);
            var nav = Grid(1); nav.Margin = new Padding(0, 0, 15, 0);
            foreach (string key in new string[] { "resource", "level", "magic", "cards", "settings" })
            {
                string selected = key;
                var button = ActionButton("nav_" + key); button.TextAlign = ContentAlignment.MiddleLeft; button.Padding = new Padding(12, 0, 4, 0);
                button.Margin = new Padding(0, 0, 0, 9); button.Click += delegate { ChangeSection(selected); };
                navigation.Add(key, button); Row(nav, button, 52);
            }
            Row(nav, new Panel { Dock = DockStyle.Fill }, -1); body.Controls.Add(nav, 0, 0);
            Row(content, sectionTitle, 40);
            var searchRow = Grid(2); searchRow.Padding = new Padding(0, 7, 0, 8);
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 82)); searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            searchRow.Controls.Add(searchLabel, 0, 0); searchRow.Controls.Add(search, 1, 0); Row(content, searchRow, 49);
            var deck = new Panel { Dock = DockStyle.Fill }; deck.Controls.Add(editorGrid); deck.Controls.Add(settings); Row(content, deck, -1); body.Controls.Add(content, 1, 0);
            editorGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 53)); editorGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 47));
            var listPanel = Grid(1); listPanel.BackColor = Color.White; listPanel.Padding = new Padding(1);
            Row(listPanel, list, -1); listSummary.Padding = new Padding(9, 0, 4, 0); listSummary.ForeColor = Muted; Row(listPanel, listSummary, 34);
            list.Columns.Add("", 240); list.Columns.Add("", 130); editorGrid.Controls.Add(listPanel, 0, 0); editorGrid.Controls.Add(detailHost, 1, 0);
            progressEditor.Padding = new Padding(17); cardEditor.Padding = new Padding(17); detailHost.Controls.Add(progressEditor); detailHost.Controls.Add(cardEditor);
            progressName.ForeColor = Slate; progressId.ForeColor = Muted; currentValue.ForeColor = Slate; range.ForeColor = Muted; progressHelp.ForeColor = Muted;
            Row(progressEditor, progressName, 41); Row(progressEditor, progressId, 28); Row(progressEditor, currentValue, 57);
            Row(progressEditor, targetLabel, 31); Row(progressEditor, target, 35); Row(progressEditor, range, 34); Row(progressEditor, apply, 49); Row(progressEditor, progressHelp, -1);
            cardName.ForeColor = Slate; cardOtherName.ForeColor = Muted; cardId.ForeColor = Muted; cardDescription.ForeColor = Ink;
            Row(cardEditor, cardName, 44); Row(cardEditor, cardOtherName, 30); Row(cardEditor, cardId, 30); Row(cardEditor, cardDescription, -1); Row(cardEditor, spawn, 51);
            settings.BackColor = Color.White; settings.Padding = new Padding(22, 13, 22, 13);
            settingTitle.ForeColor = Slate; settingHelp.ForeColor = Muted; folderHelp.ForeColor = Muted;
            Row(settings, settingTitle, 34); Row(settings, settingHelp, 61); Row(settings, unlimited, 40); Row(settings, settingState, 43);
            var settingActionRow = Grid(2); settingActionRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 230)); settingActionRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            settingActionRow.Controls.Add(applySetting, 0, 0); Row(settings, settingActionRow, 48);
            Row(settings, folderLabel, 39); Row(settings, folder, 36);
            var folderRow = Grid(2); folderRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 230)); folderRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            folderRow.Controls.Add(browse, 0, 0); folderHelp.Padding = new Padding(13, 0, 0, 0); folderRow.Controls.Add(folderHelp, 1, 0); Row(settings, folderRow, 49);
            Row(settings, new Panel { Dock = DockStyle.Fill }, -1);
            var footer = new Panel { Dock = DockStyle.Fill, BackColor = Color.White, Padding = new Padding(22, 9, 22, 9) }; footer.Controls.Add(result); root.Controls.Add(footer, 0, 3);
        }
        void Poll()
        {
            if (controller.Client == null && gameRoot != null)
            {
                var client = GamePaths.CreateClient(gameRoot);
                if (client != null) ReplaceController(client);
            }
            if (controller.Client != null) controller.Client.Poll();
            controller.Refresh(); RefreshView(false);
        }
        void ChangeSection(string value)
        {
            section = value; controller.SetSearch(""); refreshing = true; search.Text = ""; refreshing = false;
            RefreshView(true);
        }
        void RefreshView(bool rebuild)
        {
            refreshing = true;
            string session = IsLive ? controller.Client.State.session : null;
            if (lastSession != session || renderedLanguage != controller.Language) settingsDirty = false;
            if (wasPending && !IsPending) { settingsDirty = false; target.Text = ""; }
            lastSession = session; wasPending = IsPending;
            if (renderedLanguage != controller.Language) { renderedLanguage = controller.Language; Translate(); rebuild = true; }
            connection.Text = IsLive ? L("● 已连接", "● Connected") : L("● 未连接", "● Offline");
            connection.ForeColor = IsLive ? Color.FromArgb(35, 112, 82) : Amber;
            if (IsLive) connectionDetail.Text = L(controller.Client.State.messageZh, controller.Client.State.messageEn);
            else if (controller.Client != null && controller.Client.ConnectionProblem != null) connectionDetail.Text = controller.Client.ConnectionProblem.Text(controller.Language);
            else connectionDetail.Text = gameRoot == null ? L("在设置中选择游戏目录", "Select the game folder in Settings") :
                controller.Client == null ? L("请安装 Trainer 连接组件", "Install the Trainer connection component") : L("等待游戏连接；离线仍可搜索卡牌", "Waiting for the game; card search is available offline");
            language.Enabled = !IsLive; language.SelectedIndex = controller.Language == "zh" ? 0 : 1;
            language.Visible = !IsLive; languageValue.Visible = IsLive; languageValue.Text = controller.Language == "zh" ? "中文" : "English";
            if (IsLive) languageValue.BringToFront(); else language.BringToFront();
            languageLabel.Text = IsLive ? L("跟随游戏语言", "Game language") : L("界面语言", "UI language");
            foreach (var pair in navigation)
            {
                pair.Value.BackColor = pair.Key == section ? Slate : Color.White;
                pair.Value.ForeColor = pair.Key == section ? Color.White : Ink;
                pair.Value.FlatAppearance.BorderColor = pair.Key == section ? Slate : Divider;
            }
            sectionTitle.Text = SectionName(section);
            bool showingSettings = section == "settings";
            settings.Visible = showingSettings; editorGrid.Visible = !showingSettings;
            content.RowStyles[1].Height = showingSettings ? 0 : 49;
            if (showingSettings) settings.BringToFront(); else editorGrid.BringToFront();
            folder.Text = gameRoot ?? L("尚未选择", "Not selected");
            if (!settingsDirty) unlimited.Checked = controller.Client != null && controller.Client.State != null && controller.Client.State.unlimited != null && controller.Client.State.unlimited.enabled;
            settingsSession = settingsDirty ? settingsSession : session;
            var status = controller.Client != null && controller.Client.State != null ? controller.Client.State.unlimited : null;
            settingState.Text = IsLive && status != null ? L(status.messageZh, status.messageEn) : L("连接游戏后可设置。", "Connect to the game to change this setting.");
            settingState.ForeColor = IsLive && status != null && status.active ? Color.FromArgb(35, 112, 82) : Muted;
            if (!showingSettings) RefreshList(rebuild);
            refreshing = false;
            RefreshDetails();
            Notice notice = localNotice ?? (controller.Client == null ? null : controller.Client.Notice);
            result.Text = notice != null ? notice.Text(controller.Language) : L("选择项目后，使用右侧按钮执行操作。", "Select an item, then use its action button.");
            result.ForeColor = notice != null && notice.Error ? Amber : Muted;
        }
        void Translate()
        {
            Text = L("Far Far West · 桌面工具", "Far Far West · Desktop trainer");
            subtitle.Text = L("资源、等级与奇术卡", "Resources, levels and Jokers");
            foreach (var pair in navigation) pair.Value.Text = SectionName(pair.Key);
            searchLabel.Text = L("搜索", "Search"); search.AccessibleName = L("按中英文名称或 ID 搜索", "Search Chinese or English names or IDs");
            language.AccessibleName = L("离线界面语言", "Offline UI language"); list.AccessibleName = L("可选项目", "Available entries");
            targetLabel.Text = L("目标值", "Target value"); target.AccessibleName = targetLabel.Text;
            apply.Text = L("应用目标值", "Apply target value"); spawn.Text = L("生成 1 张卡牌", "Spawn one card");
            settingTitle.Text = L("属性点设置", "Attribute-point setting");
            settingHelp.Text = L("开启后，继续在游戏原有的属性菜单中加点。每项属性的上限和原有费用仍然生效。", "After enabling, spend points in the game's original attribute menu. Individual limits and normal costs still apply.");
            unlimited.Text = L("解除属性总点数限制", "Remove the total attribute-point limit");
            applySetting.Text = L("应用开关设置", "Apply setting"); folderLabel.Text = L("游戏安装目录", "Game installation folder"); browse.Text = L("选择游戏目录…", "Choose game folder…");
            folderHelp.Text = L("选择 FarFarWest 游戏根目录。", "Select the FarFarWest game root folder.");
            folder.AccessibleName = folderLabel.Text; cardDescription.AccessibleName = L("卡牌说明与当前预览", "Card description and current preview");
        }
        string SectionName(string value)
        {
            switch (value)
            {
                case "resource": return L("资源", "Resources");
                case "level": return L("角色与武器等级", "Character / weapons");
                case "magic": return L("魔法等级", "Magic levels");
                case "cards": return L("奇术卡", "Jokers");
                default: return L("设置", "Settings");
            }
        }
        void RefreshList(bool force)
        {
            var rows = new List<string[]>();
            string query = controller.Search.Trim();
            if (section == "cards")
                foreach (var card in controller.FindCards(query)) rows.Add(new string[] { card.id, L(card.nameZh, card.nameEn), card.id });
            else if (controller.Client != null && controller.Client.State != null)
                foreach (var entry in controller.Client.State.entries.Where(e => e.category == section &&
                    (TrainerController.Matches(e.id, query) || TrainerController.Matches(e.nameZh, query) || TrainerController.Matches(e.nameEn, query))))
                    rows.Add(new string[] { entry.id, L(entry.nameZh, entry.nameEn), Number(entry.value) });
            string signature = section + "|" + controller.Language + "|" + query + "|" + String.Join("|", rows.Select(r => r[0] + ":" + r[1]));
            string selectedId = section == "cards" ? controller.SelectedCardId : controller.Binding == null ? null : controller.Binding.Id;
            if (force || signature != listSignature)
            {
                list.BeginUpdate(); list.Items.Clear();
                foreach (var row in rows)
                {
                    var item = new ListViewItem(new string[] { row[1], row[2] }) { Tag = row[0] };
                    list.Items.Add(item); item.Selected = row[0] == selectedId;
                }
                list.EndUpdate(); listSignature = signature;
            }
            else for (int i = 0; i < rows.Count; i++)
            {
                if (list.Items[i].SubItems[1].Text != rows[i][2]) list.Items[i].SubItems[1].Text = rows[i][2];
                if (list.Items[i].Selected != (rows[i][0] == selectedId)) list.Items[i].Selected = rows[i][0] == selectedId;
            }
            list.Columns[0].Text = section == "cards" ? L("卡牌名称", "Card name") : L("项目", "Entry");
            list.Columns[1].Text = section == "cards" ? "ID" : IsLive ? L("当前值", "Current") : L("上次值", "Last read");
            listSummary.Text = rows.Count > 0 ? rows.Count + L(" 项 · 支持中英文名称与 ID", " items · Chinese, English or ID") : query.Length > 0 ? L("没有匹配项目", "No matching entries") : IsLive ? L("当前没有可用项目", "No entries available") : L("连接游戏后显示可修改项目", "Connect to view progress entries");
            SizeColumns();
        }
        void SizeColumns()
        {
            if (list.Columns.Count < 2) return;
            int width = Math.Max(200, list.ClientSize.Width - SystemInformation.VerticalScrollBarWidth - 2);
            int second = section == "cards" ? Math.Min(175, width / 2) : 100;
            list.Columns[0].Width = width - second; list.Columns[1].Width = second;
        }
        static string Number(object value)
        {
            return value == null ? "—" : Convert.ToString(value, CultureInfo.InvariantCulture);
        }
        void RefreshDetails()
        {
            refreshing = true;
            if (!Object.ReferenceEquals(displayedBinding, controller.Binding))
            {
                displayedBinding = controller.Binding; target.Text = ""; target.Tag = displayedBinding;
            }
            bool cards = section == "cards";
            cardEditor.Visible = cards; progressEditor.Visible = !cards;
            if (cards)
            {
                cardEditor.BringToFront();
                var card = controller.Catalog.FirstOrDefault(c => c.id == controller.SelectedCardId);
                cardName.Text = card == null ? L("选择一张奇术卡", "Select a Joker") : L(card.nameZh, card.nameEn);
                cardOtherName.Text = card == null ? L("两种语言均可搜索", "Search in either language") : L(card.nameEn, card.nameZh);
                cardId.Text = card == null ? "" : "ID: " + card.id;
                string description = card == null ? L("使用左侧列表查看说明，再点击按钮生成一张。", "Use the list to view a card, then click the button to spawn one.") : L(card.descriptionZh, card.descriptionEn);
                CardPreview preview = IsLive ? controller.Client.State.cardPreview : null;
                if (card != null && preview != null && preview.id == card.id)
                {
                    string live = L(preview.textZh, preview.textEn);
                    if (!String.IsNullOrWhiteSpace(live)) description += "\r\n\r\n" + L("当前预览", "Current preview") + "\r\n" + live;
                }
                if (cardDescription.Text != description) cardDescription.Text = description;
            }
            else
            {
                progressEditor.BringToFront();
                var entry = controller.Binding == null || controller.Client == null || controller.Client.State == null ? null : controller.Client.State.entries.FirstOrDefault(e => e.id == controller.Binding.Id);
                progressName.Text = entry == null ? L("选择一个项目", "Select an entry") : L(entry.nameZh, entry.nameEn);
                progressId.Text = entry == null ? L("从左侧列表开始", "Start with the list on the left") : "ID: " + entry.id;
                currentValue.Text = (IsLive ? L("当前值：", "Current: ") : L("上次读取：", "Last read: ")) + (entry == null ? "—" : Number(entry.value));
                range.Text = entry == null ? "" : L("允许范围：", "Range: ") + entry.min + "–" + entry.max;
                progressHelp.Text = entry != null && !entry.available ? L("当前项目不可修改。请查看上方游戏状态。", "This entry is unavailable. Check the game status above.") : L("输入完整目标值后点击应用。切换项目或搜索会清空输入。", "Enter the full target value, then apply. Changing entries or searching clears the input.");
            }
            refreshing = false; RefreshButtons();
        }
        void RefreshButtons()
        {
            bool idle = IsLive && !IsPending;
            ProgressEntry entry = controller.Binding == null || controller.Client == null || controller.Client.State == null ? null : controller.Client.State.entries.FirstOrDefault(e => e.id == controller.Binding.Id);
            target.Enabled = idle && controller.Client.State.canApply && entry != null && entry.available;
            apply.Enabled = target.Enabled && !String.IsNullOrWhiteSpace(target.Text);
            spawn.Enabled = idle && controller.Client.State.canSpawn && controller.SelectedCardId != null;
            unlimited.Enabled = idle; applySetting.Enabled = idle && settingsDirty;
            foreach (Button button in new Button[] { apply, spawn, applySetting })
            {
                button.BackColor = button.Enabled ? Slate : Surface;
                button.ForeColor = button.Enabled ? Color.White : Muted;
                button.FlatAppearance.BorderColor = button.Enabled ? Slate : Divider;
            }
        }
        void BrowseFolder()
        {
            using (var dialog = new FolderBrowserDialog { Description = L("选择 FarFarWest 游戏安装目录", "Select the FarFarWest game installation folder"), ShowNewFolderButton = false, SelectedPath = gameRoot ?? "" })
            {
                if (dialog.ShowDialog(this) != DialogResult.OK) return;
                string chosen = GamePaths.FindRoot(dialog.SelectedPath);
                if (chosen == null)
                {
                    MessageBox.Show(this, L("未找到 FarFarWest/Binaries/Win64/ue4ss/Mods。请选择已安装 UE4SS 的游戏目录。", "FarFarWest/Binaries/Win64/ue4ss/Mods was not found. Select the game folder with UE4SS installed."), Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                if (controller.Client != null) controller.Client.Dispose();
                gameRoot = chosen; preferences.gameRoot = chosen; ReplaceController(GamePaths.CreateClient(chosen)); SavePreferences(); Poll();
            }
        }
        void ReplaceController(FileBridgeClient client)
        {
            controller = new TrainerController(client, controller.Catalog); controller.SetOfflineLanguage(preferences.offlineLanguage);
            controller.SetSearch(search.Text); listSignature = null; settingsDirty = false;
        }
        void SavePreferences()
        {
            try { preferences.Save(preferenceFile); localNotice = null; }
            catch (Exception) { localNotice = new Notice("无法保存本机偏好；本次设置仍然有效。", "Cannot save local preferences; the current setting still applies.", true); }
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing) { timer.Dispose(); if (controller.Client != null) controller.Client.Dispose(); }
            base.Dispose(disposing);
        }
    }
}
