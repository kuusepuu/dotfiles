pragma Singleton
import QtQuick
import Quickshell

// Nerd Font glyphs
Singleton {
    function g(cp) {
        return String.fromCodePoint(cp);
    }

    readonly property string ram: g(0xF035B)
    readonly property string cpu: g(0xF2DB)
    readonly property string temp: g(0xF2C9)
    readonly property string gpu: g(0xF08AE)
    readonly property string clock: g(0xF017)
    readonly property string calendar: g(0xF073)
    readonly property string bt: g(0xF00AF)
    readonly property string btOff: g(0xF00B2)
    readonly property string btConnected: g(0xF00B1)
    readonly property string keyboard: g(0xF030C)
    readonly property string volMute: g(0xF075F)
    readonly property string volLow: g(0xF057F)
    readonly property string volMid: g(0xF0580)
    readonly property string volHigh: g(0xF057E)
    readonly property string headphones: g(0xF02CB)
    readonly property string headset: g(0xF02CE)
    readonly property string down: g(0xF0046)
    readonly property string up: g(0xF005E)
    readonly property string ethernet: g(0xF0200)
    readonly property string wifi: g(0xF05A9)
    readonly property string offline: g(0xF0319)
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string bellBadge: g(0xF009E)
    readonly property string clearAll: g(0xF039F)
    readonly property string close: g(0xF0156)
    readonly property string power: g(0xF011)
    readonly property string lock: g(0xF023)
    readonly property string suspend: g(0xF0904)
    readonly property string logout: g(0xF0343)
    readonly property string reboot: g(0xF0709)
    readonly property string speaker: g(0xF04C3)
    readonly property string brightness: g(0xF00DF)
    readonly property string batteryCharging: g(0xF0084)
    readonly property string search: g(0xF0349)
    readonly property string pin: g(0xF0403)
    readonly property string chevronRight: g(0xF0142)
    readonly property string apps: g(0xF003B)
    readonly property string code: g(0xF0174)
    readonly property string web: g(0xF059F)
    readonly property string media: g(0xF040A)
    readonly property string gamepad: g(0xF0297)
    readonly property string palette: g(0xF03D8)
    readonly property string office: g(0xF00D6)
    readonly property string cog: g(0xF0493)

    function battery(pct) {
        if (pct >= 95) return g(0xF0079);
        return g(0xF007A + Math.max(0, Math.floor(pct / 10) - 1));
    }

    function volume(v, muted) {
        if (muted || v <= 0) return volMute;
        if (v < 0.34) return volLow;
        if (v < 0.67) return volMid;
        return volHigh;
    }
}
