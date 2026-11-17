package com.biotrack.api.learning;

public record TrilhaResponse(Long id, String title, String description, String icon, String coverImage,
                              int totalModules, int completedModules, int progressPercent) {
}
