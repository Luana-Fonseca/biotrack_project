package com.biotrack.api.calculator;

import com.biotrack.api.user.User;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CalculationRepository extends JpaRepository<Calculation, Long> {
    List<Calculation> findByUserOrderByCreatedAtDesc(User user);
}
