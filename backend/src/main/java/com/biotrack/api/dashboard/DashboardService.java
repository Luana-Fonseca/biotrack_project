package com.biotrack.api.dashboard;

import com.biotrack.api.calculator.Calculation;
import com.biotrack.api.calculator.CalculationRepository;
import com.biotrack.api.calculator.FuelType;
import com.biotrack.api.user.User;
import com.biotrack.api.user.UserService;
import java.time.ZoneOffset;
import java.time.format.TextStyle;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class DashboardService {

    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");

    private final CalculationRepository calculationRepository;
    private final UserService userService;

    public DashboardService(CalculationRepository calculationRepository, UserService userService) {
        this.calculationRepository = calculationRepository;
        this.userService = userService;
    }

    public DashboardSummaryResponse summary(User user) {
        List<Calculation> calcs = calculationRepository.findByUserOrderByCreatedAtDesc(user);
        double totalCo2 = calcs.stream().mapToDouble(Calculation::getCo2Kg).sum();
        double totalEconomy = calcs.stream().mapToDouble(Calculation::getEconomyBrl).sum();
        int totalTrees = calcs.stream().mapToInt(Calculation::getTreesEquivalent).sum();
        int[] rankAndTotal = userService.rankAndTotal(user);
        return new DashboardSummaryResponse(calcs.size(), totalCo2, totalEconomy, totalTrees,
                user.getXp(), user.getStreakDays(), rankAndTotal[0], rankAndTotal[1]);
    }

    private static final int HISTORY_MONTHS = 6;
    private static final int PROJECTED_MONTHS = 3;

    /**
     * Last 6 calendar months of real data (oldest first), plus {@value #PROJECTED_MONTHS} more
     * months projected forward with a simple linear regression ({@link LinearRegression}) fitted
     * on those same 6 historical totals — each projected point is flagged {@code projected=true}
     * so the chart can draw it differently (dashed) instead of passing it off as measured data.
     */
    public List<TrendPoint> trend(User user) {
        List<Calculation> calcs = calculationRepository.findByUserOrderByCreatedAtDesc(user);
        Map<String, double[]> byMonth = new LinkedHashMap<>();
        var now = java.time.LocalDate.now();
        for (int i = HISTORY_MONTHS - 1; i >= 0; i--) {
            var month = now.minusMonths(i);
            String key = month.getMonth().getDisplayName(TextStyle.SHORT, PT_BR).toUpperCase();
            byMonth.put(key, new double[2]);
        }
        for (Calculation c : calcs) {
            var date = c.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate();
            String key = date.getMonth().getDisplayName(TextStyle.SHORT, PT_BR).toUpperCase();
            if (byMonth.containsKey(key)) {
                double[] agg = byMonth.get(key);
                agg[0] += c.getCo2Kg();
                agg[1] += c.getEconomyBrl();
            }
        }

        List<TrendPoint> historical = byMonth.entrySet().stream()
                .map(e -> new TrendPoint(e.getKey(), e.getValue()[0], e.getValue()[1], false))
                .toList();

        LinearRegression co2Trend = LinearRegression.fit(historical.stream().map(TrendPoint::co2Kg).toList());
        LinearRegression economyTrend = LinearRegression.fit(historical.stream().map(TrendPoint::economyBrl).toList());

        List<TrendPoint> projected = new java.util.ArrayList<>();
        for (int i = 1; i <= PROJECTED_MONTHS; i++) {
            var month = now.plusMonths(i);
            String key = month.getMonth().getDisplayName(TextStyle.SHORT, PT_BR).toUpperCase();
            int x = HISTORY_MONTHS - 1 + i;
            projected.add(new TrendPoint(key, co2Trend.predict(x), economyTrend.predict(x), true));
        }

        List<TrendPoint> combined = new java.util.ArrayList<>(historical);
        combined.addAll(projected);
        return combined;
    }

    /**
     * One entry per {@link FuelType} the calculator offers — not just diesel — so the user can
     * compare every fossil fuel against biometano, each totalled from their own logged
     * calculations. Fuels with no calculations yet still appear, zeroed out.
     */
    public List<FuelViabilityResponse> fuelViability(User user) {
        List<Calculation> calcs = calculationRepository.findByUserOrderByCreatedAtDesc(user);
        // [count, liters, co2AvoidedKg, economyBrl] per fuel, zeroed for fuels never logged.
        Map<FuelType, double[]> byFuel = new EnumMap<>(FuelType.class);
        for (FuelType ft : FuelType.values()) {
            byFuel.put(ft, new double[4]);
        }
        for (Calculation c : calcs) {
            double[] agg = byFuel.get(c.getFuelType());
            agg[0]++;
            agg[1] += c.getFuelLiters();
            agg[2] += c.getCo2Kg();
            agg[3] += c.getEconomyBrl();
        }
        return java.util.Arrays.stream(FuelType.values())
                .map(ft -> {
                    double[] agg = byFuel.get(ft);
                    return new FuelViabilityResponse(ft.name(), ft.getLabel(), (int) agg[0], agg[1], agg[2], agg[3]);
                })
                .toList();
    }
}
