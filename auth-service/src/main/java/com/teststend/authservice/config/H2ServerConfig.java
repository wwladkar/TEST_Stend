package com.teststend.authservice.config;

import org.h2.tools.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.sql.SQLException;

@Configuration
public class H2ServerConfig {

    private static final String TCP_PORT = "9091";
    private static final String WEB_PORT = "8091";

    @Bean(initMethod = "start", destroyMethod = "stop")
    public Server h2TcpServer() throws SQLException {
        return Server.createTcpServer("-tcp", "-tcpAllowOthers", "-tcpPort", TCP_PORT);
    }

    @Bean(initMethod = "start", destroyMethod = "stop")
    public Server h2WebServer(@Value("${spring.datasource.url}") String url) throws SQLException {
        return Server.createWebServer("-web", "-webAllowOthers", "-webPort", WEB_PORT);
    }
}
