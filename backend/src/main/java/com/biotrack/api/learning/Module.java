package com.biotrack.api.learning;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "modules")
public class Module {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private Trilha trilha;

    private int orderIndex;
    private String title;
    private int durationMinutes;

    @Column(columnDefinition = "TEXT")
    private String content;

    protected Module() {
    }

    public Module(Trilha trilha, int orderIndex, String title, int durationMinutes, String content) {
        this.trilha = trilha;
        this.orderIndex = orderIndex;
        this.title = title;
        this.durationMinutes = durationMinutes;
        this.content = content;
    }

    public Long getId() {
        return id;
    }

    public Trilha getTrilha() {
        return trilha;
    }

    public int getOrderIndex() {
        return orderIndex;
    }

    public String getTitle() {
        return title;
    }

    public int getDurationMinutes() {
        return durationMinutes;
    }

    public String getContent() {
        return content;
    }
}
