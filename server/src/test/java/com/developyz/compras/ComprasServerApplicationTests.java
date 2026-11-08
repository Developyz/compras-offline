package com.developyz.compras;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

/** Verifica la base ejecutable sin abrir HTTP ni configurar una base de datos. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
class ComprasServerApplicationTests {

    @Autowired
    private ApplicationContext context;

    @Test
    void startsWithoutDatabaseOrHttpServer() {
        assertThat(context.getEnvironment().getProperty("spring.main.web-application-type"))
                .isEqualTo("none");
        assertThat(context.containsBean("dataSource")).isFalse();
        assertThat(context.containsBean("flyway")).isFalse();
    }
}
