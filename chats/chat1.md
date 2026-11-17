# BioTrack project design

_Started 2026-07-20 18:48 UTC_

---

## User

Crie o design descrito no documento do projeto biotrack

## Assistant

_[tool: list_files]_

_[tool: read_skill_prompt]_

_[tool: run_script]_

Li o documento — é bem completo (paleta, tipografia, componentes, fluxos, telas). Antes de começar, algumas perguntas rápidas sobre escopo:

_[tool: questions_v2]_

## User

Questions answered:
- surface: App mobile (Flutter)
- screens: Todos
- fidelity: Uma versão polida e completa
- interactive: Protótipo totalmente interativo
- tone: Decide for me
- data_realism: Decide for me
- language: Português (PT-BR)

## Assistant

_[tool: update_todos]_

_[tool: copy_starter_component]_

_[tool: read_file]_

Vou construir o protótipo interativo completo em uma única DC. Escolhendo o tom "clean corporativo com toques naturais" — mantendo a paleta definida no doc (#00D084, #1E3A8A) com Inter + JetBrains Mono.

_[tool: dc_write]_

_[tool: ready_for_verification]_

Protótipo BioTrack pronto — 12 telas navegáveis num iPhone interativo com:

- **Onboarding**: Landing, Login, Registar
- **Calculadora**: input funcional (litros × 2.31 kg/L), resultado com CO₂/árvores/economia, histórico persistente
- **Dashboard**: Operacional (KPIs, gráfico de projeção 12m, comparativo CO₂ vs Biometano) e Explorador (ranking, badges, XP)
- **Aprendizado**: 6 trilhas com progresso, detalhe com módulos
- **Relatórios ESG** e **Perfil**

Design segue o doc: paleta #00D084 / #1E3A8A / cinzas, Inter + JetBrains Mono, inputs com border-bottom, cards limpos. Painel lateral mostra endpoints da API e fórmulas de cálculo por tela. Clique na navegação lateral ou nos CTAs internos para navegar.

## User

Convert this design into a slide deck using the deck-stage starter component, then export it as a PPTX: `BioTrack.dc.html`

## Assistant

_[tool: copy_starter_component]_

Vou criar um deck separado (preservando o protótipo original) e depois exportar.

_[tool: dc_write]_

## User

consegue me entregar o código zip todo do front e o back igual nas especificações do docs com esse design?

## Assistant

Vou ser direto sobre o que consigo entregar aqui: eu sou uma ferramenta de **design** — produzo artefatos visuais e protótipos em HTML, não bases de código de produção. Gerar um projeto Flutter + Spring Boot completo, funcional e fiel ao documento (com autenticação JWT, MySQL, endpoints reais, etc.) está fora do que faço bem, e entregar isso "meio pronto" só te atrasaria.

O que **posso** entregar num zip agora:

1. **O protótipo interativo** (`BioTrack.dc.html`) — HTML standalone que roda offline, útil como referência visual/comportamental para os devs.
2. **Um pacote de handoff para desenvolvedores** — telas + specs (paleta, tipografia, componentes, fórmulas, lista de endpoints do doc) organizados para quem for implementar o front e o back.

Para o **código real** de front (Flutter) e back (Spring Boot), o caminho certo é usar essas telas como referência com uma ferramenta de desenvolvimento (ex.: Claude Code, ou o handoff que eu gero).

Quer que eu:

- **(A)** empacote o protótipo HTML standalone num zip para download, ou
- **(B)** gere o pacote de handoff para devs (design + specs + endpoints), ou
- **(C)** ambos?

E ainda tenho pendente o **deck + PPTX** que você pediu antes — retomo assim que confirmar isto.

