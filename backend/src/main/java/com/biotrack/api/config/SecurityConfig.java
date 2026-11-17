package com.biotrack.api.config;

import com.biotrack.api.auth.JwtAuthFilter;
import com.biotrack.api.auth.JwtService;
import com.biotrack.api.user.UserRepository;
import jakarta.annotation.PostConstruct;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    @Value("${biotrack.cors.allowed-origins}")
    private String allowedOrigins;

    @PostConstruct
    void logAllowedOrigins() {
        // Printed at startup so a CORS "preflight 403 / no Access-Control-Allow-Origin header"
        // can be diagnosed by comparing this list against the browser's actual origin, instead
        // of guessing — a stray env var or a typo here is otherwise invisible until a request fails.
        log.info("CORS allowed origins: {}", List.of(resolveAllowedOrigins()));
    }

    private String[] resolveAllowedOrigins() {
        // .trim() guards against a stray space or \r sneaking into the env var (common when it's
        // set via a Windows PowerShell/batch script), which would otherwise silently make every
        // origin fail to match and the CORS preflight come back 403 with no explanation.
        return java.util.Arrays.stream(allowedOrigins.split(",")).map(String::trim).toArray(String[]::new);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, JwtService jwtService, UserRepository userRepository,
                                            JsonAuthEntryPoint authEntryPoint) throws Exception {
        JwtAuthFilter jwtAuthFilter = new JwtAuthFilter(jwtService, userRepository);

        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // CORS preflight requests never carry an Authorization header, so they must be
                        // allowed through regardless of the target path — otherwise every authenticated
                        // endpoint (calculator, reports, profile...) fails its preflight and the browser
                        // reports a generic CORS error instead of the real 401.
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers("/auth/**", "/actuator/health", "/h2-console/**").permitAll()
                        .anyRequest().authenticated()
                )
                .exceptionHandling(ex -> ex.authenticationEntryPoint(authEntryPoint))
                .headers(headers -> headers.frameOptions(frame -> frame.sameOrigin()))
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    private CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // setAllowedOriginPatterns (not setAllowedOrigins) so "*" segments in application.yml's
        // default list, e.g. "http://192.168.*.*:*", actually act as wildcards instead of being
        // compared literally — lets any LAN IP on a common private range reach the API.
        config.setAllowedOriginPatterns(List.of(resolveAllowedOrigins()));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
