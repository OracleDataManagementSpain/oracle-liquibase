package com.example.application.controller;

import java.math.BigDecimal;

import javax.sql.DataSource;
import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;


import com.example.application.persistence.*;

@RestController
public class EditionController {
	private final DataSource dataSource;

	@Autowired
	public EditionController(DataSource dataSource) {
		this.dataSource=dataSource;
	}

	@GetMapping(value = "/edition", produces = MediaType.APPLICATION_JSON_VALUE)
	public EditionEntity getEdition() {
		// SimpleJdbcCall call;
		// SqlParameterSource params;

		// BigDecimal count;

		// call=new SimpleJdbcCall(dataSource).withFunctionName("getProductCount");
		// params=new MapSqlParameterSource();
		// count=call.executeFunction(BigDecimal.class, params);

		// return new EditionEntity(count.longValue());
		JdbcTemplate jdbcTemplate;
		String edition;

		jdbcTemplate=new JdbcTemplate(dataSource);
		edition=jdbcTemplate.queryForObject(
			"SELECT SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME') FROM DUAL",
			String.class);

		return new EditionEntity(edition);



	}

	@PostMapping(value = "/edition", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
	public EditionEntity setEdition(@Valid @RequestBody EditionEntity edition) {
		JdbcTemplate jdbcTemplate;

		jdbcTemplate=new JdbcTemplate(dataSource);
		jdbcTemplate.execute(String.format("ALTER SESSION SET EDITION = %s",edition.getEdition()));

		return getEdition();
	}

}
