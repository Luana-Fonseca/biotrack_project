package com.biotrack.api.calculator;

/**
 * Which vehicle a calculation's fuel was burned in — a categorization label only. CO2/economy
 * factors depend on the fuel itself ({@link FuelType}), not the vehicle, so this never changes
 * the math; it just lets calculations be grouped/filtered/reported by vehicle (carro vs caminhão
 * vs ônibus) instead of only by fuel.
 */
public enum VehicleType {
    CARRO("Carro"),
    CAMINHAO("Caminhão"),
    ONIBUS("Ônibus");

    private final String label;

    VehicleType(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
