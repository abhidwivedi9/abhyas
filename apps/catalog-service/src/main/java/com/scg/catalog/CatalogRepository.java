package com.scg.catalog;

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
        save(new Product("sku-1", "Wireless Mouse", "electronics", 2499));
        save(new Product("sku-2", "Mechanical Keyboard", "electronics", 8999));
        save(new Product("sku-3", "USB-C Hub", "electronics", 3499));
        save(new Product("sku-4", "Standing Desk Mat", "office", 4599));
        save(new Product("sku-5", "Notebook, ruled", "office", 599));
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
