package com.biotrack.api.reports;

import java.time.Instant;
import java.time.LocalDate;

public record ReportResponse(
        Long id, String name, ReportType type, ReportPeriod period,
        LocalDate periodStart, LocalDate periodEnd, long sizeBytes, Instant createdAt
) {
    public static ReportResponse from(Report r) {
        return new ReportResponse(r.getId(), r.getName(), r.getType(), r.getPeriod(), r.getPeriodStart(), r.getPeriodEnd(),
                r.getSizeBytes(), r.getCreatedAt());
    }
}
