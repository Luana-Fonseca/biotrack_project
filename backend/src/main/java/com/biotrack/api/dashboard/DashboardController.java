package com.biotrack.api.dashboard;

import com.biotrack.api.user.User;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/summary")
    public DashboardSummaryResponse summary(@AuthenticationPrincipal User user) {
        return dashboardService.summary(user);
    }

    @GetMapping("/trend")
    public List<TrendPoint> trend(@AuthenticationPrincipal User user) {
        return dashboardService.trend(user);
    }

    @GetMapping("/viability")
    public List<FuelViabilityResponse> viability(@AuthenticationPrincipal User user) {
        return dashboardService.fuelViability(user);
    }
}
