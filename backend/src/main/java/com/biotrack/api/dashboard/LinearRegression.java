package com.biotrack.api.dashboard;

import java.util.List;

/**
 * Ordinary least-squares simple linear regression (y = a + bx) over a small in-memory series —
 * used to project the dashboard's monthly CO2/economy trend a few months forward from its
 * historical values. No external ML library needed for a fit this small (at most a handful of
 * points): the closed-form OLS formulas are a few lines of arithmetic.
 */
final class LinearRegression {

    private final double intercept;
    private final double slope;

    private LinearRegression(double intercept, double slope) {
        this.intercept = intercept;
        this.slope = slope;
    }

    /**
     * Fits a line to {@code (0, ys[0]), (1, ys[1]), ...}. Falls back to a flat line at the last
     * known value (or zero) when there are fewer than two points to fit — a single point has no
     * trend to extrapolate.
     */
    static LinearRegression fit(List<Double> ys) {
        int n = ys.size();
        if (n < 2) {
            return new LinearRegression(n == 1 ? ys.get(0) : 0, 0);
        }
        double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        for (int x = 0; x < n; x++) {
            double y = ys.get(x);
            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumXX += (double) x * x;
        }
        double denominator = n * sumXX - sumX * sumX;
        if (denominator == 0) {
            return new LinearRegression(sumY / n, 0);
        }
        double b = (n * sumXY - sumX * sumY) / denominator;
        double a = (sumY - b * sumX) / n;
        return new LinearRegression(a, b);
    }

    /** y at the given x — negative results are clamped to 0, since a negative monthly CO2/economy total is meaningless. */
    double predict(int x) {
        return Math.max(0, intercept + slope * x);
    }
}
