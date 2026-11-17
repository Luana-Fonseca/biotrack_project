package com.biotrack.api.learning;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrilhaRepository extends JpaRepository<Trilha, Long> {
    List<Trilha> findAllByOrderByOrderIndexAsc();
}
