package com.biotrack.api.learning;

import com.biotrack.api.common.ApiException;
import com.biotrack.api.user.User;
import com.biotrack.api.user.UserRepository;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class LearningService {

    private static final int XP_PER_MODULE = 10;

    private final TrilhaRepository trilhaRepository;
    private final ModuleRepository moduleRepository;
    private final ModuleProgressRepository progressRepository;
    private final UserRepository userRepository;

    public LearningService(TrilhaRepository trilhaRepository, ModuleRepository moduleRepository,
                            ModuleProgressRepository progressRepository, UserRepository userRepository) {
        this.trilhaRepository = trilhaRepository;
        this.moduleRepository = moduleRepository;
        this.progressRepository = progressRepository;
        this.userRepository = userRepository;
    }

    public List<TrilhaResponse> trilhas(User user) {
        Set<Long> completedModuleIds = progressRepository.findByUser(user).stream()
                .map(p -> p.getModule().getId()).collect(java.util.stream.Collectors.toSet());
        return trilhaRepository.findAllByOrderByOrderIndexAsc().stream().map(t -> {
            List<Module> modules = moduleRepository.findByTrilhaOrderByOrderIndexAsc(t);
            long completed = modules.stream().filter(m -> completedModuleIds.contains(m.getId())).count();
            int percent = modules.isEmpty() ? 0 : (int) Math.round(completed * 100.0 / modules.size());
            return new TrilhaResponse(t.getId(), t.getTitle(), t.getDescription(), t.getIcon(), t.getCoverImage(),
                    modules.size(), (int) completed, percent);
        }).toList();
    }

    public List<ModuleResponse> modules(User user, Long trilhaId) {
        Trilha trilha = trilhaRepository.findById(trilhaId).orElseThrow(() -> ApiException.notFound("Trilha não encontrada"));
        Set<Long> completedModuleIds = progressRepository.findByUser(user).stream()
                .map(p -> p.getModule().getId()).collect(java.util.stream.Collectors.toSet());
        return moduleRepository.findByTrilhaOrderByOrderIndexAsc(trilha).stream()
                .map(m -> new ModuleResponse(m.getId(), trilha.getId(), m.getOrderIndex(), m.getTitle(), m.getDurationMinutes(),
                        m.getContent(), completedModuleIds.contains(m.getId())))
                .toList();
    }

    public ModuleResponse complete(User user, Long moduleId) {
        Module module = moduleRepository.findById(moduleId).orElseThrow(() -> ApiException.notFound("Módulo não encontrado"));
        if (progressRepository.findByUserAndModule(user, module).isEmpty()) {
            progressRepository.save(new ModuleProgress(user, module));
            user.setXp(user.getXp() + XP_PER_MODULE);
            userRepository.save(user);
        }
        return new ModuleResponse(module.getId(), module.getTrilha().getId(), module.getOrderIndex(), module.getTitle(),
                module.getDurationMinutes(), module.getContent(), true);
    }
}
