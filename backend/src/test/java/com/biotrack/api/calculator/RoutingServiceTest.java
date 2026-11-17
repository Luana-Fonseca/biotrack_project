package com.biotrack.api.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class RoutingServiceTest {

    @Test
    void fallsBackToHaversineEstimateWhenProviderIsUnreachable() {
        RoutingService service = new RoutingService("http://127.0.0.1:1/route", "");
        // São Paulo (-23.5505, -46.6333) to Rio de Janeiro (-22.9068, -43.1729) — straight-line ~360km.
        var origin = new GeocodingService.Coordinates(-23.5505, -46.6333);
        var destination = new GeocodingService.Coordinates(-22.9068, -43.1729);

        RoutingService.RouteResult result = service.route(origin, destination);

        assertTrue(result.estimated());
        assertTrue(result.distanceKm() > 300 && result.distanceKm() < 500, "expected ~360-430km with winding factor, got " + result.distanceKm());
    }

    @Test
    void zeroDistanceForIdenticalCoordinates() {
        RoutingService service = new RoutingService("http://127.0.0.1:1/route", "");
        var point = new GeocodingService.Coordinates(-23.5505, -46.6333);

        RoutingService.RouteResult result = service.route(point, point);

        assertEquals(0.0, result.distanceKm(), 0.001);
    }
}
