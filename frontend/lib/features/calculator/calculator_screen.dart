import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import '../auth/auth_provider.dart';
import 'calculation_models.dart';
import 'calculator_provider.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  Future<void> _calculate(CalculatorProvider provider) async {
    final ok = await provider.calculate();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
    } else if (provider.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final userName = context.watch<AuthProvider>().currentUser?.name.split(' ').first ?? '';
    final p = context.palette;
    final canSubmit = provider.isAddressesValid && provider.previewCo2 > 0;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, $userName', style: AppText.inter(size: 13, color: p.gray)),
                      const SizedBox(height: 2),
                      Text('Calculadora', style: AppText.inter(size: 26, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.5)),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
                      child: Center(child: BioIcon('chart', size: 18, color: p.gray)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.verde.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BioIcon('leaf', size: 20, color: AppColors.verdeDark, strokeWidth: 2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Substituição por biometano', style: AppText.inter(size: 13.5, weight: FontWeight.w700, color: AppColors.verdeDark)),
                          const SizedBox(height: 4),
                          Text(
                            'Calcule quanto CO₂ você deixa de emitir substituindo combustível fóssil por biometano.',
                            style: AppText.inter(size: 12, color: p.ink.withOpacity(0.75), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIPO DE COMBUSTÍVEL', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: FuelType.values.map((f) {
                        final selected = provider.selectedFuelType == f;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => provider.setFuelType(f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.azul : p.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? AppColors.azul : p.border),
                                ),
                                child: Text(
                                  f.label,
                                  textAlign: TextAlign.center,
                                  style: AppText.inter(size: 11.5, weight: FontWeight.w600, color: selected ? Colors.white : p.ink),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('TIPO DE VEÍCULO', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: VehicleType.values.map((v) {
                        final selected = provider.selectedVehicleType == v;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => provider.setVehicleType(v),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.azul : p.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? AppColors.azul : p.border),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BioIcon(v.icon, size: 16, color: selected ? Colors.white : p.gray),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.label,
                                      textAlign: TextAlign.center,
                                      style: AppText.inter(size: 11.5, weight: FontWeight.w600, color: selected ? Colors.white : p.ink),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('COMBUSTÍVEL', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: provider.setFuelLiters,
                          style: AppText.mono(size: 30, weight: FontWeight.w700, color: AppColors.azul),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 8, right: 56),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azul, width: 1.4)),
                          ),
                        ),
                        // A separate, always-rendered label rather than InputDecoration.suffixText —
                        // kept visible before any value is typed, regardless of the field's state.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('litros', style: AppText.mono(size: 14, weight: FontWeight.w600, color: AppColors.verde)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text('DISTÂNCIA DA DESCARBONIZAÇÃO', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.3)),
                        const SizedBox(width: 6),
                        BioIcon('esg', size: 12, color: p.gray2),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _addressField(p, 'Endereço de origem', provider.setOriginAddress, 'Ex.: Avenida Paulista 1000, São Paulo - SP'),
                    const SizedBox(height: 14),
                    _addressField(p, 'Endereço de destino', provider.setDestinationAddress, 'Ex.: Rua Augusta 500, São Paulo - SP'),
                    if (!provider.isAddressesValid) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          BioIcon('close', size: 12, color: p.gray, strokeWidth: 2.5),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Informe origem e destino (endereços diferentes)', style: AppText.inter(size: 11.5, color: p.gray)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (provider.previewCo2 > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PREVER CO₂', style: AppText.mono(size: 10, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4)),
                          const SizedBox(height: 4),
                          Text(
                            '${fmtNumber(double.tryParse(provider.fuelLitersText.replaceAll(',', '.')) ?? 0, 0)} L × ${fmtNumber(provider.selectedFuelType.co2PerLiter, 2)} kg/L (${provider.selectedFuelType.label})',
                            style: AppText.inter(size: 11, color: p.gray2),
                          ),
                        ],
                      ),
                      Text('${fmtNumber(provider.previewCo2)} kg', style: AppText.mono(size: 20, weight: FontWeight.w700, color: AppColors.azul)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Calcular Impacto',
                icon: 'chev-r',
                loading: provider.isBusy,
                onPressed: canSubmit ? () => _calculate(provider) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressField(AppPalette p, String label, ValueChanged<String> onChanged, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: p.gray2, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          style: AppText.inter(size: 13, color: p.ink),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 6),
            hintText: hint,
            hintStyle: AppText.inter(size: 12, color: p.gray2),
            border: UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azul, width: 1.2)),
          ),
        ),
      ],
    );
  }
}
