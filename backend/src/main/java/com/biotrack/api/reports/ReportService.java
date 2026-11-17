package com.biotrack.api.reports;

import com.biotrack.api.calculator.Calculation;
import com.biotrack.api.calculator.CalculationRepository;
import com.biotrack.api.calculator.FuelType;
import com.biotrack.api.calculator.VehicleType;
import com.biotrack.api.common.ApiException;
import com.biotrack.api.dashboard.DashboardService;
import com.biotrack.api.dashboard.TrendPoint;
import com.biotrack.api.user.User;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.time.temporal.ChronoUnit;
import java.time.temporal.IsoFields;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import javax.imageio.ImageIO;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType0Font;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.apache.pdfbox.pdmodel.graphics.state.PDExtendedGraphicsState;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Generates the ESG PDF report: a modern "dashboard card" layout (donut chart, smooth gradient
 * area/line charts, icon-led KPI cards, soft shadows) built with Apache PDFBox — see
 * {@link ChartRenderer} for the raster charts embedded into it.
 */
@Service
public class ReportService {

    private static final DateTimeFormatter PT_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");

    private static final Color INK = new Color(0x1C, 0x22, 0x33);
    private static final Color MUTED = new Color(0x8A, 0x93, 0xA6);
    private static final Color PAGE_BG = new Color(0xF3, 0xF5, 0xFA);
    private static final Color CARD_BG = Color.WHITE;
    private static final Color CARD_BORDER = new Color(0xEC, 0xEE, 0xF5);
    private static final Color BLUE = new Color(0x4F, 0x7C, 0xFF);
    private static final Color BLUE_DARK = new Color(0x2F, 0x4C, 0xC9);
    private static final Color GREEN = new Color(0x1E, 0xC8, 0x8A);
    private static final Color GREEN_DARK = new Color(0x05, 0x96, 0x69);
    private static final Color PURPLE = new Color(0x8B, 0x5C, 0xF6);
    private static final Color AMBER = new Color(0xF5, 0xA5, 0x24);
    private static final Color CORAL = new Color(0xFB, 0x5B, 0x5B);
    private static final List<Color> FUEL_COLORS = List.of(BLUE, GREEN, AMBER, new Color(0x3D, 0xDC, 0xC7));

    private final ReportRepository reportRepository;
    private final CalculationRepository calculationRepository;
    private final DashboardService dashboardService;
    private final Path storageDir;

