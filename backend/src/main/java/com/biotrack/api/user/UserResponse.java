package com.biotrack.api.user;

import java.time.LocalDate;

public record UserResponse(
        Long id,
        String email,
        String name,
        String profession,
        String education,
        String city,
        LocalDate birthDate,
        UserRole role,
        boolean notificationsEnabled,
        String language,
        int xp,
        int streakDays,
        boolean hasPhoto,
        String profilePhotoBase64
) {
    public static UserResponse from(User u) {
        return new UserResponse(
                u.getId(), u.getEmail(), u.getName(), u.getProfession(), u.getEducation(), u.getCity(), u.getBirthDate(),
                u.getRole(), u.isNotificationsEnabled(), u.getLanguage(), u.getXp(), u.getStreakDays(),
                u.getProfilePhotoBase64() != null, u.getProfilePhotoBase64()
        );
    }
}
