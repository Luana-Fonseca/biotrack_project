package com.biotrack.api.reports;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.GradientPaint;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Ellipse2D;
import java.awt.geom.GeneralPath;
import java.awt.geom.Arc2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Renders the ESG PDF report's charts to raster images (no external charting library): gradient
 * rounded bars, a smooth (Catmull-Rom) gradient area/line chart that can draw a dashed
 * "projected" tail, a ring/donut chart, and the small line icons used in the KPI cards. Embedded
 * as PNGs into the PDF by {@link ReportService}.
 */
final class ChartRenderer {

    private static final Color INK = new Color(0x1C, 0x22, 0x33);
    private static final Color MUTED = new Color(0x8A, 0x93, 0xA6);
    private static final Color GRID = new Color(0xEE, 0xF0, 0xF6);

    private static final Font REGULAR;
    private static final Font MEDIUM;
    private static final Font SEMI_BOLD;
    private static final Font BOLD;
    private static final Font EXTRA_BOLD;

    static {
        REGULAR = loadFont("Inter-Regular.ttf");
        MEDIUM = loadFont("Inter-Medium.ttf");
        SEMI_BOLD = loadFont("Inter-SemiBold.ttf");
        BOLD = loadFont("Inter-Bold.ttf");
        EXTRA_BOLD = loadFont("Inter-ExtraBold.ttf");
    }

    private static Font loadFont(String resourceName) {
        try (InputStream in = ChartRenderer.class.getResourceAsStream("/fonts/" + resourceName)) {
            return Font.createFont(Font.TRUETYPE_FONT, in);
        } catch (IOException | java.awt.FontFormatException e) {
            throw new UncheckedIOException(new IOException("Could not load font " + resourceName, e));
        }
    }

    private ChartRenderer() {
    }

