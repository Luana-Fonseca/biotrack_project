package com.biotrack.api.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "trilhas")
public class Trilha {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;
    private String icon;

    /** Filename of the trilha's cover illustration, bundled as a Flutter asset under assets/images/trilhas/. */
    private String coverImage;

    private int orderIndex;

    protected Trilha() {
    }

    public Trilha(String title, String description, String icon, String coverImage, int orderIndex) {
        this.title = title;
        this.description = description;
        this.icon = icon;
        this.coverImage = coverImage;
        this.orderIndex = orderIndex;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public String getIcon() {
        return icon;
    }

    public String getCoverImage() {
        return coverImage;
    }

    public int getOrderIndex() {
        return orderIndex;
    }
}
