package com.sachidaquatics.catalog;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Repository;

/**
 * In-memory for now — a real datastore (PostgreSQL, per ADR-0004) lands in
 * Milestone 8. Kept behind this interface-free repository bean so that
 * swap is a single-class change later, not a rewrite of the controller.
 */
@Repository
public class CatalogRepository {

    private final Map<String, Product> products = new LinkedHashMap<>();

    public CatalogRepository() {
        seed();
    }

    private void seed() {
        save(new Product("sku-1", "Neon Tetra", "fish", 149));
        save(new Product("sku-2", "Amano Shrimp", "shrimp", 349));
        save(new Product("sku-3", "Mystery Snail", "snail", 299));
        save(new Product("sku-4", "Amazon Sword Plant", "plant", 899));
        save(new Product("sku-5", "Java Fern on Driftwood", "plant", 1299));
        save(new Product("sku-6", "Canister Filter, 500 GPH", "equipment", 6999));
        save(new Product("sku-7", "CO2 Diffuser Kit", "equipment", 4499));
        save(new Product("sku-8", "LED Aquarium Light, 24in", "equipment", 5499));
        save(new Product("sku-9", "Tropical Fish Flakes, 100g", "food", 699));
        save(new Product("sku-10", "Liquid Plant Fertilizer, 250ml", "fertilizer", 1199));
    }

    public void save(Product product) {
        products.put(product.id(), product);
    }

    public Iterable<Product> findAll() {
        return products.values();
    }

    public Optional<Product> findById(String id) {
        return Optional.ofNullable(products.get(id));
    }
}
