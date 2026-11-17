package com.biotrack.api.reports;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record GenerateReportRequest(
        @NotNull(message = "type é obrigatório") ReportType type,
        @NotNull(message = "period é obrigatório") ReportPeriod period,
        @NotNull(message = "periodStart é obrigatório") LocalDate periodStart,
        @NotNull(message = "periodEnd é obrigatório") LocalDate periodEnd
) {
}