    private static Graphics2D graphics(BufferedImage img) {
        Graphics2D g = img.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);
        return g;
    }

    private static Color alpha(Color c, int a) {
        return new Color(c.getRed(), c.getGreen(), c.getBlue(), a);
    }

    private static Color lighten(Color c, float amt) {
        float[] hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
        hsb[2] = Math.min(1f, hsb[2] + amt * (1 - hsb[2]));
        hsb[1] = Math.max(0f, hsb[1] - amt * 0.3f);
        return Color.getHSBColor(hsb[0], hsb[1], hsb[2]);
    }

    private static String formatValue(double v, String unit) {
        String number = Math.abs(v) >= 100 ? String.format(Locale.US, "%.0f", v) : String.format(Locale.US, "%.1f", v);
        return (number + (unit.isEmpty() ? "" : " " + unit)).replace(".", ",");
    }

    /** Vertical gradient bars with rounded tops and a soft drop shadow. */
    static BufferedImage gradientBarChart(List<String> labels, List<Double> values, List<Color> colors,
                                           int width, int height, String unit) {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(img);
        int padTop = 34, padBottom = 46, padSide = 40;
        int chartTop = padTop, chartBottom = height - padBottom;
        int chartLeft = padSide, chartRight = width - padSide;
        int chartWidth = chartRight - chartLeft;

        double max = values.stream().mapToDouble(Double::doubleValue).max().orElse(1);
        if (max <= 0) max = 1;
        max *= 1.22;

        g.setColor(GRID);
        g.setStroke(new BasicStroke(1.2f));
        g.drawLine(chartLeft, chartBottom, chartRight, chartBottom);

        int n = Math.max(values.size(), 1);
        int gap = chartWidth / (n * 3);
        int barWidth = Math.min(72, (chartWidth - gap * (n + 1)) / n);
        int totalBarsWidth = barWidth * n + gap * (n - 1);
        int x = chartLeft + (chartWidth - totalBarsWidth) / 2;

        g.setFont(SEMI_BOLD.deriveFont(11f));
        FontMetrics labelFm = g.getFontMetrics();

        for (int i = 0; i < values.size(); i++) {
            double v = values.get(i);
            int barHeight = Math.max((int) Math.round((v / max) * (chartBottom - chartTop)), 3);
            int by = chartBottom - barHeight;
            Color base = colors.get(i % colors.size());

            g.setColor(alpha(base, 40));
            g.fillRoundRect(x - 2, by + 6, barWidth + 4, barHeight, 18, 18);

            g.setPaint(new GradientPaint(0, by, lighten(base, 0.18f), 0, chartBottom, base));
            g.fillRoundRect(x, by, barWidth, barHeight, 18, 18);
            g.setPaint(null);

            g.setColor(INK);
            g.setFont(BOLD.deriveFont(13f));
            String valueText = formatValue(v, unit);
            FontMetrics vm = g.getFontMetrics();
            g.drawString(valueText, x + (barWidth - vm.stringWidth(valueText)) / 2, by - 10);

            g.setColor(MUTED);
            g.setFont(MEDIUM.deriveFont(10.5f));
            String label = strip(labels.get(i));
            int tw = labelFm.stringWidth(label);
            g.drawString(label, x + (barWidth - tw) / 2, chartBottom + 20);

            x += barWidth + gap;
        }
        g.dispose();
        return img;
    }

    /**
     * Smooth (Catmull-Rom) area/line chart. {@code dashFromIndex &gt;= 0} draws from that point
     * onward as a dashed, unfilled "projected" tail; {@code -1} draws the whole series solid.
     */
    static BufferedImage smoothAreaChart(List<String> labels, double[] values, Color color, int width, int height,
                                          String unit, int dashFromIndex) {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(img);
        int padTop = 30, padBottom = 46, padLeft = 34, padRight = 34;
        int chartTop = padTop, chartBottom = height - padBottom;
        int chartLeft = padLeft, chartRight = width - padRight;
        int n = values.length;
        if (n == 1) {
            // A single point has no line to draw — nudge it so the chart doesn't divide by zero below.
            n = 2;
            values = new double[]{values[0], values[0]};
        }

        double max = Double.NEGATIVE_INFINITY, min = Double.POSITIVE_INFINITY;
        for (double v : values) {
            max = Math.max(max, v);
            min = Math.min(min, v);
        }
        double span = Math.max(max - min, 1e-6);
        double top = max + span * 0.28;
        double bottom = Math.max(0, min - span * 0.18);
        double range = Math.max(top - bottom, 1e-6);

        double stepX = (chartRight - chartLeft) / (double) (n - 1);
        double[] xs = new double[n];
        double[] ys = new double[n];
        for (int i = 0; i < n; i++) {
            xs[i] = chartLeft + i * stepX;
            ys[i] = chartBottom - ((values[i] - bottom) / range) * (chartBottom - chartTop);
        }

        g.setColor(GRID);
        g.setStroke(new BasicStroke(1f));
        for (int i = 0; i < n; i++) {
            g.draw(new java.awt.geom.Line2D.Double(xs[i], chartTop - 4, xs[i], chartBottom));
        }

        int splitIdx = dashFromIndex < 0 ? n - 1 : Math.min(dashFromIndex, n - 1);
        GeneralPath solidPath = smoothPath(xs, ys, 0, splitIdx);

        GeneralPath area = (GeneralPath) solidPath.clone();
        area.lineTo(xs[splitIdx], chartBottom);
        area.lineTo(xs[0], chartBottom);
        area.closePath();
        g.setPaint(new GradientPaint(0, chartTop, alpha(color, 60), 0, chartBottom, alpha(color, 0)));
        g.fill(area);
        g.setPaint(null);

        g.setColor(alpha(color, 35));
        g.setStroke(new BasicStroke(6f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g.translate(0, 3);
        g.draw(solidPath);
        g.translate(0, -3);

        g.setColor(color);
        g.setStroke(new BasicStroke(2.6f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g.draw(solidPath);

        if (dashFromIndex >= 0 && dashFromIndex < n - 1) {
            GeneralPath dashedPath = smoothPath(xs, ys, splitIdx, n - 1);
            g.setStroke(new BasicStroke(2.6f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND, 1f, new float[]{1f, 7f}, 0f));
            g.draw(dashedPath);
        }

        for (int i = 0; i < n; i++) {
            boolean projected = dashFromIndex >= 0 && i > dashFromIndex;
            g.setColor(Color.WHITE);
            g.fill(new Ellipse2D.Double(xs[i] - 4, ys[i] - 4, 8, 8));
            g.setColor(color);
            if (projected) {
                g.setStroke(new BasicStroke(2.2f));
                g.draw(new Ellipse2D.Double(xs[i] - 4, ys[i] - 4, 8, 8));
            } else {
                g.fill(new Ellipse2D.Double(xs[i] - 3, ys[i] - 3, 6, 6));
            }
        }

        g.setFont(MEDIUM.deriveFont(10f));
        g.setColor(MUTED);
        FontMetrics fm = g.getFontMetrics();
        for (int i = 0; i < n; i++) {
            String lbl = strip(labels.get(i));
            int w = fm.stringWidth(lbl);
            int lx = (int) Math.min(Math.max(xs[i] - w / 2.0, 2), width - w - 2);
            g.drawString(lbl, lx, chartBottom + 20);
        }

        g.setFont(BOLD.deriveFont(12f));
        g.setColor(INK);
        String lastVal = formatValue(values[n - 1], unit);
        int lw = g.getFontMetrics().stringWidth(lastVal);
        float lx2 = (float) Math.min(Math.max(xs[n - 1] - lw / 2.0, chartLeft), chartRight - lw);
        g.drawString(lastVal, lx2, (float) ys[n - 1] - 14);

        if (dashFromIndex >= 0) {
            g.setFont(SEMI_BOLD.deriveFont(9.5f));
            g.setColor(MUTED);
            String tag = "projetado";
            int tw = g.getFontMetrics().stringWidth(tag);
            g.drawString(tag, chartRight - tw, chartTop - 10);
            g.setColor(color);
            g.setStroke(new BasicStroke(2.4f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND, 1f, new float[]{1f, 6f}, 0f));
            g.drawLine(chartRight - tw - 34, chartTop - 13, chartRight - tw - 12, chartTop - 13);
        }

        g.dispose();
        return img;
    }

    private static GeneralPath smoothPath(double[] xs, double[] ys, int from, int to) {
        GeneralPath path = new GeneralPath();
        path.moveTo(xs[from], ys[from]);
        for (int i = from; i < to; i++) {
            double x0 = i == from ? xs[i] : xs[i - 1];
            double y0 = i == from ? ys[i] : ys[i - 1];
            double x1 = xs[i], y1 = ys[i];
            double x2 = xs[i + 1], y2 = ys[i + 1];
            double x3 = i + 2 <= to ? xs[i + 2] : x2;
            double y3 = i + 2 <= to ? ys[i + 2] : y2;
            double cp1x = x1 + (x2 - x0) / 6.0, cp1y = y1 + (y2 - y0) / 6.0;
            double cp2x = x2 - (x3 - x1) / 6.0, cp2y = y2 - (y3 - y1) / 6.0;
            path.curveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
        }
        return path;
    }

    /** Ring/donut chart with rounded-cap segments, a center total, and a side legend. */
    static BufferedImage donutChart(List<String> labels, List<Double> values, List<Color> colors, int width, int height,
                                     String centerValue, String centerLabel) {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(img);

        double total = values.stream().mapToDouble(Double::doubleValue).sum();
        int cx = 130, cy = height / 2;
        int outerR = 92, innerR = 58;
        float gapDeg = 3.5f;

        double startAngle = 90;
        List<double[]> arcs = new ArrayList<>();
        for (double v : values) {
            double extent = total > 0 ? (v / total) * 360.0 : 0;
            arcs.add(new double[]{startAngle - extent, extent});
            startAngle -= extent;
        }

        float ringWidth = outerR - innerR;
        g.setStroke(new BasicStroke(ringWidth, BasicStroke.CAP_BUTT, BasicStroke.JOIN_ROUND));
        float midR = (outerR + innerR) / 2f;
        for (int i = 0; i < arcs.size(); i++) {
            double[] a = arcs.get(i);
            double extent = Math.max(a[1] - gapDeg, 0.001);
            Arc2D.Double arc = new Arc2D.Double(cx - midR, cy - midR, midR * 2, midR * 2, a[0] + gapDeg / 2.0, extent, Arc2D.OPEN);
            g.setColor(colors.get(i % colors.size()));
            g.draw(arc);
        }
        g.setStroke(new BasicStroke(1f));
        for (int i = 0; i < arcs.size(); i++) {
            double[] a = arcs.get(i);
            double extent = Math.max(a[1] - gapDeg, 0.001);
            Color col = colors.get(i % colors.size());
            g.setColor(col);
            for (double ang : new double[]{a[0] + gapDeg / 2.0, a[0] + gapDeg / 2.0 + extent}) {
                double rad = Math.toRadians(ang);
                double px = cx + midR * Math.cos(rad);
                double py = cy - midR * Math.sin(rad);
                g.fill(new Ellipse2D.Double(px - ringWidth / 2.0, py - ringWidth / 2.0, ringWidth, ringWidth));
            }
        }

        g.setFont(EXTRA_BOLD.deriveFont(24f));
        g.setColor(INK);
        FontMetrics vfm = g.getFontMetrics();
        g.drawString(centerValue, cx - vfm.stringWidth(centerValue) / 2, cy + 4);
        g.setFont(SEMI_BOLD.deriveFont(10f));
        g.setColor(MUTED);
        FontMetrics lfm = g.getFontMetrics();
        g.drawString(centerLabel, cx - lfm.stringWidth(centerLabel) / 2, cy + 20);

        int legendX = 248, legendY = cy - (labels.size() * 40) / 2 + 10;
        for (int i = 0; i < labels.size(); i++) {
            int ly = legendY + i * 40;
            Color col = colors.get(i % colors.size());
            g.setColor(col);
            g.fill(new Ellipse2D.Double(legendX, ly - 9, 12, 12));
            g.setColor(INK);
            g.setFont(SEMI_BOLD.deriveFont(12.5f));
            g.drawString(strip(labels.get(i)), legendX + 20, ly + 1);
            double pct = total > 0 ? values.get(i) / total * 100 : 0;
            String sub = String.format(Locale.US, "%.1f L  ·  %.0f%%", values.get(i), pct).replace(".", ",");
            g.setFont(REGULAR.deriveFont(10.5f));
            g.setColor(MUTED);
            g.drawString(sub, legendX + 20, ly + 15);
        }

        g.dispose();
        return img;
    }

    /** Small line icons for the KPI card badges. */
    static BufferedImage icon(String name, Color color, int size) {
        BufferedImage img = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(img);
        g.setColor(color);
        g.setStroke(new BasicStroke(size * 0.11f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        switch (name) {
            case "bars" -> {
                float w = size * 0.16f;
                g.fill(roundedBar(size * 0.18f, size * 0.55f, w, size * 0.3f));
                g.fill(roundedBar(size * 0.42f, size * 0.3f, w, size * 0.55f));
                g.fill(roundedBar(size * 0.66f, size * 0.42f, w, size * 0.43f));
            }
            case "drop" -> {
                GeneralPath p = new GeneralPath();
                float cx = size * 0.5f, topY = size * 0.16f, botY = size * 0.82f;
                p.moveTo(cx, topY);
                p.curveTo(cx + size * 0.34f, size * 0.42f, size * 0.82f, size * 0.6f, size * 0.82f, size * 0.58f);
                p.curveTo(size * 0.82f, botY, size * 0.18f, botY, size * 0.18f, size * 0.58f);
                p.curveTo(size * 0.18f, size * 0.6f, cx - size * 0.34f, size * 0.42f, cx, topY);
                p.closePath();
                g.fill(p);
            }
            case "leaf" -> {
                g.fill(new Ellipse2D.Double(size * 0.18, size * 0.18, size * 0.64, size * 0.64));
                g.setColor(new Color(255, 255, 255, 210));
                g.setStroke(new BasicStroke(size * 0.055f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
                g.draw(new java.awt.geom.Line2D.Double(size * 0.3, size * 0.7, size * 0.68, size * 0.3));
            }
            case "tree" -> {
                GeneralPath p = new GeneralPath();
                p.moveTo(size * 0.5f, size * 0.12f);
                p.lineTo(size * 0.78f, size * 0.52f);
                p.lineTo(size * 0.22f, size * 0.52f);
                p.closePath();
                p.moveTo(size * 0.5f, size * 0.34f);
                p.lineTo(size * 0.84f, size * 0.74f);
                p.lineTo(size * 0.16f, size * 0.74f);
                p.closePath();
                g.fill(p);
                g.fill(roundedBar(size * 0.44f, size * 0.74f, size * 0.12f, size * 0.16f));
            }
            case "coin" -> {
                g.setStroke(new BasicStroke(size * 0.085f));
                g.draw(new Ellipse2D.Double(size * 0.16, size * 0.16, size * 0.68, size * 0.68));
                g.setFont(BOLD.deriveFont(size * 0.38f));
                FontMetrics fm = g.getFontMetrics();
                String s = "$";
                g.drawString(s, size / 2f - fm.stringWidth(s) / 2f, size / 2f + fm.getAscent() * 0.32f);
            }
            case "warning" -> {
                GeneralPath p = new GeneralPath();
                p.moveTo(size * 0.5f, size * 0.12f);
                p.lineTo(size * 0.90f, size * 0.82f);
                p.lineTo(size * 0.10f, size * 0.82f);
                p.closePath();
                g.fill(p);
                g.setColor(new Color(255, 255, 255, 230));
                g.fillRoundRect((int) (size * 0.46f), (int) (size * 0.38f), (int) (size * 0.08f), (int) (size * 0.2f), 4, 4);
                g.fillOval((int) (size * 0.46f), (int) (size * 0.64f), (int) (size * 0.08f), (int) (size * 0.08f));
            }
            default -> g.fill(new Ellipse2D.Double(size * 0.3, size * 0.3, size * 0.4, size * 0.4));
        }
        g.dispose();
        return img;
    }

    private static java.awt.Shape roundedBar(float x, float y, float w, float h) {
        return new java.awt.geom.RoundRectangle2D.Float(x, y, w, h, w, w);
    }

    private static String strip(String s) {
        if (s == null) return "";
        String normalized = Normalizer.normalize(s, Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{M}", "");
    }
}
