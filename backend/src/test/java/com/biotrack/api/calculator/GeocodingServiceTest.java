package com.biotrack.api.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class GeocodingServiceTest {

    private final GeocodingService service = new GeocodingService("http://127.0.0.1:1/search", "BioTrack-Test/1.0", "");

    @Test
    void returnsEmptyWhenProviderUrlIsUnreachable() {
        assertTrue(service.geocode("Praça da Sé, São Paulo").isEmpty());
    }

    @Test
    void returnsEmptyWhenResponseIsNotValidJson() {
        GeocodingService notJsonService = new GeocodingService("http://127.0.0.1:1/not-json", "BioTrack-Test/1.0", "");
        assertFalse(notJsonService.geocode("endereco qualquer").isPresent());
    }

    @Test
    void candidatesExpandCommonAbbreviations() {
        List<String> candidates = service.buildCandidates("Av. Paulista, 1000");
        assertTrue(candidates.get(0).startsWith("Avenida Paulista"), "expected 'Av.' expanded, got: " + candidates.get(0));
    }

    @Test
    void candidatesDropParentheticalNoteAsAFallback() {
        List<String> candidates = service.buildCandidates("Rua Augusta, 500 (perto do metrô)");
        assertTrue(candidates.contains("Rua Augusta, 500"), "expected a candidate without the parenthetical note: " + candidates);
    }

    @Test
    void candidatesDropTrailingComplementWhenThereAreEnoughSegments() {
        List<String> candidates = service.buildCandidates("Rua Augusta, 500, apto 12, São Paulo - SP");
        assertTrue(candidates.contains("Rua Augusta, 500, apto 12"), "expected the last comma-segment dropped: " + candidates);
    }

    @Test
    void neverDropsTheHouseNumberEvenAsALastResort() {
        // A dropped house number can resolve to the wrong end of a long street — every candidate
        // for an address with a number must keep it, however many other rewrites are tried.
        List<String> candidates = service.buildCandidates("Avenida Paulista, 1000, apto 5 (fundos), São Paulo - SP");
        assertTrue(candidates.stream().allMatch(c -> c.contains("1000")), "expected every candidate to keep the house number: " + candidates);
    }

    @Test
    void candidatesHaveNoDuplicatesWhenNothingToRewrite() {
        List<String> candidates = service.buildCandidates("Praça da Sé, São Paulo");
        assertEquals(1, candidates.size(), "a plain address with nothing to rewrite should yield exactly one candidate");
    }
}
