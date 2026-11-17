package com.biotrack.api.auth;

import com.biotrack.api.user.UserResponse;

public record AuthResponse(String accessToken, String tokenType, UserResponse user) {
    public static AuthResponse of(String token, UserResponse user) {
        return new AuthResponse(token, "Bearer", user);
    }
}