    public ReportService(ReportRepository reportRepository, CalculationRepository calculationRepository,
                          DashboardService dashboardService,
                          @Value("${biotrack.reports.storage-dir}") String storageDir) {
        this.reportRepository = reportRepository;
        this.calculationRepository = calculationRepository;
        this.dashboardService = dashboardService;
        this.storageDir = Path.of(storageDir);
        try {
            Files.createDirectories(this.storageDir);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    public List<ReportResponse> list(User user) {
        return reportRepository.findByUserOrderByCreatedAtDesc(user).stream().map(ReportResponse::from).toList();
    }

    public ReportResponse generate(User user, GenerateReportRequest req) {
        if (req.periodEnd().isBefore(req.periodStart())) {
            throw ApiException.badRequest("O fim do período não pode ser antes do início.");
        }

        List<Calculation> periodCalcs = calculationRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .filter(c -> {
                    var date = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate();
                    return !date.isBefore(req.periodStart()) && !date.isAfter(req.periodEnd());
                })
                .toList();

        String periodLabel = periodLabel(req.period());
        String monthLabel = req.periodStart().format(DateTimeFormatter.ofPattern("MMMM yyyy", PT_BR));
        String reportName = "Relatorio " + periodLabel + " " + typeLabel(req.type()) + " - " + capitalize(monthLabel);

        byte[] pdfBytes = renderPdf(user, req, reportName, periodLabel, periodCalcs);

        String fileName = user.getId() + "-" + System.currentTimeMillis() + ".pdf";
        Path filePath = storageDir.resolve(fileName);
        try {
            Files.write(filePath, pdfBytes);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }

        Report report = new Report(user, reportName, req.type(), req.period(), req.periodStart(), req.periodEnd(),
                filePath.toString(), pdfBytes.length);
        return ReportResponse.from(reportRepository.save(report));
    }

    public byte[] download(User user, Long id) {
        Report report = reportRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> ApiException.notFound("Relatório não encontrado"));
        try {
            return Files.readAllBytes(Path.of(report.getFilePath()));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    public Report getMeta(User user, Long id) {
        return reportRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> ApiException.notFound("Relatório não encontrado"));
    }

    // ---------------------------------------------------------------------
    // PDF rendering
    // ---------------------------------------------------------------------

    /** Mirrors CalculatorService's private consumptionRate(): liters/km when distance is reliable, else raw liters. */
    private double consumptionRate(double liters, double distanceKm) {
        return distanceKm > 0.5 ? liters / distanceKm : liters;
    }

    private byte[] renderPdf(User user, GenerateReportRequest req, String title, String periodLabel,
                              List<Calculation> calcs) {
        double totalCo2 = sum(calcs, Calculation::getCo2Kg);
        int totalTrees = calcs.stream().mapToInt(Calculation::getTreesEquivalent).sum();
        double totalEconomy = sum(calcs, Calculation::getEconomyBrl);
        double totalLiters = sum(calcs, Calculation::getFuelLiters);
        double biomethaneCo2 = totalCo2 * 0.4;

        List<Calculation> anomalies = calcs.stream().filter(Calculation::isAnomaly).toList();

        try (PDDocument doc = new PDDocument()) {
            PDFont regular = loadFont(doc, "Inter-Regular.ttf");
            PDFont medium = loadFont(doc, "Inter-Medium.ttf");
            PDFont semiBold = loadFont(doc, "Inter-SemiBold.ttf");
            PDFont bold = loadFont(doc, "Inter-Bold.ttf");
            PDFont extraBold = loadFont(doc, "Inter-ExtraBold.ttf");
            Canvas canvas = new Canvas(doc, regular, medium, semiBold, bold, extraBold);

            canvas.headerBand("BioTrack", "Plataforma de sustentabilidade logistica",
                    (periodLabel + " · " + typeLabel(req.type())).toUpperCase());
            canvas.advance(18);
            canvas.text(extraBold, 19, INK, stripAccents(title));
            canvas.advance(24);
            canvas.text(regular, 10.5f, MUTED,
                    "Periodo " + req.periodStart().format(PT_DATE) + " - " + req.periodEnd().format(PT_DATE)
                            + "   ·   " + stripAccents(user.getName()) + " (" + user.getEmail() + ")");
            canvas.advance(13);
            canvas.text(regular, 9, MUTED, "Gerado em " + DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
                    .format(java.time.LocalDateTime.now()) + " UTC");
            canvas.advance(22);

            canvas.sectionLabel("RESUMO DO PERIODO");
            canvas.advance(16);
            canvas.kpiGrid(List.of(
                    new Canvas.Kpi("CALCULOS", String.valueOf(calcs.size()), BLUE, "bars"),
                    new Canvas.Kpi("LITROS", formatNumberComma(totalLiters) + " L", BLUE_DARK, "drop"),
                    new Canvas.Kpi("CO2 EVITADO", String.format(Locale.US, "%.0f kg", totalCo2), GREEN, "leaf"),
                    new Canvas.Kpi("ARVORES EQUIV.", String.valueOf(totalTrees), GREEN, "tree"),
                    new Canvas.Kpi("ECONOMIA", "R$ " + formatNumberComma(totalEconomy), AMBER, "coin")));
            canvas.advance(22);

            if (calcs.isEmpty()) {
                canvas.emptyStateCard("Nenhum calculo registrado neste periodo.");
            } else {
                canvas.sectionLabel("ALERTAS DE CONSUMO FORA DO PADRAO");
                canvas.advance(16);
                canvas.anomalyCard(anomalies);
                canvas.advance(22);

                canvas.sectionLabel("COMBUSTIVEL FOSSIL VS BIOMETANO");
                canvas.advance(16);
                BufferedImage chart1 = ChartRenderer.gradientBarChart(
                        List.of("Combustivel fossil", "Biometano"), List.of(totalCo2, biomethaneCo2),
                        List.of(CORAL, GREEN), 480, 230, "kg CO2");
                canvas.imageCard(chart1, 480, 230);
                canvas.advance(10);
                canvas.paragraph(regular, 8.5f, MUTED,
                        "Compara o total de CO2 que os combustiveis fosseis registrados neste periodo emitiriam com o CO2 estimado usando Biometano no lugar deles. O Biometano emite, em media, 60% menos CO2 que o equivalente fossil, o que explica a diferenca entre as duas barras.");
                canvas.advance(14);

                Map<String, Double> trend = trendBuckets(calcs, req.periodStart(), req.periodEnd());
                canvas.sectionLabel("EVOLUCAO DE CO2 EVITADO NO PERIODO");
                canvas.advance(16);
                BufferedImage chart2 = ChartRenderer.smoothAreaChart(
                        new ArrayList<>(trend.keySet()), toArray(trend.values()), BLUE, 480, 230, "kg", -1);
                canvas.imageCard(chart2, 480, 230);
                canvas.advance(10);
                canvas.paragraph(regular, 8.5f, MUTED,
                        "Soma o CO2 evitado calculo a calculo ao longo do periodo selecionado, agrupado por dia, semana ou mes conforme a duracao do periodo. Picos indicam dias/semanas de maior operacao com Biometano; quedas indicam periodos de menor volume ou sem registros.");
                canvas.advance(14);

                List<TrendPoint> co2Trend = dashboardService.trend(user);
                if (co2Trend.size() >= 2) {
                    canvas.sectionLabel("TENDENCIA E PROJECAO (REGRESSAO LINEAR)");
                    canvas.advance(16);
                    List<String> trendLabels = co2Trend.stream().map(TrendPoint::label).toList();
                    double[] trendValues = co2Trend.stream().mapToDouble(TrendPoint::co2Kg).toArray();
                    int historyCount = (int) co2Trend.stream().filter(p -> !p.projected()).count();
                    BufferedImage chart4 = ChartRenderer.smoothAreaChart(
                            trendLabels, trendValues, PURPLE, 480, 230, "kg", historyCount - 1);
                    canvas.imageCard(chart4, 480, 230);
                    canvas.advance(10);
                    canvas.paragraph(regular, 8.5f, MUTED,
                            "Usa os ultimos meses de historico completo do usuario (linha solida) para projetar os proximos meses (linha tracejada), ajudando a antecipar a tendencia de CO2 evitado se o ritmo atual de uso de Biometano se mantiver.");
                    canvas.advance(4);
                    canvas.text(regular, 8.5f, MUTED,
                            "* Projetado por regressao linear (minimos quadrados) sobre os ultimos meses. Nao e garantia, e estimativa estatistica.");
                    canvas.advance(22);
                }

                Map<FuelType, Double> litersByFuel = new LinkedHashMap<>();
                for (FuelType ft : FuelType.values()) {
                    double l = calcs.stream().filter(c -> c.getFuelType() == ft).mapToDouble(Calculation::getFuelLiters).sum();
                    if (l > 0) litersByFuel.put(ft, l);
                }
                if (!litersByFuel.isEmpty()) {
                    canvas.sectionLabel("LITROS POR TIPO DE COMBUSTIVEL");
                    canvas.advance(16);
                    BufferedImage donut = ChartRenderer.donutChart(
                            litersByFuel.keySet().stream().map(ft -> stripAccents(ft.getLabel())).toList(),
                            new ArrayList<>(litersByFuel.values()), FUEL_COLORS, 480, 240,
                            formatNumberComma(totalLiters) + " L", "TOTAL");
                    canvas.imageCard(donut, 480, 240);
                    canvas.advance(10);
                    canvas.paragraph(regular, 8.5f, MUTED,
                            "Mostra como os litros registrados neste periodo se dividem entre os tipos de combustivel fossil comparados ao Biometano, revelando qual combustivel concentra a maior parte da operacao.");
                    canvas.advance(14);
                }

                canvas.sectionLabel("DETALHAMENTO POR TIPO DE COMBUSTIVEL");
                canvas.advance(16);
                List<String[]> rows = new ArrayList<>();
                for (FuelType ft : FuelType.values()) {
                    List<Calculation> ftCalcs = calcs.stream().filter(c -> c.getFuelType() == ft).toList();
                    if (ftCalcs.isEmpty()) continue;
                    double liters = sum(ftCalcs, Calculation::getFuelLiters);
                    double co2 = sum(ftCalcs, Calculation::getCo2Kg);
                    double economy = sum(ftCalcs, Calculation::getEconomyBrl);
                    rows.add(new String[]{
                            stripAccents(ft.getLabel()) + " (" + ftCalcs.size() + ")",
                            formatNumberComma(liters) + " L",
                            String.format(Locale.US, "%.0f kg CO2", co2),
                            "R$ " + formatNumberComma(economy)
                    });
                }
                canvas.table(new String[]{"Combustivel", "Litros", "CO2 evitado", "Economia"}, rows);
                canvas.advance(22);

                List<String[]> vehicleRows = new ArrayList<>();
                for (VehicleType vt : VehicleType.values()) {
                    List<Calculation> vtCalcs = calcs.stream().filter(c -> c.getVehicleType() == vt).toList();
                    if (vtCalcs.isEmpty()) continue;
                    double liters = sum(vtCalcs, Calculation::getFuelLiters);
                    double co2 = sum(vtCalcs, Calculation::getCo2Kg);
                    double economy = sum(vtCalcs, Calculation::getEconomyBrl);
                    vehicleRows.add(new String[]{
                            stripAccents(vt.getLabel()) + " (" + vtCalcs.size() + ")",
                            formatNumberComma(liters) + " L",
                            String.format(Locale.US, "%.0f kg CO2", co2),
                            "R$ " + formatNumberComma(economy)
                    });
                }
                if (!vehicleRows.isEmpty()) {
                    canvas.sectionLabel("DETALHAMENTO POR TIPO DE VEICULO");
                    canvas.advance(16);
                    canvas.table(new String[]{"Veiculo", "Litros", "CO2 evitado", "Economia"}, vehicleRows);
                    canvas.advance(22);
                }

                canvas.sectionLabel("RESUMO DOS RESULTADOS");
                canvas.advance(16);
                canvas.paragraph(regular, 9.5f, INK, resultsSummary(calcs, totalCo2, totalTrees, totalEconomy,
                        anomalies.size()));
                canvas.advance(18);
            }

            canvas.paragraph(regular, 8.5f, MUTED,
                    "CO2 evitado, arvores equivalentes e economia sao estimativas calculadas a partir dos fatores de emissao/economia por combustivel definidos no app, nao medicoes de laboratorio.");
            canvas.advance(4);
            canvas.paragraph(regular, 8.5f, MUTED,
                    "Alertas de consumo fora do padrao usam a regra estatistica do intervalo interquartil (IQR) sobre o historico do proprio usuario para o mesmo combustivel, e exigem pelo menos 5 calculos anteriores para serem avaliados.");
            canvas.advance(4);
            canvas.paragraph(regular, 8.5f, MUTED,
                    "A projecao de tendencia usa regressao linear simples (minimos quadrados) sobre os ultimos meses de historico e nao considera sazonalidade.");
            canvas.advance(4);
            canvas.paragraph(regular, 8.5f, MUTED,
                    "Enderecos sao normalizados automaticamente (expansao de abreviacoes) antes do calculo de distancia, mantendo sempre o numero do imovel informado.");

            canvas.close();
            canvas.stampFooters(regular, "BioTrack - Relatorio ESG gerado automaticamente - MVP v1.0.0");

            var out = new ByteArrayOutputStream();
            doc.save(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static PDFont loadFont(PDDocument doc, String resourceName) throws IOException {
        try (InputStream in = ReportService.class.getResourceAsStream("/fonts/" + resourceName)) {
            return PDType0Font.load(doc, in);
        }
    }

    private static double[] toArray(java.util.Collection<Double> values) {
        return values.stream().mapToDouble(Double::doubleValue).toArray();
    }

    private static String formatNumberComma(double v) {
        return String.format(Locale.US, "%.1f", v).replace(".", ",");
    }

    /** Buckets CO2-evitado into at most ~12 points across the period: daily if short, weekly/monthly if longer. */
    private Map<String, Double> trendBuckets(List<Calculation> calcs, LocalDate start, LocalDate end) {
        long days = ChronoUnit.DAYS.between(start, end) + 1;
        Map<String, Double> labeled = new LinkedHashMap<>();

        if (days <= 14) {
            Map<LocalDate, Double> byDay = new TreeMap<>();
            for (LocalDate d = start; !d.isAfter(end); d = d.plusDays(1)) byDay.put(d, 0.0);
            for (Calculation c : calcs) {
                LocalDate d = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate();
                byDay.merge(d, c.getCo2Kg(), Double::sum);
            }
            byDay.forEach((d, v) -> labeled.put(d.format(DateTimeFormatter.ofPattern("dd/MM")), v));
        } else if (days <= 90) {
            // Keyed by (week-based year, week) so buckets sort chronologically regardless of the
            // order calcs arrive in (the repository returns them newest-first).
            Map<Integer, Double> byWeek = new TreeMap<>();
            Map<Integer, String> weekLabels = new java.util.HashMap<>();
            for (Calculation c : calcs) {
                LocalDate d = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate();
                int week = d.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR);
                int sortKey = d.get(IsoFields.WEEK_BASED_YEAR) * 100 + week;
                byWeek.merge(sortKey, c.getCo2Kg(), Double::sum);
                weekLabels.putIfAbsent(sortKey, "Sem " + week);
            }
            byWeek.forEach((k, v) -> labeled.put(weekLabels.get(k), v));
        } else {
            Map<java.time.YearMonth, Double> byMonth = new TreeMap<>();
            for (Calculation c : calcs) {
                LocalDate d = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate();
                byMonth.merge(java.time.YearMonth.from(d), c.getCo2Kg(), Double::sum);
            }
            byMonth.forEach((ym, v) -> labeled.put(ym.getMonth().getDisplayName(TextStyle.SHORT, PT_BR).toUpperCase(), v));
        }
        if (labeled.size() < 2) {
            labeled.put(labeled.isEmpty() ? "Sem dados" : "-", 0.0);
        }
        return labeled;
    }

    private double sum(List<Calculation> list, java.util.function.ToDoubleFunction<Calculation> fn) {
        return list.stream().mapToDouble(fn).sum();
    }

    /** Plain-language close-out of the period's numbers, written for a non-technical stakeholder reading the PDF. */
    private String resultsSummary(List<Calculation> calcs, double totalCo2, int totalTrees, double totalEconomy,
                                   int anomalyCount) {
        StringBuilder sb = new StringBuilder();
        sb.append("Neste periodo foram registrados ").append(calcs.size())
                .append(calcs.size() == 1 ? " calculo" : " calculos")
                .append(", evitando ao todo ").append(String.format(Locale.US, "%.0f", totalCo2))
                .append(" kg de CO2 ao optar por Biometano em vez de combustiveis fosseis - o equivalente ao que ")
                .append(totalTrees).append(totalTrees == 1 ? " arvore" : " arvores")
                .append(" absorveriam em um ano. A economia estimada no periodo foi de R$ ")
                .append(formatNumberComma(totalEconomy)).append(". ");
        sb.append(anomalyCount == 0
                ? "Nenhum calculo fora do padrao foi identificado no periodo."
                : (anomalyCount == 1 ? "1 calculo fora do padrao foi identificado e deve ser revisado."
                        : anomalyCount + " calculos fora do padrao foram identificados e devem ser revisados."));
        return sb.toString();
    }

    private String periodLabel(ReportPeriod period) {
        return switch (period) {
            case DIARIO -> "Diario";
            case SEMANAL -> "Semanal";
            case MENSAL -> "Mensal";
            case PERSONALIZADO -> "Personalizado";
        };
    }

    private String typeLabel(ReportType type) {
        return switch (type) {
            case AMBIENTAL -> "ESG - Ambiental";
            case SOCIAL -> "ESG - Social";
            case GOVERNANCA -> "ESG - Governanca";
        };
    }

    private String capitalize(String s) {
        return s.isBlank() ? s : Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    private String stripAccents(String s) {
        if (s == null) return "";
        String normalized = java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{M}", "");
    }

    /**
     * Multi-page PDF cursor for the "dashboard card" layout: every section (KPI grid,
     * anomaly alerts, chart, table) draws inside a white rounded card with a soft shadow,
     * floating over a light-gray page background.
     */
    private final class Canvas implements AutoCloseable {
        private final PDDocument doc;
        private static final float MARGIN = 42;
        private static final float PAGE_W = PDRectangle.A4.getWidth();
        private static final float PAGE_H = PDRectangle.A4.getHeight();
        private final PDFont regular;
        private final PDFont medium;
        private final PDFont semiBold;
        private final PDFont bold;
        private final PDFont extraBold;
        private final List<PDPage> pages = new ArrayList<>();
        private PDPage page;
        private PDPageContentStream cs;
        private float y;
        private float cardTopBeforeDraw;
        private float cardX;

        record Kpi(String label, String value, Color color, String icon) {
        }

        Canvas(PDDocument doc, PDFont regular, PDFont medium, PDFont semiBold, PDFont bold, PDFont extraBold) throws IOException {
            this.doc = doc;
            this.regular = regular;
            this.medium = medium;
            this.semiBold = semiBold;
            this.bold = bold;
            this.extraBold = extraBold;
            newPage();
        }

        private void newPage() throws IOException {
            if (cs != null) cs.close();
            page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            pages.add(page);
            cs = new PDPageContentStream(doc, page);
            cs.setNonStrokingColor(PAGE_BG);
            cs.addRect(0, 0, PAGE_W, PAGE_H);
            cs.fill();
            y = PAGE_H - MARGIN;
        }

        private void ensureSpace(float needed) throws IOException {
            if (y - needed < MARGIN + 24) newPage();
        }

        void advance(float amount) {
            y -= amount;
        }

        private void setAlpha(float fillA, float strokeA) throws IOException {
            PDExtendedGraphicsState gs = new PDExtendedGraphicsState();
            gs.setNonStrokingAlphaConstant(fillA);
            gs.setStrokingAlphaConstant(strokeA);
            cs.setGraphicsStateParameters(gs);
        }

        private void roundedRectPath(float x, float yy, float w, float h, float r) throws IOException {
            float k = r * 0.5523f;
            cs.moveTo(x + r, yy);
            cs.lineTo(x + w - r, yy);
            cs.curveTo(x + w - r + k, yy, x + w, yy + r - k, x + w, yy + r);
            cs.lineTo(x + w, yy + h - r);
            cs.curveTo(x + w, yy + h - r + k, x + w - r + k, yy + h, x + w - r, yy + h);
            cs.lineTo(x + r, yy + h);
            cs.curveTo(x + r - k, yy + h, x, yy + h - r + k, x, yy + h - r);
            cs.lineTo(x, yy + r);
            cs.curveTo(x, yy + r - k, x + r - k, yy, x + r, yy);
            cs.closePath();
        }

        private void softShadow(float x, float yy, float w, float h, float r) throws IOException {
            setAlpha(0.05f, 1f);
            cs.setNonStrokingColor(INK);
            roundedRectPath(x - 2, yy - 5, w + 4, h, r + 2);
            cs.fill();
            setAlpha(0.04f, 1f);
            roundedRectPath(x - 1, yy - 3, w + 2, h, r + 1);
            cs.fill();
            setAlpha(1f, 1f);
        }

        /** Begins a card of the given height at the current cursor; advances {@code y} past it. */
        void cardBegin(float height) throws IOException {
            ensureSpace(height + 8);
            float x = MARGIN, w = PAGE_W - 2 * MARGIN, top = y, bottom = y - height;
            softShadow(x, bottom, w, height, 16);
            cs.setNonStrokingColor(CARD_BG);
            roundedRectPath(x, bottom, w, height, 16);
            cs.fill();
            cs.setStrokingColor(CARD_BORDER);
            cs.setLineWidth(1f);
            roundedRectPath(x, bottom, w, height, 16);
            cs.stroke();
            cardTopBeforeDraw = top;
            cardX = x;
            y -= height;
        }

        void text(PDFont font, float size, Color color, String value) throws IOException {
            ensureSpace(size + 4);
            cs.setNonStrokingColor(color);
            cs.beginText();
            cs.setFont(font, size);
            cs.newLineAtOffset(MARGIN, y);
            cs.showText(value == null ? "" : value);
            cs.endText();
        }

        private void textAt(PDFont font, float size, Color color, float x, float yy, String value) throws IOException {
            cs.setNonStrokingColor(color);
            cs.beginText();
            cs.setFont(font, size);
            cs.newLineAtOffset(x, yy);
            cs.showText(value == null ? "" : value);
            cs.endText();
        }

        private void textFitted(PDFont font, float maxSize, float minSize, float maxWidth, Color color, float x, float yy, String value) throws IOException {
            float size = maxSize;
            while (size > minSize && font.getStringWidth(value) / 1000f * size > maxWidth) {
                size -= 0.5f;
            }
            textAt(font, size, color, x, yy, value);
        }

        private List<String> wrapLines(PDFont font, float size, String value, float maxWidth) throws IOException {
            List<String> lines = new ArrayList<>();
            StringBuilder line = new StringBuilder();
            for (String word : value.split(" ")) {
                String candidate = line.isEmpty() ? word : line + " " + word;
                float width = font.getStringWidth(candidate) / 1000f * size;
                if (width > maxWidth && !line.isEmpty()) {
                    lines.add(line.toString());
                    line = new StringBuilder(word);
                } else {
                    line = new StringBuilder(candidate);
                }
            }
            if (!line.isEmpty()) lines.add(line.toString());
            return lines;
        }

        void paragraph(PDFont font, float size, Color color, String value) throws IOException {
            for (String line : wrapLines(font, size, value, PAGE_W - 2 * MARGIN)) {
                text(font, size, color, line);
                y -= size + 4;
            }
        }

        void headerBand(String wordmark, String tagline, String badge) throws IOException {
            float bandHeight = 74;
            cs.setNonStrokingColor(BLUE_DARK);
            roundedRectPath(0, PAGE_H - bandHeight - 14, PAGE_W, bandHeight + 14, 0);
            cs.fill();
            setAlpha(0.10f, 1f);
            cs.setNonStrokingColor(Color.WHITE);
            cs.moveTo(PAGE_W * 0.55f, PAGE_H);
            cs.lineTo(PAGE_W, PAGE_H);
            cs.lineTo(PAGE_W, PAGE_H - bandHeight - 14);
            cs.lineTo(PAGE_W * 0.8f, PAGE_H - bandHeight - 14);
            cs.closePath();
            cs.fill();
            setAlpha(1f, 1f);

            textAt(extraBold, 21, Color.WHITE, MARGIN, PAGE_H - 34, wordmark);
            textAt(regular, 10, new Color(255, 255, 255, 215), MARGIN, PAGE_H - 50, tagline);

            float badgeSize = 9.5f;
            float badgeWidth = semiBold.getStringWidth(badge) / 1000f * badgeSize + 26;
            float badgeX = PAGE_W - MARGIN - badgeWidth;
            float badgeY = PAGE_H - 42;
            setAlpha(0.16f, 1f);
            cs.setNonStrokingColor(Color.WHITE);
            roundedRectPath(badgeX, badgeY, badgeWidth, 20, 10);
            cs.fill();
            setAlpha(1f, 1f);
            textAt(semiBold, badgeSize, Color.WHITE, badgeX + 13, badgeY + 6.5f, badge);

            y = PAGE_H - bandHeight - 14 - 26;
        }

        void sectionLabel(String text) throws IOException {
            ensureSpace(16);
            cs.setNonStrokingColor(MUTED);
            cs.beginText();
            cs.setFont(bold, 10.5f);
            cs.newLineAtOffset(MARGIN, y);
            cs.showText(text);
            cs.endText();
        }

        void kpiGrid(List<Kpi> kpis) throws IOException {
            int cols = kpis.size();
            float gap = 10;
            float cardH = 92;
            float cardW = (PAGE_W - 2 * MARGIN - gap * (cols - 1)) / cols;
            ensureSpace(cardH + 6);
            float top = y, bottom = y - cardH;
            for (int i = 0; i < kpis.size(); i++) {
                float cardXi = MARGIN + i * (cardW + gap);
                softShadow(cardXi, bottom, cardW, cardH, 14);
                cs.setNonStrokingColor(CARD_BG);
                roundedRectPath(cardXi, bottom, cardW, cardH, 14);
                cs.fill();
                cs.setStrokingColor(CARD_BORDER);
                cs.setLineWidth(1f);
                roundedRectPath(cardXi, bottom, cardW, cardH, 14);
                cs.stroke();

                Kpi kpi = kpis.get(i);
                float iconSize = 30;
                float iconX = cardXi + 14, iconY = top - 14 - iconSize;
                setAlpha(0.13f, 1f);
                cs.setNonStrokingColor(kpi.color());
                roundedRectPath(iconX, iconY, iconSize, iconSize, 9);
                cs.fill();
                setAlpha(1f, 1f);
                BufferedImage icon = ChartRenderer.icon(kpi.icon(), kpi.color(), 44);
                var bos = new ByteArrayOutputStream();
                ImageIO.write(icon, "png", bos);
                PDImageXObject iconXObj = PDImageXObject.createFromByteArray(doc, bos.toByteArray(), "icon" + i);
                float pad = iconSize * 0.16f;
                cs.drawImage(iconXObj, iconX + pad / 2, iconY + pad / 2, iconSize - pad, iconSize - pad);

                textAt(semiBold, 7.6f, MUTED, cardXi + 14, bottom + 16, kpi.label());
                textFitted(extraBold, 16.5f, 11f, cardW - 24, INK, cardXi + 14, bottom + 32, kpi.value());
            }
            y = bottom;
        }


        void emptyStateCard(String message) throws IOException {
            cardBegin(44);
            textAt(medium, 11, MUTED, cardX + 20, cardTopBeforeDraw - 27, message);
        }

        void anomalyCard(List<Calculation> anomalies) throws IOException {
            if (anomalies.isEmpty()) {
                cardBegin(44);
                float top = cardTopBeforeDraw;
                cs.setNonStrokingColor(GREEN);
                cs.addRect(cardX + 20, top - 26, 8, 8);
                cs.fill();
                textAt(semiBold, 10.5f, INK, cardX + 38, top - 29, "Nenhum calculo fora do padrao neste periodo.");
                return;
            }

            float innerWidth = PAGE_W - 2 * MARGIN - 2 * 20 - 36;
            List<List<String>> wrappedReasons = new ArrayList<>();
            for (Calculation c : anomalies) {
                wrappedReasons.add(wrapLines(regular, 8.5f, stripAccents(c.getAnomalyReason()), innerWidth));
            }
            float gapToReason = 13, reasonLineH = 11.5f, rowGap = 14;
            float totalH = 18;
            for (List<String> lines : wrappedReasons) totalH += gapToReason + lines.size() * reasonLineH + rowGap;

            cardBegin(totalH);
            float rowY = cardTopBeforeDraw - 18;
            for (int i = 0; i < anomalies.size(); i++) {
                Calculation c = anomalies.get(i);
                double rate = consumptionRate(c.getFuelLiters(), c.getDistanceKm());
                String date = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate().format(PT_DATE);
                String rateText = formatNumberComma(rate) + (c.isDistanceEstimated() || c.getDistanceKm() <= 0.5 ? " L" : " L/km");
                List<String> lines = wrappedReasons.get(i);

                setAlpha(0.15f, 1f);
                cs.setNonStrokingColor(AMBER);
                roundedRectPath(cardX + 18, rowY - 8, 26, 26, 8);
                cs.fill();
                setAlpha(1f, 1f);
                cs.setNonStrokingColor(AMBER);
                cs.addRect(cardX + 29, rowY + 1, 4, 9);
                cs.fill();
                cs.addRect(cardX + 29, rowY - 3, 4, 2);
                cs.fill();

                textAt(semiBold, 10, INK, cardX + 56, rowY + 4,
                        date + "   ·   " + stripAccents(c.getFuelType().getLabel()) + "   ·   " + rateText);
                float ly = rowY - gapToReason;
                for (String line : lines) {
                    textAt(regular, 8.5f, MUTED, cardX + 56, ly, line);
                    ly -= reasonLineH;
                }
                rowY -= gapToReason + lines.size() * reasonLineH + rowGap;
            }
        }

        void imageCard(BufferedImage img, int widthPx, int heightPx) throws IOException {
            float innerPad = 18;
            float contentW = PAGE_W - 2 * MARGIN - 2 * innerPad;
            float contentH = heightPx * (contentW / widthPx);
            float cardH = contentH + 2 * innerPad;
            cardBegin(cardH);
            var bos = new ByteArrayOutputStream();
            ImageIO.write(img, "png", bos);
            PDImageXObject image = PDImageXObject.createFromByteArray(doc, bos.toByteArray(), "chart");
            cs.drawImage(image, MARGIN + innerPad, (cardTopBeforeDraw - cardH) + innerPad, contentW, contentH);
        }

        void table(String[] headers, List<String[]> rows) throws IOException {
            float rowH = 30;
            float headerH = 32;
            float h = headerH + rows.size() * rowH + 12;
            cardBegin(h);
            float top = cardTopBeforeDraw - 12;
            int cols = headers.length;
            float tableW = PAGE_W - 2 * MARGIN - 2 * 20;
            float[] colW = {tableW * 0.38f, tableW * 0.2f, tableW * 0.22f, tableW * 0.2f};

            float cx = cardX + 20 + 6;
            for (int i = 0; i < cols; i++) {
                textAt(semiBold, 8.5f, MUTED, cx, top - headerH + 12, headers[i].toUpperCase(Locale.ROOT));
                cx += colW[i];
            }
            cs.setStrokingColor(CARD_BORDER);
            cs.setLineWidth(1f);
            cs.moveTo(cardX + 20, top - headerH);
            cs.lineTo(cardX + 20 + tableW, top - headerH);
            cs.stroke();

            float rowTop = top - headerH;
            for (int r = 0; r < rows.size(); r++) {
                if (r % 2 == 1) {
                    cs.setNonStrokingColor(new Color(0xF7, 0xF8, 0xFC));
                    cs.addRect(cardX + 8, rowTop - rowH, tableW + 24, rowH);
                    cs.fill();
                }
                float colX = cardX + 20 + 6;
                String[] cells = rows.get(r);
                for (int i = 0; i < cols; i++) {
                    PDFont f = i == 0 ? semiBold : regular;
                    Color col = i == 0 ? INK : MUTED;
                    textAt(f, 9.5f, col, colX, rowTop - rowH + 11, i < cells.length ? cells[i] : "");
                    colX += colW[i];
                }
                rowTop -= rowH;
            }
        }

        void stampFooters(PDFont footerFont, String footerText) throws IOException {
            int total = pages.size();
            for (int i = 0; i < total; i++) {
                try (PDPageContentStream footerCs = new PDPageContentStream(doc, pages.get(i),
                        PDPageContentStream.AppendMode.APPEND, true)) {
                    footerCs.setStrokingColor(CARD_BORDER);
                    footerCs.setLineWidth(0.6f);
                    footerCs.moveTo(MARGIN, MARGIN - 10);
                    footerCs.lineTo(PAGE_W - MARGIN, MARGIN - 10);
                    footerCs.stroke();

                    footerCs.setNonStrokingColor(MUTED);
                    footerCs.beginText();
                    footerCs.setFont(footerFont, 8);
                    footerCs.newLineAtOffset(MARGIN, MARGIN - 22);
                    footerCs.showText(footerText);
                    footerCs.endText();

                    String pageLabel = "Pagina " + (i + 1) + " de " + total;
                    float w = footerFont.getStringWidth(pageLabel) / 1000f * 8;
                    footerCs.beginText();
                    footerCs.setFont(footerFont, 8);
                    footerCs.newLineAtOffset(PAGE_W - MARGIN - w, MARGIN - 22);
                    footerCs.showText(pageLabel);
                    footerCs.endText();
                }
            }
        }

        @Override
        public void close() throws IOException {
            if (cs != null) {
                cs.close();
                cs = null;
            }
        }
    }
}
