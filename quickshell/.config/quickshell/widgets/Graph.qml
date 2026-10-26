import QtQuick
import qs.config

// Sparkline of 0–100 values
Canvas {
    id: root

    property var values: []
    property int capacity: 60
    property color color: Theme.text

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        ctx.strokeStyle = Theme.alpha(Theme.surface1, 0.8);
        ctx.lineWidth = 1;
        for (const f of [0.25, 0.5, 0.75]) {
            ctx.beginPath();
            ctx.moveTo(0, Math.round(h * f) + 0.5);
            ctx.lineTo(w, Math.round(h * f) + 0.5);
            ctx.stroke();
        }
        if (values.length < 2) return;
        const step = w / (capacity - 1);
        const x0 = w - (values.length - 1) * step;
        const y = v => h - 1 - Math.max(0, Math.min(100, v)) / 100 * (h - 2);

        ctx.beginPath();
        ctx.moveTo(x0, h);
        values.forEach((v, i) => ctx.lineTo(x0 + i * step, y(v)));
        ctx.lineTo(w, h);
        ctx.closePath();
        const grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, Theme.alpha(color, 0.35));
        grad.addColorStop(1, Theme.alpha(color, 0.02));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        values.forEach((v, i) => i ? ctx.lineTo(x0 + i * step, y(v)) : ctx.moveTo(x0, y(v)));
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.stroke();
    }
}
