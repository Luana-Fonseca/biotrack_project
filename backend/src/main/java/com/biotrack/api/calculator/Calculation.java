package com.biotrack.api.calculator;

import com.biotrack.api.user.User;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "calculations")
public class Calculation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private User user;

    @Enumerated(EnumType.STRING)
    private FuelType fuelType;

    @Enumerated(EnumType.STRING)
    private VehicleType vehicleType;

    private double fuelLiters;

    private String originAddress;
    private String destinationAddress;
    private double distanceKm;
    private boolean distanceEstimated;

    private double co2Kg;
    private int treesEquivalent;
    private double economyBrl;

    private boolean anomaly;
    private String anomalyReason;

    private Instant createdAt = Instant.now();

    protected Calculation() {
    }

    public Calculation(User user, FuelType fuelType, VehicleType vehicleType, double fuelLiters, String originAddress, String destinationAddress,
                        double distanceKm, boolean distanceEstimated, double co2Kg, int treesEquivalent, double economyBrl) {
        this.user = user;
        this.fuelType = fuelType;
        this.vehicleType = vehicleType;
        this.fuelLiters = fuelLiters;
        this.originAddress = originAddress;
        this.destinationAddress = destinationAddress;
        this.distanceKm = distanceKm;
        this.distanceEstimated = distanceEstimated;
        this.co2Kg = co2Kg;
        this.treesEquivalent = treesEquivalent;
        this.economyBrl = economyBrl;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public FuelType getFuelType() {
        return fuelType;
    }

    public VehicleType getVehicleType() {
        return vehicleType;
    }

    public double getFuelLiters() {
        return fuelLiters;
    }

    public String getOriginAddress() {
        return originAddress;
    }

    public String getDestinationAddress() {
        return destinationAddress;
    }

    public double getDistanceKm() {
        return distanceKm;
    }

    public boolean isDistanceEstimated() {
        return distanceEstimated;
    }

    public double getCo2Kg() {
        return co2Kg;
    }

    public int getTreesEquivalent() {
        return treesEquivalent;
    }

    public double getEconomyBrl() {
        return economyBrl;
    }

    public boolean isAnomaly() {
        return anomaly;
    }

    public String getAnomalyReason() {
        return anomalyReason;
    }

    /** Set after construction, once {@link AnomalyDetectionService} has compared this calculation against the user's history. */
    public void setAnomaly(boolean anomaly, String anomalyReason) {
        this.anomaly = anomaly;
        this.anomalyReason = anomalyReason;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
