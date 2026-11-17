package com.biotrack.api.learning;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ModuleRepository extends JpaRepository<Module, Long> {
    List<Module> findByTrilhaOrderByOrderIndexAsc(Trilha trilha);

    long countByTrilha(Trilha trilha);
}
