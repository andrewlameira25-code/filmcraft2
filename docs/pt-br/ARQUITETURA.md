# Arquitetura do Sistema — FilmCraft

## 1. Visão Geral e Princípios Fundamentais

O **FilmCraft** é um editor de vídeo não-linear (NLE) de alta performance, construído em Rust puro (clean-room), projetado para atingir paridade com o Adobe Premiere Pro e superá-lo em estabilidade e extensibilidade.

### Princípios Arquiteturais Inegociáveis:
1. **Desacoplamento Rigoroso**: Nada abaixo da camada de interface (`L5`) depende de toolkits de UI (`egui`, `eframe`, `winit`, `cpal`, `rfd`) ou APIs diretas do sistema operacional.
2. **Tempo Exato (`filmcraft_time::Tick`)**: Nenhuma matemática de corte ou timeline utiliza ponto flutuante (`f64`). O tempo é discretizado em uma base exata de **254.016.000.000 ticks por segundo**, garantindo precisão absoluta sem erros de arredondamento em qualquer taxa de quadros (23.976, 24, 25, 29.97, 30, 50, 59.94, 60, 120 fps e taxas variáveis).
3. **Padrão de Comando Universal**: Toda mutação no estado do projeto ou da sessão é executada via comando (`crates/engine`), permitindo histórico infinito de Undo/Redo, reprodução serializada, macros e controle por canais externos (JSON e MCP).

---

## 2. Camadas do Workspace (Dependency Layering)

A hierarquia de dependências é estritamente unidirecional e verificada pelo gate de CI `cargo xtask layers`:

```
┌────────────────────────────────────────────────────────┐
│ Camada 5: Frontends & Aplicações                        │
│ apps/filmcraft, apps/filmcraft-cli, crates/ui-egui     │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Camada 4: Engine & Orquestração de Sessão               │
│ crates/engine, crates/automation                       │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Camada 3: Renderização, GPU & Exportação                │
│ crates/render, crates/gpu (wgpu), crates/export        │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Camada 2: Grafo de Edição, Legendas & Intercâmbio      │
│ crates/edit, crates/project, crates/interchange        │
│ crates/captions, crates/format                         │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Camada 1: Fundações de Mídia & DSP de Áudio            │
│ crates/media, crates/frame, crates/color, crates/geom  │
│ crates/time, crates/text, crates/audio-dsp             │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│ Camada 0: Codecs, Contêineres & Bitstream              │
│ h264, hevc, vp9, prores, av1, aac, opus, isobmff...    │
│ crates/bitstream (única dependência interna comum)     │
└────────────────────────────────────────────────────────┘
```

### Regras de Dependência:
- Crates de **Nível L0** (Codecs e Contêineres) dependem exclusivamente de `filmcraft-bitstream` e bibliotecas externas puras em Rust. Elas não conhecem conceitos de timeline, faixa ou clipe.
- Crates de **Nível L1 e L2** são totalmente portáveis e compiláveis para WebAssembly (WASM).
- O módulo **`crates/platform`** é o único componente autorizado a conter código `unsafe` (isolado sob FFI) para interagir com aceleradores de decodificação de hardware do SO (Media Foundation / Direct3D 11 no Windows, VideoToolbox no macOS, VA-API/NVDEC no Linux). Todas as chamadas possuem fallback obrigatório para os decodificadores puros em Rust.

---

## 3. Modelo de Tempo e Precisão Temporal

O tipo fundamental de tempo é `filmcraft_time::Tick`:
- **1 segundo = 254.016.000.000 ticks**.
- Essa constante é o mínimo múltiplo comum exato capaz de representar sem dízima ou truncamento:
  - Padrões de cinema (24, 48 fps);
  - Padrões de transmissão NTSC (24000/1001 ≈ 23.976 fps, 30000/1001 ≈ 29.97 fps, 60000/1001 ≈ 59.94 fps);
  - Padrões PAL/SECAM (25, 50 fps);
  - Frequências de amostragem de áudio profissionais (44.1 kHz, 48 kHz, 96 kHz, 192 kHz).

Datas de calendário e fusos horários utilizam exclusivamente a crate de workspace `chrono`.

---

## 4. Pipeline de Renderização e Grafo de Efeitos

A renderização é baseada em grafo acíclico dirigido (DAG):
1. **Amostragem de Mídia**: O `crates/media` requisita quadros no `Tick` solicitado. Se houver decodificador por hardware disponível no SO, ele é consultado primeiro; caso contrário, o decodificador nativo de software em Rust é utilizado.
2. **Transformações Geométricas & Espaço de Cor**: O `crates/color` converte os espaços de cor (Rec.709, Rec.2020, sRGB, Log) em ponto flutuante linear de 32 bits por canal.
3. **Composição e Efeitos (GPU/CPU)**:
   - No pipeline acelerado (`crates/gpu` via `wgpu`), os shaders realizam blend modes, transformações afins, Lumetri Color e filtros em pipelines de renderização na GPU.
   - Fallback por software: Se a GPU falhar ou o driver crashar (verificado em tempo de inicialização), o sistema chaveia automaticamente para o pipeline de CPU (`crates/render`) ou software WARP no Windows, garantindo que o software nunca feche inesperadamente.
4. **Mixagem de Áudio**: O `crates/audio-dsp` realiza reamostragem, ganho de volume em ponto flutuante de 32 bits, aplicação de equalizadores, compressores e pan estéreo/surround antes da entrega ao dispositivo de áudio ou codificador.

---

## 5. Automação e Extensibilidade

O FilmCraft expõe dois canais nativos de controle programático:
1. **Canal de Controle JSON (porta TCP 9876)**:
   - Protocolo baseado em linhas JSON (JSON-Lines).
   - Permite que ferramentas de orquestração, scripts de teste e agentes inspecionem a UI, despachem comandos e capturem capturas de tela do viewport (`ui.screenshot`).
2. **Servidor MCP (Model Context Protocol)**:
   - Permite acoplamento direto com LLMs e agentes inteligentes para edição autônoma via ferramentas padronizadas (`filmcraft-cli mcp`).
