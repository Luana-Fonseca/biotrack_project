import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';

/// Shared Terms of Use / Privacy Policy content, written to satisfy LGPD (Lei
/// 13.709/2018) transparency requirements: what is collected, why, and how it
/// is stored. Reused as-is for both the profile's "Privacidade e segurança"
/// entry and the login/register "Termos de Uso" links, per product request.
class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: BioIcon('chev-l', size: 20, color: p.gray),
              ),
            ),
            const SizedBox(height: 16),
            Text('Termos de Uso e Privacidade',
                style: AppText.inter(size: 22, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Como o BioTrack coleta, usa e protege os seus dados, em conformidade com a LGPD.',
                style: AppText.inter(size: 13, color: p.gray)),
            const SizedBox(height: 24),
            _section(p, 'Quais dados coletamos', [
              'Dados de cadastro: nome completo, e-mail, senha, cidade e, opcionalmente, data de nascimento, profissão e foto de perfil.',
              'Dados de uso da calculadora: endereços de origem e destino informados, distância percorrida, tipo e volume de combustível, e os resultados calculados (CO₂ evitado, árvores equivalentes, economia estimada).',
              'Dados de progresso: XP, sequência de dias de uso (streak), posição no ranking e avanço nas trilhas de aprendizado.',
              'Relatórios gerados: tipo, período e conteúdo dos relatórios ESG em PDF criados na sua conta.',
            ]),
            _section(p, 'Como usamos os seus dados', [
              'Para realizar e exibir os cálculos de pegada de carbono e economia, e para gerar dashboards e relatórios ESG a partir deles.',
              'Para autenticar o seu acesso à conta (login) e manter sua sessão segura.',
              'Para comparar um novo cálculo com o seu próprio histórico e identificar consumos fora do padrão (nenhum dado de outros usuários é usado nessa comparação).',
              'Não vendemos nem compartilhamos os seus dados com terceiros para fins de marketing.',
            ]),
            _section(p, 'Como armazenamos e protegemos os seus dados', [
              'Sua senha nunca é armazenada em texto puro — apenas um hash criptográfico dela é guardado, que não pode ser revertido para a senha original.',
              'Os dados ficam armazenados no banco de dados do BioTrack enquanto a sua conta estiver ativa.',
              'O acesso à API é protegido por autenticação (token JWT), e a comunicação entre o aplicativo e o servidor é feita de forma autenticada.',
            ]),
            _section(p, 'Os seus direitos (LGPD — Lei 13.709/2018)', [
              'Confirmar a existência de tratamento dos seus dados e acessar os dados que temos sobre você.',
              'Corrigir dados incompletos, inexatos ou desatualizados a qualquer momento, pela tela de Editar Perfil.',
              'Solicitar a anonimização, o bloqueio ou a eliminação de dados desnecessários ou tratados em desacordo com a lei.',
              'Solicitar a portabilidade dos seus dados a outro fornecedor de serviço.',
              'Revogar o seu consentimento e solicitar o encerramento da sua conta e a exclusão dos seus dados a qualquer momento.',
            ]),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dúvidas ou solicitações sobre os seus dados',
                      style: AppText.inter(size: 13, weight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 6),
                  Text(
                      'Para exercer qualquer um dos direitos acima, entre em contato com o nosso canal de privacidade informado dentro do app.',
                      style: AppText.inter(size: 12, color: p.gray, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Última atualização: ao fazer alterações nestes termos, avisaremos você dentro do aplicativo.',
                style: AppText.inter(size: 11, color: p.gray2)),
          ],
        ),
      ),
    );
  }

  Widget _section(AppPalette p, String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.inter(size: 15, weight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 10),
          ...items.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.verde, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: AppText.inter(size: 12.5, color: p.gray, height: 1.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
