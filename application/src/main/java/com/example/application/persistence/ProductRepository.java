package com.example.application.persistence;

import java.util.*;

import org.springframework.data.repository.CrudRepository;
import org.springframework.transaction.annotation.Transactional;

public interface ProductRepository extends CrudRepository<ProductEntity, Integer> {
	@Transactional(readOnly = true)
	Optional<ProductEntity> findById(int Id);

	// JMA: JPA >=1.7
	@Transactional(readOnly = false)
	Long deleteById(int Id);
}
