# Documentação Técnica do FilmCraft (pt-BR)

Bem-vindo ao centro de documentação técnica do **FilmCraft** em Português do Brasil. Este diretório foi estruturado para fornecer uma visão arquitetural completa, transparente e de alto rigor técnico para desenvolvedores, auditores de código e modelos de IA.

---

## 🧭 Mapa de Documentos

1. **[Arquitetura do Sistema](ARQUITETURA.md)**:
   - Estrutura de camadas rigorosa (L0 a L5).
   - Invariante de tempo exato (`Tick` a 254.016.000.000 unidades/segundo).
   - Barramento desacoplado de comandos e pipeline de renderização em grafo.

2. **[Regras Não-Negociáveis e Diretrizes de Segurança](REGRAS_E_DIRETRIZES.md)**:
   - Regra 0: **Never Crash** (eliminação completa de pânico em tempo de execução).
   - Proibição de código `unsafe` (isolado estritamente em `crates/platform` com FFI seguro).
   - Conformidade Clean-Room (proibição de assets ou engenharia reversa de softwares proprietários).
   - Políticas de licenciamento e sidecars de atribuição (`.attribution`).

3. **[Estabilidade, Runtime Windows e Gates de CI (Opção A)](ESTABILIDADE_E_WINDOWS.md)**:
   - Diagnóstico e mitigação de falhas de inicialização (GPU fallback para DirectX 12 e WARP/Software).
   - Tratamento de peculiaridades do Windows (caminhos de arquivo, normalização UTF-8, Direct3D 11 / Media Foundation).
   - Gates de qualidade locais e execução de CI (`cargo xtask ci`, `cargo xtask layers`, `cargo xtask assets`).

4. **[Relatório de Gaps e Paridade vs Adobe Premiere Pro](GAPS_E_PARIDADE.md)**:
   - Diagnóstico completo das 20 lacunas mapeadas (G1 a G20).
   - Status de paridade em codecs (10-bit, 4:2:2), aceleração por hardware e formatos de projeto (`.prproj`).
   - Estimativas de esforço e critérios de aceitação para o marco Beta.

5. **[Protocolo de Controle e Automação (MCP)](PROTOCOLO_AUTOMACAO.md)**:
   - Servidor de controle remoto via JSON-lines (porta 9876).
   - Integração headless via Model Context Protocol (MCP) para condução por agentes autônomos.

---

## 🛠️ Comandos Essenciais de Desenvolvimento

```powershell
# Executar a aplicação desktop nativa (com projeto de demonstração):
cargo run --release -p filmcraft

# Executar com servidor de controle remoto JSON habilitado na porta 9876:
cargo run --release -p filmcraft -- --control 9876

# Listar todos os comandos registrados na engine:
cargo run --release -p filmcraft-cli -- commands

# Executar o servidor MCP em modo headless:
cargo run --release -p filmcraft-cli -- mcp

# Executar a suíte completa de validação e qualidade (Quality Gates):
cargo xtask ci
```

---

## 📌 Glossário de Pós-Produção (pt-BR)

| Termo em Inglês | Tradução Padronizada | Definição no FilmCraft |
|---|---|---|
| **Clip** | Clipe | Unidade básica de mídia instanciada em uma faixa. |
| **Track** | Faixa | Trilhas horizontais de áudio ou vídeo na timeline. |
| **Sequence** | Sequência | Grafo de montagem contendo faixas, clipes e transições. |
| **Timeline** | Linha do Tempo | Representação temporal e espacial da sequência de edição. |
| **Playhead** | Cursor de Reprodução | Indicador da posição temporal atual de visualização (`Tick`). |
| **In / Out Point** | Ponto de Entrada / Saída | Delimitação temporal para inserção, extração ou reprodução. |
| **Keyframe** | Quadro-chave | Ponto de interpolação temporal de um parâmetro de efeito ou geometria. |
| **Frame Hold** | Quadro Congelado | Congelamento de um único quadro de vídeo ao longo do tempo. |
| **Ripple Trim** | Aparar em Cascata | Corte com deslocamento automático dos clipes subsequentes. |
| **Rolling Edit** | Edição Rolante | Ajuste do ponto de corte entre dois clipes sem alterar a duração total. |
| **Slip / Slide** | Deslizar Conteúdo / Clipes | Deslocamento do conteúdo interno do clipe ou da posição na faixa. |
| **Color Grading** | Gradação de Cor | Ajustes cromáticos e tonais (Lumetri, curvas, rodas de cor). |
