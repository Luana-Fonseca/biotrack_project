package com.biotrack.api.calculator;

import com.biotrack.api.user.User;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/calculator")
public class CalculatorController {

    private final CalculatorService calculatorService;

    public CalculatorController(CalculatorService calculatorService) {
        this.calculatorService = calculatorService;
    }

    @PostMapping("/calculate")
    public ResponseEntity<CalculationResponse> calculate(@AuthenticationPrincipal User user, @Valid @RequestBody CalculateRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(calculatorService.calculate(user, req));
    }

    @GetMapping("/history")
    public List<CalculationResponse> history(@AuthenticationPrincipal User user) {
        return calculatorService.history(user);
    }
}
