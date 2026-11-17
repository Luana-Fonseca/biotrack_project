package com.biotrack.api.learning;

import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

/**
 * Seeds the ESG/sustainability trilhas and modules on first boot, and transparently replaces
 * an older seed generation with the current one (detected by the first trilha's title) so a dev
 * database created before a content update doesn't get stuck showing stale text. Not meant to
 * preserve user data across content generations — {@link ModuleProgress} rows tied to replaced
 * modules are cleared along with them, since the modules themselves no longer exist.
 */
@Component
public class LearningDataSeeder {

    /** Bump this whenever the seed content below changes shape, so existing dev DBs upgrade. */
    private static final String CURRENT_GENERATION_MARKER = "Trilha 1: Análise de Impacto";

    private final TrilhaRepository trilhaRepository;
    private final ModuleRepository moduleRepository;
    private final ModuleProgressRepository progressRepository;

    public LearningDataSeeder(TrilhaRepository trilhaRepository, ModuleRepository moduleRepository,
                               ModuleProgressRepository progressRepository) {
        this.trilhaRepository = trilhaRepository;
        this.moduleRepository = moduleRepository;
        this.progressRepository = progressRepository;
    }

    @PostConstruct
    public void seed() {
        boolean upToDate = trilhaRepository.findAllByOrderByOrderIndexAsc().stream()
                .findFirst().map(t -> CURRENT_GENERATION_MARKER.equals(t.getTitle())).orElse(false);
        if (upToDate) {
            return;
        }
        progressRepository.deleteAll();
        moduleRepository.deleteAll();
        trilhaRepository.deleteAll();

        seedTrilha(
                "Trilha 1: Análise de Impacto",
                "Entenda a pegada de carbono, o CO2 evitado e como ler os números do app.",
                "leaf", "trilha_impacto.png", 0,
                new String[][]{
                        {"O que é a Pegada de Carbono?", "5", """
                                EXPLICACAO: Gases de Efeito Estufa (GEE) formam uma barreira química na atmosfera que retém o calor do sol na Terra. A "Pegada de Carbono" é a soma de todos os rastros de emissão desses gases que as nossas atividades diárias (comer, dirigir, consumir) deixam no planeta. No Brasil, a média por habitante é de impressionantes 11 toneladas de CO₂ ao ano.
                                ANALOGIA: Imagine que a pegada de carbono é uma "mochila invisível". A cada vez que você liga um carro a combustão ou consome produtos ultraprocessados, um novo "tijolo" de poluição é colocado nela. Ao final do ano, essa mochila se torna um fardo térmico gigantesco para o planeta carregar.
                                CURIOSIDADE: O metano, liberado no lixo orgânico e na pecuária, aquece a Terra quase 28 vezes mais que o CO₂.
                                CURIOSIDADE: A média de 11 toneladas do cidadão brasileiro supera fortemente a média global de 7 toneladas por pessoa.
                                RESUMO: A pegada de carbono é a conta acumulada da poluição invisível que deixamos no planeta todos os dias.
                                """},
                        {"Entendendo o CO2 Evitado", "5", """
                                EXPLICACAO: Evitar emissões significa escolher proativamente uma tecnologia limpa no lugar de uma poluente, impedindo que o gás chegue à atmosfera. A conta é simples: subtrai-se a poluição da escolha ecológica da poluição que teria ocorrido na escolha tradicional. Essa é a métrica que transforma o esforço ambiental em um número de sucesso.
                                ANALOGIA: É exatamente igual a poupar dinheiro no cartão de crédito. Se você decide não comprar algo supérfluo, aquele dinheiro foi "evitado" de virar dívida. Ir de bicicleta para o trabalho "poupa" a sua cota diária de poluição atmosférica.
                                CURIOSIDADE: Trocar uma frota de diesel por biometano evita a emissão de até 95% do CO₂ equivalente.
                                CURIOSIDADE: Dirigir o mesmo carro usando técnicas econômicas evita até 15% de consumo e poluição sem precisar trocar de veículo.
                                RESUMO: O CO₂ evitado é a poluição que você ativamente impediu de existir ao fazer escolhas mais inteligentes na rotina.
                                """},
                        {"Traduzindo em Árvores e Água", "5", """
                                EXPLICACAO: Transformar quilos de um gás invisível em métricas reais ajuda o cérebro a compreender a urgência. As árvores nativas usam o CO₂ na fotossíntese para criar troncos e crescer. Além disso, a pegada de carbono está totalmente ligada à água, já que o tratamento e bombeamento hídrico consomem quantias maciças de energia.
                                ANALOGIA: Ler gráficos com números puros de emissões é como ver o preço de um imóvel em uma moeda estrangeira desconhecida. Converter esses kgCO₂ em "árvores plantadas" ou "banhos curtos" funciona como uma taxa de câmbio instantânea para a mente.
                                CURIOSIDADE: Reduzir o tempo de banho do chuveiro elétrico de 15 para 10 minutos economiza dezenas de litros de água tratada de uma só vez.
                                CURIOSIDADE: Um hectare de Mata Atlântica em recuperação tem força biológica para absorver dezenas de toneladas de carbono por ano.
                                RESUMO: Converter dados de gases em florestas preservadas e litros de água traduz a matemática da ciência climática para a vida real.
                                """},
                        {"Como ler os seus Resultados", "5", """
                                EXPLICACAO: Como soltamos diversos tipos de gases diferentes, a ciência unificou a medição na métrica "Quilograma de CO₂ Equivalente" (kgCO₂e). Ela mede o poder de aquecimento de qualquer gás (como metano ou óxido nitroso) e traduz para o peso do CO₂. É olhando para o kgCO₂e no aplicativo que usuários e empresas definem suas metas mensais de redução.
                                ANALOGIA: Da mesma forma que convertemos moedas do mundo todo (dólares, euros e ienes) para Reais a fim de saber o valor total do nosso patrimônio, usamos o CO₂e para somar toda a mistura de poluentes em uma só "moeda" climática.
                                CURIOSIDADE: O gás Óxido Nitroso (N₂O), oriundo de fertilizantes agrícolas, possui um poder de estufa terrível, 273 vezes pior que o CO₂ comum.
                                CURIOSIDADE: Estipular metas anuais de redução de 5% a 10% cria uma curva de hábito alcançável e extremamente eficaz a longo prazo.
                                RESUMO: O kgCO₂e é a moeda universal que permite ler, comparar e reduzir o impacto de todas as suas atividades em um único gráfico claro.
                                """},
                        {"Teste de Conhecimento", "6", """
                                QUESTAO: Para que serve a métrica de Quilograma de CO₂ Equivalente (kgCO₂e)?
                                A: Para medir a quantidade de água da chuva ácida.
                                B: Para calcular apenas a queima de gasolina e diesel.
                                C: Para unificar o poder de aquecimento de vários gases diferentes em uma única medida.
                                D: Para pesar os restos de lixo orgânico.
                                GABARITO: C
                                EXPLICACAO: A métrica kgCO₂e funciona como uma "moeda padrão", permitindo somar diferentes gases poluentes num único número comparável.
                                QUESTAO: Qual é o conceito central do "CO₂ Evitado"?
                                A: É o carbono que o escapamento não conseguiu queimar direito.
                                B: É a poluição que deixou de ser gerada graças à escolha por uma alternativa sustentável.
                                C: É o gás que escapou dos biodigestores para a atmosfera.
                                D: É a quantidade de oxigênio que as árvores liberam no dia.
                                GABARITO: B
                                EXPLICACAO: Assim como poupar dinheiro evita dívidas, fazer trocas verdes evita ativamente que mais gases poluam o planeta.
                                QUESTAO: Por que o aplicativo BioTrack converte emissões de gases em dados como árvores e água?
                                A: Porque o gás carbônico é composto de seiva de árvore.
                                B: Para ajudar a vender produtos de jardinagem.
                                C: Porque facilita o cálculo automático dos impostos estaduais.
                                D: Para traduzir números abstratos em impactos reais e facilmente visualizáveis na nossa rotina.
                                GABARITO: D
                                EXPLICACAO: O cérebro humano entende melhor quando substituímos toneladas invisíveis de gás por exemplos palpáveis, como banhos e plantios.
                                """},
                });

        seedTrilha(
                "Trilha 2: ESG e Sustentabilidade no Dia a Dia",
                "Descomplique o ESG e aprenda a reconhecer o greenwashing.",
                "esg", "trilha_esg.png", 1,
                new String[][]{
                        {"Descomplicando o ESG", "5", """
                                EXPLICACAO: ESG é a sigla para Ambiental, Social e Governança. É o novo padrão global que audita se empresas e pessoas protegem a natureza, respeitam a dignidade dos trabalhadores e agem com ética contra fraudes. Hoje, consumidores exigem produtos atrelados a esses valores, forçando a migração do mercado para práticas mais verdes.
                                ANALOGIA: O ESG é como um banco de sentar com três pernas. Se uma empresa lucra e tem boa Governança, trata bem a equipe no aspecto Social, mas destrói o pilar Ambiental poluindo um rio, a terceira perna quebra e a reputação da empresa desaba por completo.
                                CURIOSIDADE: Investidores institucionais estão bloqueando trilhões de dólares para empresas sem conformidade ESG comprovada.
                                CURIOSIDADE: Práticas sólidas de governança não só protegem o planeta como barateiam os seguros empresariais.
                                RESUMO: ESG é a prova auditável de que uma organização cuida do planeta, valoriza seres humanos e atua com transparência ética absoluta.
                                """},
                        {"Cuidados com o Meio Ambiente (E)", "5", """
                                EXPLICACAO: A letra "E" (Ambiental) diz respeito à eficiência dos recursos em casas e negócios. Na prática, trata-se de abolir aparelhos antiquados, consertar desperdícios de água e praticar economia circular desviando o lixo orgânico dos aterros a céu aberto para a compostagem ou biodigestão.
                                ANALOGIA: A eficiência energética é como tapar os furos no fundo de um balde antes de colocar mais água dentro. É muito mais inteligente estancar o desperdício em casa do que construir usinas gigantescas para gerar energia.
                                CURIOSIDADE: O chuveiro elétrico brasileiro chega a consumir entre 5.500W e 7.500W, sendo um dos maiores "vampiros" de energia da casa.
                                CURIOSIDADE: No Estado de São Paulo, o biogás capturado do lixo dos aterros gera energia para centenas de milhares de habitações.
                                RESUMO: O maior aliado do meio ambiente é a redução implacável do desperdício diário de energia, água e lixo.
                                """},
                        {"Pessoas e Ética na Prática (S e G)", "5", """
                                EXPLICACAO: O pilar Social foca na segurança, diversidade e impacto nas comunidades vizinhas. A Governança exige lideranças independentes e auditorias anticorrupção rigorosas. Cuidar das populações é essencial, pois os grupos historicamente vulnerabilizados costumam sofrer de forma desproporcional com a poluição.
                                ANALOGIA: Imagine um time de futebol profissional: o Social assegura que os jogadores recebam salários justos, saúde e que não haja discriminação. Já a Governança é a regra da arbitragem e o uso do VAR, garantindo total transparência e ausência de trapaças.
                                CURIOSIDADE: Estudos confirmam que a degradação ambiental castiga de forma mais cruel populações de favelas, periferias e indígenas.
                                CURIOSIDADE: Equipes diretivas que estimulam a diversidade resolvem crises corporativas com muito mais rapidez e inovação.
                                RESUMO: Não existe salvação ambiental verdadeira se a natureza não for acompanhada de dignidade social e justiça ética.
                                """},
                        {"Como Identificar Empresas Sustentáveis", "5", """
                                EXPLICACAO: "Greenwashing" (lavagem verde) é quando uma marca gasta fortunas com marketing para parecer verde, mas na verdade tem um modelo de negócio extremamente poluente e destrutivo. Termos soltos como "Produto 100% Ecológico" e embalagens verdes são as armas principais da falsa sustentabilidade.
                                ANALOGIA: Praticar greenwashing é como pintar a fachada de uma casa que tem fundações completamente podres com tinta verde e nova. Parece bonita por fora, atrai o cliente, mas os problemas graves continuam ocultos sob a pintura.
                                CURIOSIDADE: Cerca de 85% das alegações verdes impressas em supermercados falham na comprovação científica dos dados.
                                CURIOSIDADE: A certificação independente rigorosa, como o "Sistema B" (B-Corp), é a melhor defesa do consumidor para descobrir quem fala a verdade.
                                RESUMO: Para escapar da mentira do Greenwashing, ignore rótulos atrativos com linguagem vaga e exija certificações sustentáveis de auditores independentes.
                                """},
                        {"Teste de Conhecimento", "6", """
                                QUESTAO: O que representa a sigla ESG na avaliação das empresas?
                                A: Economia, Serviço e Gestão.
                                B: Ambiental, Social e Governança.
                                C: Engenharia, Sustentabilidade e Globalização.
                                D: Energia, Sustentabilidade e Gás.
                                GABARITO: B
                                EXPLICACAO: A sigla norteia boas práticas para proteger o meio ambiente (E), as pessoas (S) e a ética corporativa (G).
                                QUESTAO: Considerando o cuidado com o pilar Ambiental (E) dentro de casa, qual aparelho é considerado um grande vilão de gasto de energia?
                                A: Lâmpadas de LED.
                                B: Televisores modernos.
                                C: Chuveiros elétricos.
                                D: Modems de internet.
                                GABARITO: C
                                EXPLICACAO: Com potência que pode ultrapassar os 7.000 Watts, o chuveiro demanda altíssima carga da rede elétrica em pouco tempo.
                                QUESTAO: O que define a prática de "Greenwashing"?
                                A: O uso de água reciclável para lavagem industrial.
                                B: A substituição completa de frota fóssil por elétrica.
                                C: Campanhas de marketing falsas ou exageradas para que a marca pareça sustentável sem agir.
                                D: Um tipo de certificado auditado altamente rigoroso.
                                GABARITO: C
                                EXPLICACAO: A lavagem verde ocorre quando o dinheiro vai para a propaganda ecológica, enquanto a empresa continua poluindo de forma oculta.
                                """},
                });

        seedTrilha(
                "Trilha 3: Mobilidade e Transporte Limpo",
                "O impacto dos motores fósseis, os combustíveis do futuro e o eco-driving.",
                "truck", "trilha_mobilidade.png", 2,
                new String[][]{
                        {"O Impacto dos Transportes no Planeta", "5", """
                                EXPLICACAO: Motores a gasolina e diesel são verdadeiros vilões climáticos, injetando toneladas de CO₂ e fuligem negra na atmosfera. As micropartículas exaladas pelos escapamentos (PM2.5) invadem os pulmões das pessoas nas cidades, causando um surto urbano de asma infantil, AVCs e mortes.
                                ANALOGIA: Morar em uma metrópole asfixiada pelo diesel dos veículos afeta o sistema respiratório das pessoas com a mesma severidade do tabagismo passivo: respirar o ar de um grande engarrafamento é análogo a fumar até 5 cigarros no mesmo dia.
                                CURIOSIDADE: O setor rodoviário solta mais de 40% do pó inalável letal encontrado nas grandes cidades, como São Paulo.
                                CURIOSIDADE: A poluição gerada por veículos na capital paulista mata anualmente um número de pessoas que é cerca de 3 vezes superior aos acidentes de trânsito.
                                RESUMO: A frota convencional fóssil transforma as avenidas em corredores de chaminés letais para a saúde pública e para a temperatura da Terra.
                                """},
                        {"Combustíveis do Futuro", "5", """
                                EXPLICACAO: O futuro da mobilidade está focado no Biometano, Eletricidade, Etanol e Biodiesel. A matriz elétrica evita 100% da poluição local e brilha no Brasil porque nossa rede já possui fontes de energia altamente renováveis e intensidades de carbono super baixas. Para veículos ultra-pesados, o Biometano brilha forte como o grande antídoto contra o diesel.
                                ANALOGIA: Trocar combustíveis fósseis por alternativas renováveis é como substituir uma dieta de fast-food nociva por alimentos de alto valor nutricional. O motor continua entregando potência, mas o "corpo" do planeta fica desintoxicado e ágil.
                                CURIOSIDADE: Como o Brasil é impulsionado por água e vento, a intensidade da pegada de carbono da nossa tomada é 5 vezes mais limpa que a média global.
                                CURIOSIDADE: O Biometano possui o poder incrível de fulminar quase por completo o material particulado pesado expelido pelos canos de descarga.
                                RESUMO: Dos motores silenciosos nas cidades ao torque bruto do biometano nas estradas, as opções do futuro garantem que o país não pare enquanto o ar volta a ser puro.
                                """},
                        {"Veículos Elétricos e a Gás", "5", """
                                EXPLICACAO: Nos elétricos, enormes baterias transferem elétrons silenciosamente para as rodas, com aceleração suave. Mas as carretas gigantes precisam puxar dezenas de toneladas, o que faria o peso das baterias se tornar inviável. A solução é o motor a Biometano: ele inflama o gás com potências extremas sob pressões gigantes, abafando o barulho e cortando o fumo.
                                ANALOGIA: O motor do carro elétrico roda liso e macio como as pás de um ventilador potente e sem ruído. Já o caminhão a biometano usa a chama forte, limpa e azulada dos fogões industriais: tem potência agressiva para o peso, mas zero sujeira escura.
                                CURIOSIDADE: A engenharia moderna faz com que caminhões pesados a biometano atinjam de 460 até 560 cavalos, gerando torques esmagadores para subir serras.
                                CURIOSIDADE: Como caminhões a gás são bem mais silenciosos, a logística urbana os prefere amplamente para não incomodar os bairros durante as madrugadas.
                                RESUMO: Seja com a levitação fluida da eletricidade ou com a explosão azul do biometano, as inovações mecânicas derrotaram a necessidade da poluição preta no asfalto.
                                """},
                        {"Hábitos e Rotas Eficientes", "5", """
                                EXPLICACAO: Ter hardware ecológico não é o bastante; quem conduz tem peso gigantesco nas emissões. O "Eco-driving" envolve aceleração fluida, manter velocidades cruzeiro razoáveis, cuidar religiosamente da pressão dos pneus e usar a telemetria do GPS para jamais perder horas parados e rodando atoa nos trânsitos intensos.
                                ANALOGIA: Conduzir com eficiência é espelhar a tática de um maratonista de elite: usar passos e fôlego constantes para ir muito longe. Acelerar de forma grosseira para frear bruscamente depois equivale a dar tiros de corrida, o que esgota a energia (e o tanque) no início da jornada.
                                CURIOSIDADE: O simples fato de circular a 100 km/h, em vez de focar na faixa mais calma dos 80 km/h, penaliza em até 20% o consumo do tanque.
                                CURIOSIDADE: Um pneu descalibrado, girando 20% abaixo do exigido, aumenta fortemente o atrito e consome 1,7% a mais de todo o seu combustível.
                                RESUMO: A serenidade e inteligência do condutor nas ruas salvam tanto impacto climático e financeiro quanto a mais avançada engenharia automobilística.
                                """},
                        {"Teste de Conhecimento", "6", """
                                QUESTAO: Qual impacto o combustível fóssil dos carros tem gerado no ar de São Paulo?
                                A: Mata de asfixia as aves das rodovias brasileiras.
                                B: Gera mais mortes anuais na saúde pública local do que os próprios acidentes de trânsito.
                                C: Reduz levemente a temperatura do centro histórico da cidade.
                                D: Impede que o combustível limpo seja processado em postos.
                                GABARITO: B
                                EXPLICACAO: A forte emissão inalável ataca o sistema cardiovascular, gerando óbitos muito além dos riscos diários nas estradas.
                                QUESTAO: Por que o biometano é a melhor escolha para substituir o diesel em caminhões pesadíssimos e grandes frotas logísticas rodoviárias?
                                A: Porque pode ser estocado no assoalho.
                                B: Porque os veículos elétricos recarregam rápido demais nas serras.
                                C: Porque entrega a mesma força brutal do motor a diesel, mas sem o peso colossal que baterias enormes demandariam na estrada.
                                D: Porque ele solta faíscas maiores no motor de 4 tempos.
                                GABARITO: C
                                EXPLICACAO: O Biometano consegue manter os torques massivos dos cavalos mecânicos com o bônus excepcional de quase apagar a poeira poluidora.
                                QUESTAO: Como a prática do Eco-driving prevê a ação de manter os pneus calibrados?
                                A: Evita o aumento do atrito no solo, economizando consideravelmente as taxas de combustível a longo prazo.
                                B: Garante mais tração na chuva mas gasta mais ar da bomba.
                                C: Facilita o desgaste do pneu para que a borracha recicle mais rápido.
                                D: Ajuda apenas no amortecimento sem afetar o painel.
                                GABARITO: A
                                EXPLICACAO: Pneus descalibrados pesam no movimento; cuidar dessa calibragem faz a inércia render e evita a queima extra de energia inútil.
                                """},
                });

        seedTrilha(
                "Trilha 4: Biometano e Energia Renovável",
                "Da digestão anaeróbica aos CBIOs: como o lixo vira combustível limpo.",
                "flame", "trilha_biometano.png", 3,
                new String[][]{
                        {"Do Lixo à Energia: O que é Biometano?", "6", """
                                EXPLICACAO: O Biometano é a glória maior da economia circular, gerado na "Digestão Anaeróbica". Bactérias devoram material podre (lixo urbano orgânico, estrume) dentro de tanques fechados sem oxigênio. As quatro fases desse show metabólico rápido (Hidrólise, Acidogênese, Acetogênese e Metanogênese) quebram a sujeira e expelem o gás limpo e purificado que empurrará os motores das carretas.
                                ANALOGIA: Imagine um gigantesco estômago mecânico blindado de aço agindo igual ao estômago das vacas bovinas: ingere a sujeira e restos apodrecidos no escuro total e arrota o valioso gás canalizado, que acende luzes e empurra as frotas em vez de infestar a atmosfera com enxofre ruim.
                                CURIOSIDADE: Além de fornecer tração pesada para transportes, o processo bloqueia a evaporação natural dos lixões e esgotos fétidos que envenenavam as comunidades globais.
                                CURIOSIDADE: O potencial do país é assustadoramente gigante: o Brasil possui volume biológico para substituir enormes percentuais do diesel diário nacional.
                                RESUMO: A digestão anaeróbica é o maquinário milagroso que anula toneladas infindáveis de lixo repulsivo e devolve metano com pura força energética à humanidade.
                                """},
                        {"Biometano nos Veículos", "6", """
                                EXPLICACAO: Para atuar nas ruas, a molécula é idêntica ao que os injetores térmicos necessitam para girar as polias. Chamada de estratégia "drop-in", grandes fornecedoras e empresas de distribuição pegam os modelos atuais aptos e despejam a versão do gás verde recém extraído, cortando com isso entre 90% a incríveis 95% do CO₂ de sua malha de abastecimento rodoviário.
                                ANALOGIA: Essa transição de combustível emula a experiência de colocar grãos limpos de café orgânico colhido na fazenda na mesma cafeteira industrial gigante que operava grãos podres de baixa qualidade; o aparelho motor não sente o abalo mecânico, porém a pureza da extração (escapamento veicular) se torna inigualável e cristalina.
                                CURIOSIDADE: Testes laboratoriais constataram eliminação quase cirúrgica na casa dos 99% a 100% dos particulados inaláveis (PM10).
                                CURIOSIDADE: A combustão sob os blocos a gás atua silenciando o temido barulho metálico pesado das engrenagens.
                                RESUMO: Trocar a alimentação da frota pesada destrói por completo a nuvem tóxica mantendo rigorosamente intacto todo o esqueleto mecânico da potência de tração e força rodoviária de alto nível.
                                """},
                        {"Biometano x Combustíveis Tradicionais", "6", """
                                EXPLICACAO: O diesel escavado rasga reservas extintas lá da terra funda enchendo a superfície com novos poluentes mortais. Na oposição, o processo de metanização aproveita só o ciclo em que vivemos reciclando ativamente. Mas o seu ás de ouro é o "Digestato": o líquido residual extraído da usina se converte em super adubos agronômicos (NPK natural) enchendo as safras verdes em total substituição de venenos e fertilizantes químicos perigosos que libertavam o mortal N₂O na agricultura.
                                ANALOGIA: Pagar por petróleo externo é trazer sujeira inédita importada ao seu castelo limpo. Processar Biometano e Digestato é rastelar as próprias folhas orgânicas do seu quintal interior: gerar a luz para todo o espaço fechado gratuitamente e ainda nutrir o seu campo de cultivo interno perfeitamente sem comprar veneno caro no balcão químico alheio.
                                CURIOSIDADE: O salto do impacto fóssil cortado bate a casa insana dos quase 95% de poupança.
                                CURIOSIDADE: Regressar os digestatos para dentro do agronegócio bloqueia enxurradas e derrames químicos lixiviados das lavouras em direção a rios de consumo doméstico.
                                RESUMO: O reinado inquestionável do sistema orgânico limpa os motores nas longas estradas urbanas, purifica os céus em cidades abafadas, expulsa lixões mortais da periferia e injeta nutrição farta nos solos sem venenos e químicos pesados industriais.
                                """},
                        {"O Biometano no Brasil e Selos Verdes", "6", """
                                EXPLICACAO: Usufruindo de megaprojetos espalhados, como grandes aterros metropolitanos e UVSs em São Paulo, o lixão alimenta enormes corporações (como Natura no país), desidratando o rastro. Para garantir à bolsa global e ao mercado internacional a pureza desses tanques isolando mentiras ambientais, os fornecedores ganham um certificado infalsificável fiscal emitido sob a chancela RenovaBio: os CBIOs. Atrelado a isenções diretas do ICMS feitas estrategicamente pelo Governo Paulista no ramo, garante um mercado altamente confiável, barato e rentável.
                                ANALOGIA: Receber os títulos dos valiosos CBIOs das autoridades financeiras e reguladoras brasileiras reflete na prática obter a marca-d'água brilhante forense nos vistos e cédulas em passaportes federais autênticos, confirmando matematicamente ao inspetor ou ao cliente mais descrente da logística de rua a idoneidade, ética corporativa e fiscalização extrema da pegada limpa daquela rodagem rodoviária contra furos ambientais ilegais pesados da indústria comum concorrente não ecológica moderna.
                                CURIOSIDADE: Leis audaciosas de isenção de impostos ICMS de São Paulo protegeram e agilizaram maciçamente os caixas das empresas migratórias no gás.
                                CURIOSIDADE: Os títulos auditados contabilizam só do impacto líquido efetivamente deixado fora do ar sujo contrapostos ferozmente na balança comparativa ao gasóleo sujo tradicional original que seria outrora queimado suando as pistas federais inteiras brasileiras nas velhas décadas.
                                RESUMO: Respaldado em isenções fiscais agressivas locais e rigorosos selos governamentais como a chancela dos CBIOs anti-fraudes, o país desbrava como imenso gigante global das tecnologias de descarbonização em frotas rodoviárias e energia verde inesgotável baseada inteiramente na reutilização ativa de entulhos orgânicos valiosíssimos de seus super pólos populosos.
                                """},
                        {"Teste de Conhecimento", "6", """
                                QUESTAO: O Biometano resulta da atividade da digestão anaeróbica (sem oxigênio). Quais são as 4 fases biológicas dessa transformação?
                                A: Trituração, Filtragem Térmica, Ignição e Expansão.
                                B: Hidrólise, Acidogênese, Acetogênese e Metanogênese.
                                C: Centrifugação, Precipitação, Alcalinização e Pasteurização.
                                D: Fermentação Láctea, Evaporação, Secagem e Resfriamento.
                                GABARITO: B
                                EXPLICACAO: A sequência das bactérias quebrando os resíduos sólidos até formar o valioso gás passa exatamente por essas quatro etapas bioquímicas fundamentais.
                                QUESTAO: O que se faz no campo e lavouras com o precioso "Digestato" extraído após a retirada do biogás da usina purificadora anaeróbica?
                                A: Ele é descartado na natureza como lixo estéril imprestável.
                                B: É enterrado nos poços artesianos subterrâneos esgotados no fundo das pedreiras como rejeito.
                                C: É revendido para queimar como gasolina rústica de forma bruta.
                                D: Serve como biofertilizante natural carregado dos nutrientes fundamentais de NPK para revigorar solos do agronegócio e diminuir adubos químicos perigosos.
                                GABARITO: D
                                EXPLICACAO: O lodo restante estabilizado é uma das fontes mais puras e orgânicas de adubos agrícolas seguros, sem os efeitos tóxicos de fertilizantes químicos pesados.
                                QUESTAO: Como um produtor no Brasil hoje assegura a originalidade limpa (contra o Greenwashing) perante investidores das reduções reais do seu gás via RenovaBio?
                                A: Emitindo panfletos promocionais impressos distribuídos livremente.
                                B: Colocando selos simples desenhados pelos seus publicitários do departamento.
                                C: Vendendo apenas em leilões internacionais não fiscalizados com fotos de ecossistemas belos.
                                D: Através da conquista validada por entidades federais dos Créditos de Descarbonização hiper auditados chamados CBIOs no pregão.
                                GABARITO: D
                                EXPLICACAO: Esse mecanismo legal e auditado emite recibos monetizáveis exatos de abatimento, comprovando a efetividade ecológica real da rodagem verde, blindada da farsa do greenwashing.
                                """},
                });
    }

    private void seedTrilha(String title, String description, String icon, String coverImage, int orderIndex, String[][] modules) {
        Trilha trilha = trilhaRepository.save(new Trilha(title, description, icon, coverImage, orderIndex));
        for (int i = 0; i < modules.length; i++) {
            String[] m = modules[i];
            moduleRepository.save(new Module(trilha, i, m[0], Integer.parseInt(m[1]), m[2].strip()));
        }
    }
}
