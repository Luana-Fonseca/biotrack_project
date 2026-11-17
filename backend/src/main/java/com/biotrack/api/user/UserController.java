package com.biotrack.api.user;

import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal User user) {
        return UserResponse.from(user);
    }

    @PutMapping("/me/photo")
    public UserResponse updatePhoto(@AuthenticationPrincipal User user, @Valid @RequestBody UpdatePhotoRequest req) {
        return UserResponse.from(userService.updatePhoto(user, req.photoBase64()));
    }

    @PutMapping("/me/profile")
    public UserResponse updateProfile(@AuthenticationPrincipal User user, @Valid @RequestBody UpdateProfileRequest req) {
        return UserResponse.from(userService.updateProfile(user, req));
    }

    @PutMapping("/me/password")
    public UserResponse changePassword(@AuthenticationPrincipal User user, @Valid @RequestBody ChangePasswordRequest req) {
        return UserResponse.from(userService.changePassword(user, req));
    }
}
