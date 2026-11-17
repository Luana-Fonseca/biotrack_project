package com.biotrack.api.dashboard;

public record FuelViabilityResponse(
        String fuelType,
        String fuelLabel,
        int calculations,
        double liters,
        double co2AvoidedKg,
        double economyBrl
) {
}
