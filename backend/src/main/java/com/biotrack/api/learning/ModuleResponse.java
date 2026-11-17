package com.biotrack.api.learning;

public record ModuleResponse(Long id, Long trilhaId, int orderIndex, String title, int durationMinutes, String content, boolean completed) {
}
