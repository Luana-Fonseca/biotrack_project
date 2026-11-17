package com.biotrack.api.calculator;

/** Real, differentiated CO2/economy factors per fossil fuel type, compared against biometano. */
public enum FuelType {
    DIESEL_S10("Diesel S10", 2.60, 2.20),
    DIESEL_B12("Diesel B12", 2.31, 2.00),
    GASOLINA("Gasolina", 2.21, 1.90),
    ETANOL("Etanol", 1.51, 0.80);

    private final String label;
    private final double co2PerLiter;
    private final double econPerLiter;

    FuelType(String label, double co2PerLiter, double econPerLiter) {
        this.label = label;
        this.co2PerLiter = co2PerLiter;
        this.econPerLiter = econPerLiter;
    }

    public String getLabel() {
        return label;
    }

    public double getCo2PerLiter() {
        return co2PerLiter;
    }

    public double getEconPerLiter() {
        return econPerLiter;
    }
}
