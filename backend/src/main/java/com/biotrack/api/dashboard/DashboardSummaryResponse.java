package com.biotrack.api.dashboard;

public record DashboardSummaryResponse(
        int totalCalculations,
        double totalCo2Kg,
        double totalEconomyBrl,
        int totalTrees,
        int xp,
        int streakDays,
        int rank,
        int totalUsers
) {
}
