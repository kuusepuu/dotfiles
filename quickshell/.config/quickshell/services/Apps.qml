pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Desktop entries for the launcher: categories, fuzzy search, pins and frecency (persisted in the state dir)
Singleton {
    id: root

    // Visible apps, deduplicated and sorted by name
    readonly property var list: {
        const seen = new Set();
        return DesktopEntries.applications.values.filter(e => {
            if (e.noDisplay || seen.has(e.id)) return false;
            seen.add(e.id);
            return true;
        }).sort((a, b) => a.name.localeCompare(b.name));
    }

    // id → entry of Config.launcherCategories (or undefined)
    readonly property var categoryOf: {
        const map = {};
        for (const e of list) {
            const cats = e.categories;
            map[e.id] = Config.launcherCategories.find(c => c.cats.some(x => cats.includes(x)));
        }
        return map;
    }

    readonly property var all: ({ name: "All", icon: Icons.apps, accent: Theme.mauve, cats: [] })
    // "All" plus every category that has at least one app
    readonly property var categories: [all, ...Config.launcherCategories.filter(c => list.some(e => categoryOf[e.id] === c))]

    readonly property real halfLife: Config.launcherHalfLifeDays * 86400000
    readonly property int maxRecent: 10
    readonly property int maxResults: 50

    FileView {
        id: store
        path: Quickshell.statePath("launcher.json")
        atomicWrites: true

        JsonAdapter {
            id: saved
            property var usage: ({})        // id → { s: decayed launch count, t: last launch (ms) }
            property var pinned: []         // ids, in pin order
        }
    }

    function frecency(id) {
        const u = saved.usage[id];
        return u ? u.s * Math.pow(0.5, (Date.now() - u.t) / halfLife) : 0;
    }

    function isPinned(id) {
        return saved.pinned.includes(id);
    }

    function togglePin(id) {
        saved.pinned = isPinned(id) ? saved.pinned.filter(p => p !== id) : [...saved.pinned, id];
        store.writeAdapter();
    }

    function launch(entry, action) {
        const usage = Object.assign({}, saved.usage);
        usage[entry.id] = { s: frecency(entry.id) + 1, t: Date.now() };
        saved.usage = usage;
        store.writeAdapter();

        if (action) action.execute();
        else if (entry.runInTerminal) Quickshell.execDetached({ command: [...Config.terminal, ...entry.command], workingDirectory: entry.workingDirectory });
        else entry.execute();
    }

    // Rows for the launcher list: { key, entry, action, cat, idx (matched name chars), header }
    function search(query, category) {
        const apps = category === all ? list : list.filter(e => categoryOf[e.id] === category);
        const row = (entry, action, idx, header) => ({
            key: `${entry.id}/${action?.id ?? ""}`,
            entry,
            action,
            cat: categoryOf[entry.id],
            idx,
            header: header ?? "",
        });
        const tokens = query.toLowerCase().split(/\s+/).filter(t => t);

        // No query: pinned, then recently used, then everything else A–Z
        if (!tokens.length) {
            const pinned = saved.pinned.map(id => apps.find(e => e.id === id)).filter(e => e);
            const recent = apps.filter(e => !isPinned(e.id))
                .map(e => [e, frecency(e.id)])
                .filter(p => p[1] > 0.05)
                .sort((a, b) => b[1] - a[1])
                .slice(0, maxRecent)
                .map(p => p[0]);
            const rest = apps.filter(e => !pinned.includes(e) && !recent.includes(e));
            return [
                ...pinned.map((e, i) => row(e, null, [], i === 0 ? "Pinned" : "")),
                ...recent.map((e, i) => row(e, null, [], i === 0 ? "Recent" : "")),
                ...rest.map((e, i) => row(e, null, [], i === 0 && (pinned.length || recent.length) ? "All apps" : "")),
            ];
        }

        const scored = [];
        for (const e of apps) {
            const boost = 10 * Math.log1p(frecency(e.id)) + (isPinned(e.id) ? 5 : 0);
            const m = matchAll(tokens, [[e.name, 1], [e.genericName, 0.6], [e.keywords.join(" "), 0.5], [e.comment, 0.3]]);
            if (m) scored.push([row(e, null, m.idx), m.score + boost]);

            // Actions only show when the query names them, otherwise "fire" would list every Firefox action
            for (const a of e.actions) {
                const am = matchAll(tokens, [[a.name, 1], [e.name, 0.8], [e.genericName, 0.4]]);
                if (am && am.idx.length) scored.push([row(e, a, am.idx), am.score + boost - 5]);
            }
        }
        return scored.sort((a, b) => b[1] - a[1]).slice(0, maxResults).map(p => p[0]);
    }

    // Every token must match some field. Returns the summed best weighted scores and the indices matched in field 0.
    function matchAll(tokens, fields) {
        let score = 0;
        const idx = [];
        for (const t of tokens) {
            let best = null, bestScore = 0, bestField = -1;
            fields.forEach(([text, w], i) => {
                // Loose (subsequence) matching only on names; descriptions would match almost anything
                const m = text ? fuzzy(t, text, w >= 0.8) : null;
                if (m && m.score * w > bestScore) {
                    best = m;
                    bestScore = m.score * w;
                    bestField = i;
                }
            });
            if (!best) return null;
            score += bestScore;
            if (bestField === 0) idx.push(...best.idx);
        }
        return { score, idx };
    }

    // needle is lowercase. Prefix and word-start substrings rank highest, then subsequences anchored at the
    // start of the name ("ff" → Firefox), then mid-word substrings ("ff" in LibreOffice).
    function fuzzy(needle, hay, loose) {
        const h = hay.toLowerCase();
        const sub = h.indexOf(needle);
        if (sub >= 0) {
            const base = h === needle ? 300 : sub === 0 ? 200 : isBoundary(hay, sub) ? 150 : 60;
            return {
                score: Math.max(10, base - sub * 0.5 - (h.length - needle.length) * 0.2),
                idx: Array.from({ length: needle.length }, (_, i) => sub + i),
            };
        }
        if (!loose) return null;

        const idx = [];
        let score = 0, starts = 0;
        for (let i = 0; i < h.length && idx.length < needle.length; i++) {
            if (h[i] !== needle[idx.length]) continue;
            const start = isBoundary(hay, i);
            score += 1 + (idx.length && idx[idx.length - 1] === i - 1 ? 5 : 0) + (start ? 8 : 0);
            starts += start;
            idx.push(i);
        }
        if (idx.length < needle.length) return null;
        const span = idx[idx.length - 1] - idx[0] + 1;
        // Scattered letters are noise, unless every one starts a word ("lw" → LibreOffice Writer)
        if (span > needle.length * 3 + 2 && starts < needle.length) return null;
        return { score: Math.max(1, score + (idx[0] === 0 ? 50 : 0) - (span - needle.length) * 0.5), idx };
    }

    // Start of a word or of a camelCase hump
    function isBoundary(s, i) {
        if (i === 0 || /[\s\-_.]/.test(s[i - 1])) return true;
        return s[i] !== s[i].toLowerCase() && s[i - 1] === s[i - 1].toLowerCase();
    }
}
