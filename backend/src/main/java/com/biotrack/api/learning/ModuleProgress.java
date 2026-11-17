package com.biotrack.api.learning;

import com.biotrack.api.user.User;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(name = "module_progress", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "module_id"}))
public class ModuleProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private User user;

    @ManyToOne(optional = false)
    private Module module;

    private Instant completedAt = Instant.now();

    protected ModuleProgress() {
    }

    public ModuleProgress(User user, Module module) {
        this.user = user;
        this.module = module;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public Module getModule() {
        return module;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }
}
