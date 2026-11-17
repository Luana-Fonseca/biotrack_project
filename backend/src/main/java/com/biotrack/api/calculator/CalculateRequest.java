package com.biotrack.api.calculator;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CalculateRequest(
        @NotNull(message = "Tipo de combustível é obrigatório") FuelType fuelType,
        @NotNull(message = "Tipo de veículo é obrigatório") VehicleType vehicleType,
        @NotNull(message = "Litros é obrigatório") @DecimalMin(value = "0.01", message = "Litros deve ser maior que zero") Double fuelLiters,
        @NotBlank(message = "Endereço de origem é obrigatório") String originAddress,
        @NotBlank(message = "Endereço de destino é obrigatório") String destinationAddress
) {
}
