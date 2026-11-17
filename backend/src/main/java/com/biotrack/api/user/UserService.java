package com.biotrack.api.user;

import com.biotrack.api.common.ApiException;
import java.util.List;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User updatePhoto(User user, String photoBase64) {
        user.setProfilePhotoBase64(photoBase64);
        return userRepository.save(user);
    }

    public User updateProfile(User user, UpdateProfileRequest req) {
        user.setName(req.name());
        user.setProfession(req.profession());
        user.setCity(req.city());
        user.setBirthDate(req.birthDate());
        return userRepository.save(user);
    }

    public User changePassword(User user, ChangePasswordRequest req) {
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        return userRepository.save(user);
    }

    /** Returns {rank, totalUsers} for the ranking screen — 1-based position by XP descending. */
    public int[] rankAndTotal(User user) {
        List<User> ranked = userRepository.findAllByOrderByXpDesc();
        int rank = ranked.indexOf(userById(ranked, user.getId())) + 1;
        return new int[]{rank <= 0 ? ranked.size() : rank, ranked.size()};
    }

    private User userById(List<User> users, Long id) {
        return users.stream().filter(u -> u.getId().equals(id)).findFirst()
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado"));
    }
}
