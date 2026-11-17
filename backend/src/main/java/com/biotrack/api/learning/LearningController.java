package com.biotrack.api.learning;

import com.biotrack.api.user.User;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/learning")
public class LearningController {

    private final LearningService learningService;

    public LearningController(LearningService learningService) {
        this.learningService = learningService;
    }

    @GetMapping("/trilhas")
    public List<TrilhaResponse> trilhas(@AuthenticationPrincipal User user) {
        return learningService.trilhas(user);
    }

    @GetMapping("/trilhas/{trilhaId}/modules")
    public List<ModuleResponse> modules(@AuthenticationPrincipal User user, @PathVariable Long trilhaId) {
        return learningService.modules(user, trilhaId);
    }

    @PostMapping("/modules/{moduleId}/complete")
    public ModuleResponse complete(@AuthenticationPrincipal User user, @PathVariable Long moduleId) {
        return learningService.complete(user, moduleId);
    }
}
