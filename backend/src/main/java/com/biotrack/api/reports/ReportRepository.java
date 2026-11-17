package com.biotrack.api.reports;

import com.biotrack.api.user.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportRepository extends JpaRepository<Report, Long> {
    List<Report> findByUserOrderByCreatedAtDesc(User user);

    Optional<Report> findByIdAndUser(Long id, User user);
}
