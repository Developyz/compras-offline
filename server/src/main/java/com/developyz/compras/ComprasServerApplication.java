package com.developyz.compras;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Base sin HTTP ni persistencia. TODO: añadir integraciones por perfiles y fases. */
@SpringBootApplication
public class ComprasServerApplication {

	public static void main(String[] args) {
		SpringApplication.run(ComprasServerApplication.class, args);
	}

}
