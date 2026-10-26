using System;
using System.Collections.Generic;

namespace FFWTrainerGui
{
    public sealed class ProgressEntry
    {
        public string id { get; set; }
        public string category { get; set; }
        public string nameZh { get; set; }
        public string nameEn { get; set; }
        public long min { get; set; }
        public long max { get; set; }
        public object value { get; set; }
        public object raw { get; set; }
        public bool available { get; set; }
    }
    public sealed class UnlimitedState
    {
        public bool enabled { get; set; }
        public bool active { get; set; }
        public string messageZh { get; set; }
        public string messageEn { get; set; }
    }
    public sealed class CommandResult
    {
        public string requestId { get; set; }
        public bool success { get; set; }
        public string messageZh { get; set; }
        public string messageEn { get; set; }
    }
    public sealed class CardPreview
    {
        public string id { get; set; }
        public string textZh { get; set; }
        public string textEn { get; set; }
    }
    public sealed class BridgeState
    {
        public int protocol { get; set; }
        public string session { get; set; }
        public double updatedAt { get; set; }
        public string language { get; set; }
        public bool connected { get; set; }
        public bool canApply { get; set; }
        public bool canSpawn { get; set; }
        public string messageZh { get; set; }
        public string messageEn { get; set; }
        public List<ProgressEntry> entries { get; set; }
        public UnlimitedState unlimited { get; set; }
        public CommandResult lastResult { get; set; }
        public CardPreview cardPreview { get; set; }
    }
    public sealed class BridgeCommand
    {
        public int protocol { get; set; }
        public string clientId { get; set; }
        public string session { get; set; }
        public string requestId { get; set; }
        public double createdAt { get; set; }
        public string action { get; set; }
        public Dictionary<string, object> payload { get; set; }
    }
    public sealed class CardEntry
    {
        public string id { get; set; }
        public string nameZh { get; set; }
        public string nameEn { get; set; }
        public string descriptionZh { get; set; }
        public string descriptionEn { get; set; }
    }
    public sealed class Notice
    {
        public readonly string Zh;
        public readonly string En;
        public readonly bool Error;
        public Notice(string zh, string en, bool error) { Zh = zh; En = en; Error = error; }
        public string Text(string language) { return language == "zh" ? Zh : En; }
    }
}
