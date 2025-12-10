package com.workcheck.entity;

import javax.persistence.*;

@Entity
@Table(name = "check_template_items")
public class CheckTemplateItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    private CheckTemplate template;

    @Column(name = "item_text", nullable = false, length = 200)
    private String itemText;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public CheckTemplate getTemplate() {
        return template;
    }

    public void setTemplate(CheckTemplate template) {
        this.template = template;
    }

    public String getItemText() {
        return itemText;
    }

    public void setItemText(String itemText) {
        this.itemText = itemText;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }
}