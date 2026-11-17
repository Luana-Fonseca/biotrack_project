package com.biotrack.api.dashboard;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import org.junit.jupiter.api.Test;

class LinearRegressionTest {

    @Test
    void fitsAnExactLineThroughPerfectlyLinearPoints() {
        // y = 10 + 5x for x = 0..4
        LinearRegression reg = LinearRegression.fit(List.of(10.0, 15.0, 20.0, 25.0, 30.0));
        assertEquals(35.0, reg.predict(5), 0.001);
        assertEquals(40.0, reg.predict(6), 0.001);
    }

    @Test
    void fitsAFlatLineForConstantValues() {
        LinearRegression reg = LinearRegression.fit(List.of(100.0, 100.0, 100.0));
        assertEquals(100.0, reg.predict(10), 0.001);
    }

    @Test
    void singlePointProjectsAsFlatAtThatValue() {
        LinearRegression reg = LinearRegression.fit(List.of(42.0));
        assertEquals(42.0, reg.predict(3), 0.001);
    }

    @Test
    void emptySeriesProjectsAsZero() {
        LinearRegression reg = LinearRegression.fit(List.of());
        assertEquals(0.0, reg.predict(3), 0.001);
    }

    @Test
    void negativeProjectionIsClampedToZero() {
        // Sharp downward trend: y = 10 - 5x would go negative past x=2.
        LinearRegression reg = LinearRegression.fit(List.of(10.0, 5.0, 0.0));
        assertEquals(0.0, reg.predict(5), 0.001);
    }
}
