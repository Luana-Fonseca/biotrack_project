package com.biotrack.api.dashboard;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

import com.biotrack.api.calculator.Calculation;
import com.biotrack.api.calculator.CalculationRepository;
import com.biotrack.api.calculator.FuelType;
import com.biotrack.api.calculator.VehicleType;
import com.biotrack.api.user.User;
import com.biotrack.api.user.UserService;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    @Mock
    private CalculationRepository calculationRepository;
    @Mock
    private UserService userService;

    private DashboardService dashboardService;
    private User user;

    @BeforeEach
    void setUp() {
        dashboardService = new DashboardService(calculationRepository, userService);
        user = new User("teste@example.com", "hash", "Teste");
    }

    @Test
    void trendReturnsSixHistoricalMonthsPlusThreeProjectedMonths() {
        when(calculationRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(List.of());

        List<TrendPoint> trend = dashboardService.trend(user);

        assertEquals(9, trend.size());
        for (int i = 0; i < 6; i++) {
            assertFalse(trend.get(i).projected(), "month index " + i + " should be historical");
        }
        for (int i = 6; i < 9; i++) {
            assertTrue(trend.get(i).projected(), "month index " + i + " should be projected");
        }
    }

    @Test
    void projectsForwardFromAGrowingHistoricalTrend() {
        // One calc per month for the last 6 months with steadily growing CO2 totals
        // (100, 200, ..., 600) so the regression's slope is unambiguous: +100/month.
        List<Calculation> calcs = new ArrayList<>();
        var now = LocalDate.now();
        for (int i = 5; i >= 0; i--) {
            double co2 = (6 - i) * 100.0;
            Instant createdAt = now.minusMonths(i).atStartOfDay(ZoneOffset.UTC).toInstant();
            calcs.add(calculation(co2, createdAt));
        }
        when(calculationRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(calcs);

        List<TrendPoint> trend = dashboardService.trend(user);

        assertEquals(600.0, trend.get(5).co2Kg(), 0.001, "last historical month should be 600");
        assertEquals(700.0, trend.get(6).co2Kg(), 0.001, "first projected month should continue the +100/month trend");
        assertEquals(800.0, trend.get(7).co2Kg(), 0.001);
        assertEquals(900.0, trend.get(8).co2Kg(), 0.001);
    }

    private Calculation calculation(double co2Kg, Instant createdAt) {
        Calculation calc = new Calculation(user, FuelType.DIESEL_B12, VehicleType.CARRO, 10, "Origem", "Destino", 5, false, co2Kg, 1, co2Kg * 0.8);
        setCreatedAt(calc, createdAt);
        return calc;
    }

    private void setCreatedAt(Calculation calc, Instant createdAt) {
        try {
            var field = Calculation.class.getDeclaredField("createdAt");
            field.setAccessible(true);
            field.set(calc, createdAt);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
