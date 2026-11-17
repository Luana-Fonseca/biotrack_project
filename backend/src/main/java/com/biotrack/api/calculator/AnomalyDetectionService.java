package com.biotrack.api.calculator;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

/**
 * Flags a new calculation as a possible data-entry mistake (or something worth a second look) by
 * comparing it against the user's own history of the same fuel type. This is plain descriptive
 * statistics — the interquartile-range (IQR) outlier rule — not a trained model: a value more
 * than 1.5x the IQR outside the middle 50% of past values is flagged.
 *
 * <p>Needs at least {@value #MIN_HISTORY} past calculations of the same fuel type before it says
 * anything — with fewer points there's no real "usual pattern" to compare against yet, and a
 * confident-sounding flag on someone's first couple of calculations would do more harm than good.
 */
@Service
public class AnomalyDetectionService {

    static final int MIN_HISTORY = 5;
    private static final double IQR_MULTIPLIER = 1.5;
    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");

    public record Result(boolean anomalous, String reason) {
        static final Result NONE = new Result(false, null);
    }

    /**
     * @param consumptionRate this calculation's liters-per-km (or raw liters when distance isn't
     *                        known) — the metric compared against history.
     * @param pastSameFuelType the same metric computed for the user's past calculations with the
     *                         same fuel type, in any order.
     */
    public Result check(double consumptionRate, List<Double> pastSameFuelType) {
        if (pastSameFuelType.size() < MIN_HISTORY) {
            return Result.NONE;
        }
        List<Double> sorted = new ArrayList<>(pastSameFuelType);
        Collections.sort(sorted);

        double q1 = percentile(sorted, 25);
        double q3 = percentile(sorted, 75);
        double iqr = q3 - q1;
        double lower = q1 - IQR_MULTIPLIER * iqr;
        double upper = q3 + IQR_MULTIPLIER * iqr;

        if (consumptionRate < lower || consumptionRate > upper) {
            String direction = consumptionRate > upper ? "acima" : "abaixo";
            String reason = String.format(PT_BR,
                    "Este cálculo está %s do seu padrão habitual (entre %.2f e %.2f, com base nos últimos %d cálculos com este combustível). "
                            + "Confira se os valores de litros e os endereços estão corretos.",
                    direction, Math.max(0, lower), upper, pastSameFuelType.size());
            return new Result(true, reason);
        }
        return Result.NONE;
    }

    /** Linear-interpolation percentile over an already-sorted list (the common "R type 7" method). */
    private double percentile(List<Double> sorted, double p) {
        if (sorted.size() == 1) {
            return sorted.get(0);
        }
        double rank = (p / 100.0) * (sorted.size() - 1);
        int low = (int) Math.floor(rank);
        int high = (int) Math.ceil(rank);
        if (low == high) {
            return sorted.get(low);
        }
        double fraction = rank - low;
        return sorted.get(low) + fraction * (sorted.get(high) - sorted.get(low));
    }
}
