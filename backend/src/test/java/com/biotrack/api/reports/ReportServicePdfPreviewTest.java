package com.biotrack.api.reports;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.biotrack.api.calculator.Calculation;
import com.biotrack.api.calculator.CalculationRepository;
import com.biotrack.api.calculator.FuelType;
import com.biotrack.api.calculator.VehicleType;
import com.biotrack.api.dashboard.DashboardService;
import com.biotrack.api.dashboard.TrendPoint;
import com.biotrack.api.user.User;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Exercises the real {@link ReportService#generate} end to end (mocked repositories/services,
 * real PDF rendering via {@link ChartRenderer}) and writes the resulting PDF to
 * {@code target/report-preview.pdf} so it can be converted to images and inspected visually —
 * this is how the modern "dashboard card" redesign was verified against real data wiring
 * (anomaly list, DashboardService trend) rather than the throwaway standalone prototype.
 */
@ExtendWith(MockitoExtension.class)
class ReportServicePdfPreviewTest {

    @Mock
    private ReportRepository reportRepository;
    @Mock
    private CalculationRepository calculationRepository;
    @Mock
    private DashboardService dashboardService;

    @TempDir
    Path storageDir;

    private ReportService reportService;
    private User user;

    @BeforeEach
    void setUp() {
        reportService = new ReportService(reportRepository, calculationRepository,
                dashboardService, storageDir.toString());
        user = new User("maria@exemplo.com", "hash", "Maria Silva");
    }

    @Test
    void generatesAPdfWithKpisAnomaliesChartsAndTable() throws IOException {
        List<Calculation> calcs = buildFixtureCalculations();
        when(calculationRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(calcs);
        when(dashboardService.trend(user)).thenReturn(buildFixtureTrend());
        when(reportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(29);
        GenerateReportRequest req = new GenerateReportRequest(ReportType.AMBIENTAL, ReportPeriod.MENSAL, start, end);

        ReportResponse response = reportService.generate(user, req);
        assertTrue(response.sizeBytes() > 1000, "the PDF should not be empty");

        // Copy the stored PDF to a stable, predictable path for visual review (pdftoppm, etc.).
        Path stored = Files.list(storageDir).findFirst().orElseThrow();
        Path out = Path.of("target/report-preview.pdf");
        Files.copy(stored, out, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
    }

    private List<Calculation> buildFixtureCalculations() {
        List<Calculation> calcs = new ArrayList<>();
        LocalDate end = LocalDate.now();
        FuelType[] fuels = FuelType.values();
        VehicleType[] vehicles = VehicleType.values();
        for (int i = 0; i < 18; i++) {
            FuelType fuel = fuels[i % fuels.length];
            VehicleType vehicle = vehicles[i % vehicles.length];
            double liters = 6 + (i % 7);
            double distanceKm = 12 + (i % 5) * 3;
            double co2 = liters * fuel.getCo2PerLiter();
            double economy = liters * fuel.getEconPerLiter();
            Calculation calc = new Calculation(user, fuel, vehicle, liters, "Av. Paulista, 1000, Sao Paulo - SP",
                    "Rua Augusta, 500, Sao Paulo - SP", distanceKm, false, co2, (int) Math.round(co2 / 21.0), economy);
            setCreatedAt(calc, end.minusDays(i * 1L).atTime(10, 0).atZone(ZoneOffset.UTC).toInstant());
            calcs.add(calc);
        }
        // A couple of calculations flagged anomalous, with realistic (long) messages —
        // exercises the anomaly card's word-wrapping, not just a short placeholder string.
        calcs.get(2).setAnomaly(true,
                "Este calculo esta acima do seu padrao habitual (entre 0.40 e 0.70 L/km, com base nos ultimos 9 "
                        + "calculos com este combustivel). Confira se os valores de litros e os enderecos estao corretos.");
        calcs.get(9).setAnomaly(true,
                "Este calculo esta abaixo do seu padrao habitual (entre 0.35 e 0.65 L/km, com base nos ultimos 6 "
                        + "calculos com este combustivel). Confira se os valores de litros e os enderecos estao corretos.");
        return calcs;
    }

    private List<TrendPoint> buildFixtureTrend() {
        List<TrendPoint> trend = new ArrayList<>();
        String[] months = {"MAI", "JUN", "JUL", "AGO", "SET", "OUT"};
        double[] co2 = {280, 310, 350, 390, 440, 498};
        double[] economy = {210, 235, 260, 290, 330, 372};
        for (int i = 0; i < months.length; i++) {
            trend.add(new TrendPoint(months[i], co2[i], economy[i], false));
        }
        String[] projectedMonths = {"NOV", "DEZ", "JAN"};
        double[] projectedCo2 = {545, 592, 639};
        double[] projectedEconomy = {404, 436, 468};
        for (int i = 0; i < projectedMonths.length; i++) {
            trend.add(new TrendPoint(projectedMonths[i], projectedCo2[i], projectedEconomy[i], true));
        }
        return trend;
    }

    private void setCreatedAt(Calculation calc, Instant createdAt) {
        try {
            var field = Calculation.class.getDeclaredField("createdAt");
            field.setAccessible(true);
            field.set(calc, createdAt);
        } catch (ReflectiveOperationException e) {
            throw new UncheckedIOException(new IOException(e));
        }
    }
}
