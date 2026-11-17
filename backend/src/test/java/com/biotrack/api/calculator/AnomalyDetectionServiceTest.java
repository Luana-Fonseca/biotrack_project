package com.biotrack.api.calculator;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class AnomalyDetectionServiceTest {

    private final AnomalyDetectionService service = new AnomalyDetectionService();

    @Test
    void doesNotFlagAnythingWithFewerThanFivePastCalculations() {
        // A wildly different value, but only 4 points of history — not enough to call a pattern yet.
        AnomalyDetectionService.Result result = service.check(1000.0, List.of(1.0, 1.1, 1.2, 0.9));
        assertFalse(result.anomalous());
    }

    @Test
    void flagsAValueFarOutsideThePastConsistentPattern() {
        List<Double> pastConsumption = List.of(1.0, 1.1, 0.9, 1.05, 0.95, 1.0, 1.1);
        AnomalyDetectionService.Result result = service.check(5.0, pastConsumption);
        assertTrue(result.anomalous());
        assertTrue(result.reason().contains("acima"), "expected the reason to say the value is above the usual pattern: " + result.reason());
    }

    @Test
    void doesNotFlagAValueConsistentWithPastHistory() {
        List<Double> pastConsumption = List.of(1.0, 1.1, 0.9, 1.05, 0.95, 1.0, 1.1);
        AnomalyDetectionService.Result result = service.check(1.02, pastConsumption);
        assertFalse(result.anomalous());
    }

    @Test
    void flagsAnUnusuallyLowValueToo() {
        List<Double> pastConsumption = List.of(10.0, 10.5, 9.8, 10.2, 9.9, 10.1, 10.0);
        AnomalyDetectionService.Result result = service.check(0.1, pastConsumption);
        assertTrue(result.anomalous());
        assertTrue(result.reason().contains("abaixo"), "expected the reason to say the value is below the usual pattern: " + result.reason());
    }
}
