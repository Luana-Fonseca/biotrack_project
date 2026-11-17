package com.biotrack.api.reports;

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
import java.time.LocalDate;

@Entity
@Table(name = "reports")
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private User user;

    private String name;

    @Enumerated(EnumType.STRING)
    private ReportType type;

    @Enumerated(EnumType.STRING)
    private ReportPeriod period;

    private LocalDate periodStart;
    private LocalDate periodEnd;

    private String filePath;
    private long sizeBytes;

    private Instant createdAt = Instant.now();

    protected Report() {
    }

    public Report(User user, String name, ReportType type, ReportPeriod period, LocalDate periodStart, LocalDate periodEnd,
                  String filePath, long sizeBytes) {
        this.user = user;
        this.name = name;
        this.type = type;
        this.period = period;
        this.periodStart = periodStart;
        this.periodEnd = periodEnd;
        this.filePath = filePath;
        this.sizeBytes = sizeBytes;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getName() {
        return name;
    }

    public ReportType getType() {
        return type;
    }

    public ReportPeriod getPeriod() {
        return period;
    }

    public LocalDate getPeriodStart() {
        return periodStart;
    }

    public LocalDate getPeriodEnd() {
        return periodEnd;
    }

    public String getFilePath() {
        return filePath;
    }

    public long getSizeBytes() {
        return sizeBytes;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
