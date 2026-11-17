package com.biotrack.api.calculator;

import java.time.Instant;

public record CalculationResponse(
        Long id,
        FuelType fuelType,
        String fuelTypeLabel,
        VehicleType vehicleType,
        String vehicleTypeLabel,
        double fuelLiters,
        String originAddress,
        String destinationAddress,
        double distanceKm,
        boolean distanceEstimated,
        double co2Kg,
        int treesEquivalent,
        double economyBrl,
        boolean anomaly,
        String anomalyReason,
        Instant createdAt
) {
    public static CalculationResponse from(Calculation c) {
        return new CalculationResponse(
                c.getId(), c.getFuelType(), c.getFuelType().getLabel(),
                c.getVehicleType(), c.getVehicleType() == null ? null : c.getVehicleType().getLabel(),
                c.getFuelLiters(),
                c.getOriginAddress(), c.getDestinationAddress(), c.getDistanceKm(), c.isDistanceEstimated(),
                c.getCo2Kg(), c.getTreesEquivalent(), c.getEconomyBrl(),
                c.isAnomaly(), c.getAnomalyReason(), c.getCreatedAt()
        );
    }
}
