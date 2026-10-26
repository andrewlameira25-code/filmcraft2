# Relatório de Gaps e Paridade vs Adobe Premiere Pro (pt-BR)

> **Referência Técnica**: Adobe Premiere Pro 2026 (v26.5.2)  
> **Status Geral**: Fase Alpha (~86% de amplitude de recursos brutos, ~56% de prontidão para trabalho em produção real).

Este documento resume detalhadamente as 20 lacunas críticas catalogadas em `docs/gaps.md`, ordenadas pelo impacto impeditivo para que editores profissionais possam utilizar o FilmCraft em ambientes reais de pós-produção.

---

## 📊 Matriz Consolidada de Lacunas (Gaps G1 a G20)

| ID | Lacuna / Descrição Técnica | Categoria | Bloqueia Versão Beta? | Estimativa (Horas) |
|---|---|---|---|---|
| **G1** | Ausência de harness automatizado comparando saída visual/áudio com o Premiere | Medição / QA | Não (mas valida prontidão) | 40–70 h |
| **G2** | Impossibilidade de abrir projetos nativos do Premiere (`.prproj`) | Formatos de Arquivo | **Sim (Crítico)** | 60–120 h |
| **G3** | Mídias de câmera 10-bit e 4:2:2 exigem decodificação por hardware | Codecs | **Sim** | 30–50 h |
| **G4** | Falhas na inicialização e ausência de execução completa de testes em PRs | Estabilidade / CI | **Sim** | 40–80 h |
| **G5** | Aceleração por GPU parcial (ausência de zero-copy e efeitos faltantes) | Hardware / GPU | Parcialmente | 120–200 h |
| **G6** | Inexistência de corpus padronizado de mídias reais para testes end-to-end | Medição / QA | **Sim** | 40–70 h |
| **G7** | Ferramenta de paridade de menus e efeitos ausente no pipeline de CI | Medição / QA | Não | 10–20 h |
| **G8** | Fidelidade de interface (alças no monitor, controles de efeito, docking) | Interface / UX | Parcialmente | 120–200 h |
| **G9** | Estabilidade de runtime e testes contínuos no Windows e Linux | Plataformas | Parcialmente | 50–90 h |
| **G10** | Lacunas em contêineres e formatos de importação (MXF, AVCHD, ProRes RAW) | Formatos / Codecs | Parcialmente | 120–200 h |
| **G11** | Ausência de suporte à hospedagem de plugins (VST3, Audio Units, OpenFX) | Ecossistema | Não | 200–400 h |
| **G12** | Funcionalidades de Inteligência Artificial (Remoção de voz, Auto Reframe) | IA / Recursos | Não | 150–300 h |
| **G13** | Limitações em formatos de entrega (exportação H.264/H.265 via GPU no Windows) | Formatos / Saída | Não | 60–110 h |
| **G14** | Localização incompleta em idiomas chave (Hindi, Árabe, Vietnamita) | Localização | Não | 150–230 h |
| **G15** | Intercâmbio não validado em Avid Media Composer / Pro Tools (AAF/OMF) | Intercâmbio | Parcialmente | 20–40 h |
| **G16** | Relatórios de benchmark e medição contínua de performance | Performance | Parcialmente | 30–60 h |
| **G17** | Confiabilidade de dispositivos de áudio e latência de reprodução | Estabilidade | Parcialmente | 20–40 h |
| **G18** | Profundidade de efeitos (Lumetri curves, máscaras poligonais, distorções) | Recursos / FX | Não | 60–110 h |
| **G19** | Transcrição de fala para texto desabilitada em builds de release | Recursos / IA | Não | 5–10 h |
| **G20** | Shell e performance da versão web (WebAssembly) | Plataformas | Não | 40–80 h |

---

## 🎯 Detalhamento dos Gaps Mais Críticos para o Beta

### 1. Gap G2: Importação de Projetos do Premiere (`.prproj`)
- **Problema**: O arquivo `.prproj` do Premiere Pro é essencialmente um XML compactado com Gzip. Hoje o editor precisa exportar FCP7 XML, AAF ou OTIO a partir do Premiere para abrir no FilmCraft, perdendo pastas (bins), metadados e parâmetros refinados de efeitos.
- **Abordagem Técnica**: Engenharia clean-room a partir de projetos gerados internamente. Criar um parser em streaming (gzip -> XML) mapeando sequências, faixas, clipes, pontos de corte in/out, velocidade, transições, marcadores e parâmetros básicos de Transformação, Opacidade, Lumetri Básico e Volume.

### 2. Gap G3: Mídias de Câmera 10-bit e 4:2:2
- **Problema**: A maioria das câmeras mirrorless e de cinema atuais (Sony FX3/FX6 em XAVC S-I, Canon C70 em XF-AVC, Panasonic GH6/S5II em 10-bit 4:2:2) grava em perfis High 10 ou High 4:2:2. O decodificador H.264 por software do FilmCraft cobre apenas 8-bit 4:2:0. No Windows e Linux, sem decodificação por hardware correspondente, o clipe falha.
- **Plano de Solução**: Implementar suporte a perfis High 10 e High 4:2:2 no decodificador em Rust (`crates/h264`), adicionando deblocking, geometria de chroma 4:2:2 e matrizes de quantização estendidas.

### 3. Gap G4: Estabilidade de Inicialização e Gates de CI
- **Problema**: Inicializações falhavam sem aviso em GPUs antigas ou por falha no carregamento do Vulkan (`igvk64.dll`). Além disso, Pull Requests podiam introduzir regressões despercebidas por falta de execução de `cargo test` e `cargo xtask ci` em todos os sistemas operacionais.
- **Plano de Solução**: Fallback dinâmico entre backends gráficos (DirectX 12 -> WARP/Software) e reforço dos gatilhos de CI em `.github/workflows/ci.yml`.

### 4. Gap G5: Pipeline de GPU com Zero-Copy
- **Problema**: Atualmente, os quadros de vídeo decodificados por hardware são lidos de volta para a memória da CPU (`read-back`) e reenviados para a GPU via `wgpu`. Isso cria um gargalo severo de barramento PCIe em resoluções 4K e 8K.
- **Plano de Solução**: Implementar interoperação direta de memória de textura (D3D11 Texture Sharing no Windows / IOSurface no macOS) ligando o decodificador diretamente ao contexto do `wgpu`.
