package com.biotrack.api.calculator;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Locale;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Computes a real road-route distance between two geocoded points via a routing API, falling back
 * to a Haversine straight-line estimate (times a 1.3 road-winding factor) when the provider is
 * unreachable or the addresses can't be geocoded — that fallback is always flagged
 * ({@link RouteResult#estimated()}) rather than silently presented as a precise route distance.
 */
@Service
public class RoutingService {

    private static final Logger log = LoggerFactory.getLogger(RoutingService.class);
    private static final double EARTH_RADIUS_KM = 6371.0;
    private static final double ROAD_WINDING_FACTOR = 1.3;

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private final ObjectMapper mapper = new ObjectMapper();
    private final String providerUrl;
    private final String apiKey;

    public RoutingService(
            @Value("${biotrack.routing.provider-url}") String providerUrl,
            @Value("${biotrack.routing.api-key}") String apiKey) {
        this.providerUrl = providerUrl;
        this.apiKey = apiKey;
    }

    public record RouteResult(double distanceKm, boolean estimated) {
    }

    public RouteResult route(GeocodingService.Coordinates origin, GeocodingService.Coordinates destination) {
        Optional<Double> routedKm = routedDistanceKm(origin, destination);
        if (routedKm.isPresent()) {
            return new RouteResult(routedKm.get(), false);
        }
        return new RouteResult(haversineKm(origin, destination) * ROAD_WINDING_FACTOR, true);
    }

    private Optional<Double> routedDistanceKm(GeocodingService.Coordinates origin, GeocodingService.Coordinates destination) {
        try {
            String url = String.format(Locale.US, "%s/%f,%f;%f,%f?overview=false",
                    providerUrl, origin.lon(), origin.lat(), destination.lon(), destination.lat())
                    + (apiKey != null && !apiKey.isBlank() ? "&key=" + apiKey : "");
            HttpRequest request = HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(8)).GET().build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                log.warn("RoutingService returned HTTP {}", response.statusCode());
                return Optional.empty();
            }
            JsonNode root = mapper.readTree(response.body());
            JsonNode routes = root.get("routes");
            if (routes == null || !routes.isArray() || routes.isEmpty()) {
                return Optional.empty();
            }
            double meters = routes.get(0).get("distance").asDouble();
            return Optional.of(meters / 1000.0);
        } catch (Exception e) {
            log.warn("Routing provider unreachable: {}", e.toString());
            return Optional.empty();
        }
    }

    private double haversineKm(GeocodingService.Coordinates a, GeocodingService.Coordinates b) {
        double dLat = Math.toRadians(b.lat() - a.lat());
        double dLon = Math.toRadians(b.lon() - a.lon());
        double sinDLat = Math.sin(dLat / 2);
        double sinDLon = Math.sin(dLon / 2);
        double h = sinDLat * sinDLat + Math.cos(Math.toRadians(a.lat())) * Math.cos(Math.toRadians(b.lat())) * sinDLon * sinDLon;
        return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
    }
}
