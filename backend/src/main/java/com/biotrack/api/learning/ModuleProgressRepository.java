package com.biotrack.api.learning;

import com.biotrack.api.user.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ModuleProgressRepository extends JpaRepository<ModuleProgress, Long> {
    List<ModuleProgress> findByUser(User user);

    Optional<ModuleProgress> findByUserAndModule(User user, Module module);

    long countByUserAndModule_Trilha(User user, Trilha trilha);
}
