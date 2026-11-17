package com.biotrack.api.calculator;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Geocodes a free-text address into coordinates so the "Cálculo de Distância da Descarbonização"
 * can compute a real route distance instead of relying only on user-entered figures.
 *
 * <p>Default provider is the public Nominatim (OpenStreetMap) search API — free, no API key, but
 * rate-limited and occasionally blocks automated clients outright with HTTP 403. LocationIQ
 * (locationiq.com, free tier, no credit card) exposes a Nominatim-compatible {@code /v1/search}
 * endpoint that's friendlier to automation; point {@code GEOCODING_URL} at
 * {@code https://us1.locationiq.com/v1/search} and {@code GEOCODING_API_KEY} to your free key
 * to switch.
 *
 * <p><b>Address matching</b>: a free-text address typed by a person rarely matches a geocoder's
 * index verbatim (abbreviations, a "(próximo ao mercado)" aside, an apartment number Nominatim
 * has no record of). Rather than failing on the very first miss, {@link #geocode(String)} expands
 * common Brazilian abbreviations, then — only if that still doesn't resolve — retries with
 * progressively less specific rewrites of the same address (dropping a parenthetical note, then a
 * trailing complement) until one of them resolves or every rewrite has been tried. This is plain
 * rule-based text normalization, not a trained model — it fixes the exact "não foi possível
 * localizar o endereço" failures seen with slightly-off input, without needing any ML/NLP
 * dependency.
 *
 * <p>Deliberately <b>not</b> attempted: dropping the house number to search the street alone. That
 * was tried and removed — it can "succeed" at the wrong end of a long avenue, turning a failed
 * geocode (visible, fixable) into a wrong-but-confident one (silent, and wrong by however many
 * kilometers the street runs) that feeds straight into the distance/CO2 numbers downstream.
 */
@Service
public class GeocodingService {

    private static final Logger log = LoggerFactory.getLogger(GeocodingService.class);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private final ObjectMapper mapper = new ObjectMapper();
    private final String providerUrl;
    private final String userAgent;
    private final String apiKey;

    public GeocodingService(
            @Value("${biotrack.geocoding.provider-url}") String providerUrl,
            @Value("${biotrack.geocoding.user-agent}") String userAgent,
            @Value("${biotrack.geocoding.api-key}") String apiKey) {
        this.providerUrl = providerUrl;
        this.userAgent = userAgent;
        this.apiKey = apiKey;
    }

    public record Coordinates(double lat, double lon) {
    }

    public Optional<Coordinates> geocode(String address) {
        List<String> candidates = buildCandidates(address);
        for (String candidate : candidates) {
            Optional<Coordinates> result = attemptGeocode(candidate);
            if (result.isPresent()) {
                if (!candidate.equals(address)) {
                    log.info("Geocoded '{}' after normalizing to '{}'", address, candidate);
                }
                return result;
            }
        }
        return Optional.empty();
    }

    /**
     * Builds an ordered list of address rewrites to try, from most to least specific: the
     * abbreviation-expanded address first, then (only as needed) versions with a parenthetical
     * note removed and a trailing comma-separated complement dropped — each one strictly less
     * precise than the last, used only when everything before it failed to resolve, but all of
     * them still pinned to the same house number so a resolved match can't drift down the street.
     */
    List<String> buildCandidates(String address) {
        List<String> candidates = new ArrayList<>();
        String normalized = normalize(address);
        candidates.add(normalized);

        String noParens = normalized.replaceAll("\\([^)]*\\)", "").replaceAll("\\s{2,}", " ").trim();
        if (!noParens.isBlank()) {
            candidates.add(noParens);
        }

        String[] parts = noParens.split(",");
        if (parts.length >= 3) {
            StringBuilder dropped = new StringBuilder();
            for (int i = 0; i < parts.length - 1; i++) {
                if (i > 0) dropped.append(',');
                dropped.append(parts[i]);
            }
            candidates.add(dropped.toString().trim());
        }

        return candidates.stream().distinct().toList();
    }

    /** Expands common Brazilian address abbreviations Nominatim matches more reliably when spelled out. */
    private String normalize(String address) {
        String s = address.trim().replaceAll("\\s{2,}", " ");
        s = s.replaceAll("(?i)\\bAv\\.(?=\\s|$)", "Avenida");
        s = s.replaceAll("(?i)\\bR\\.(?=\\s)", "Rua");
        s = s.replaceAll("(?i)\\bPç\\.?a?\\b|\\bPca\\.?\\b", "Praça");
        s = s.replaceAll("(?i)\\bAl\\.(?=\\s)", "Alameda");
        s = s.replaceAll("(?i)\\bRod\\.(?=\\s)", "Rodovia");
        s = s.replaceAll("(?i)\\bn[ºo°]\\s*\\.?\\s*", "");
        return s.trim();
    }

    private Optional<Coordinates> attemptGeocode(String address) {
        try {
            String url = providerUrl + "?format=json&limit=1&q=" + URLEncoder.encode(address, StandardCharsets.UTF_8)
                    + (apiKey != null && !apiKey.isBlank() ? "&key=" + apiKey : "");
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(8))
                    .header("User-Agent", userAgent)
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                log.warn("GeocodingService returned HTTP {}", response.statusCode());
                return Optional.empty();
            }
            JsonNode root = mapper.readTree(response.body());
            if (!root.isArray() || root.isEmpty()) {
                return Optional.empty();
            }
            JsonNode first = root.get(0);
            return Optional.of(new Coordinates(first.get("lat").asDouble(), first.get("lon").asDouble()));
        } catch (Exception e) {
            log.warn("Could not parse geocoding response: {}", e.toString());
            return Optional.empty();
        }
    }
}
