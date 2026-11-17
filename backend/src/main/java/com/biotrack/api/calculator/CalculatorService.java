package com.biotrack.api.calculator;

import com.biotrack.api.common.ApiException;
import com.biotrack.api.user.User;
import java.util.List;
import java.util.Locale;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class CalculatorService {

    private static final Logger log = LoggerFactory.getLogger(CalculatorService.class);
    private static final double TREE_KG_CO2_PER_YEAR = 21.0;

    private final CalculationRepository calculationRepository;
    private final GeocodingService geocodingService;
    private final RoutingService routingService;
    private final AnomalyDetectionService anomalyDetectionService;

    public CalculatorService(CalculationRepository calculationRepository, GeocodingService geocodingService,
                              RoutingService routingService,
                              AnomalyDetectionService anomalyDetectionService) {
        this.calculationRepository = calculationRepository;
        this.geocodingService = geocodingService;
        this.routingService = routingService;
        this.anomalyDetectionService = anomalyDetectionService;
    }

    public CalculationResponse calculate(User user, CalculateRequest req) {
        GeocodingService.Coordinates origin = geocodingService.geocode(req.originAddress())
                .orElseThrow(() -> ApiException.badRequest(
                        "Não foi possível localizar o endereço de origem \"" + req.originAddress()
                                + "\". Tente incluir rua, número, cidade e UF, ou o nome exato do local."));
        GeocodingService.Coordinates destination = geocodingService.geocode(req.destinationAddress())
                .orElseThrow(() -> ApiException.badRequest(
                        "Não foi possível localizar o endereço de destino \"" + req.destinationAddress()
                                + "\". Tente incluir rua, número, cidade e UF, ou o nome exato do local."));

        RoutingService.RouteResult route = routingService.route(origin, destination);
        // A wrong-but-confident distance (geocoding resolving to the wrong place, or a routing
        // provider quirk) is otherwise invisible until it shows up as a weird number on screen —
        // this line is what a "the distance came out wrong" report gets diagnosed from.
        log.info(String.format(Locale.US,
                "Route for calculation: origin=(%.5f,%.5f) destination=(%.5f,%.5f) distanceKm=%.2f estimated=%s",
                origin.lat(), origin.lon(), destination.lat(), destination.lon(), route.distanceKm(), route.estimated()));

        FuelType fuelType = req.fuelType();
        double liters = req.fuelLiters();
        double co2Kg = liters * fuelType.getCo2PerLiter();
        double economyBrl = liters * fuelType.getEconPerLiter();
        int treesEquivalent = (int) Math.round(co2Kg / TREE_KG_CO2_PER_YEAR);

        Calculation calc = new Calculation(user, fuelType, req.vehicleType(), liters, req.originAddress(), req.destinationAddress(),
                route.distanceKm(), route.estimated(), co2Kg, treesEquivalent, economyBrl);

        List<Double> pastSameFuelType = calculationRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .filter(c -> c.getFuelType() == fuelType)
                .map(c -> consumptionRate(c.getFuelLiters(), c.getDistanceKm()))
                .toList();
        AnomalyDetectionService.Result anomaly = anomalyDetectionService.check(
                consumptionRate(liters, route.distanceKm()), pastSameFuelType);
        calc.setAnomaly(anomaly.anomalous(), anomaly.reason());

        calc = calculationRepository.save(calc);

        return CalculationResponse.from(calc);
    }

    public List<CalculationResponse> history(User user) {
        return calculationRepository.findByUserOrderByCreatedAtDesc(user).stream().map(CalculationResponse::from).toList();
    }

    /** Liters per km when the route distance is known and non-trivial, else raw liters — the metric anomaly detection compares across a user's history. */
    private double consumptionRate(double liters, double distanceKm) {
        return distanceKm > 0.5 ? liters / distanceKm : liters;
    }
}
