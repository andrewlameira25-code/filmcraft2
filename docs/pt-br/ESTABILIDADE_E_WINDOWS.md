# Estabilidade, Runtime Windows e Gates de CI — Opção A

Este guia técnico aborda as medidas de engenharia, diagnóstico de falhas e procedimentos operacionais necessários para assegurar estabilidade contínua, compilação consistente e execução no ambiente Windows.

---

## 1. Contexto e Diagnóstico no Windows

Historicamente, o desenvolvimento do FilmCraft esteve concentrado em ecossistemas Unix/macOS, gerando lacunas registradas em `docs/gaps.md` (especialmente **G4** - Falhas na inicialização e **G9** - Estabilidade de runtime no Windows e Linux).

### Principais Fatores de Instabilidade Mapeados:
1. **Drivers Gráficos e Falha na Inicialização do `wgpu`**:
   - Em certos sistemas Windows com GPUs integradas (ex.: Intel UHD Graphics via `igvk64.dll`), o driver Vulkan apresentava crash durante a enumeração de adaptadores.
   - **Solução Implementada (Fallback Progressivo)**: O FilmCraft possui um mecanismo resiliente de inicialização. Se duas inicializações consecutivas falharem dentro de 15 segundos sem desenhar o primeiro quadro:
     - O sistema chaveia automaticamente para o backend nativo **DirectX 12** (`--graphics dx12`);
     - Se o DirectX 12 falhar, ele retrocede para renderização de software via **WARP** (`--graphics software`), executando composição e shaders pela CPU.
     - É possível forçar o backend desejado definindo a variável de ambiente `WGPU_BACKEND=dx12` ou via parâmetro de linha de comando.
2. **Manipulação de Caminhos de Arquivo (Windows Path Normalization)**:
   - Caminhos no formato DOS estendido (`\\?\C:\...`) causavam falhas no importador CLI e no carregamento de projetos. A rotina de importação agora normaliza caminhos para UTF-8 absoluto canônico.
   - Extensões com maiúsculas/minúsculas (`.MOV`, `.MP4`, `.FCPROJ`) foram padronizadas para resolução sem distinção de caixa no Windows.
3. **Decodificação de Hardware com Media Foundation / Direct3D 11**:
   - No Windows, a aceleração de hardware opera através do subsistema Media Foundation ligado a superfícies D3D11.
   - Caso um formato (ex.: H.264 10-bit 4:2:2 ou HEVC RExt) não possua suporte nativo na GPU do usuário, a engine faz fallback automático para o decodificador puro em Rust sem interrupção de reprodução.

---

## 2. Configuração do Ambiente de Compilação no Windows

Para compilar, testar e executar o FilmCraft nativamente no Windows, os seguintes pré-requisitos são necessários:

### Pré-requisitos:
- **Rustup & Cargo** (Rust >= 1.95, edição 2024):
  ```powershell
  # Instalação via winget:
  winget install --id Rustlang.Rustup -e --silent
  
  # Atualização da toolchain estável:
  rustup default stable
  rustup update
  ```
- **Compilador C++ e SDK do Windows (MSVC)**:
  - Necessário para link-editores do Windows (`link.exe`) e chamadas de API do subsistema Direct3D/Media Foundation.
  - Pode ser instalado através do [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_buildtools.exe) com a carga de trabalho "Desenvolvimento para Desktop com C++".

---

## 3. Comandos de Validação e Gates de CI no Windows

Antes de submeter código ou abrir pull requests, execute os gates de validação:

```powershell
# 1. Compilação rápida e checagem de tipos em todos os pacotes:
cargo check --workspace --all-targets

# 2. Execução da análise estática estrita (zero avisos):
cargo clippy --workspace --all-targets -- -D warnings

# 3. Execução dos testes unitários e de integração:
cargo test --workspace

# 4. Verificação das camadas de arquitetura (enforce L0 -> L5):
cargo xtask layers

# 5. Verificação de sidecars de atribuição de recursos:
cargo xtask assets

# 6. Execução consolidada de todos os gates:
cargo xtask ci
```

---

## 4. Estrutura de CI no GitHub Actions (`.github/workflows/ci.yml`)

O repositório utiliza o fluxo consolidado de CI compartilhado através de `storytold/craft-common-actions/.github/workflows/gate.yml@main`.

- **Gatilhos**: Executado em todo `push` para a branch `main` e em todos os `pull_request`.
- **Matriz de Execução**: Executa a suíte de testes e os testes de camada (`cargo xtask layers`) em contêineres e runners dedicados.
- **Cancelamento Concorrente**: Pushes subsequentes em um mesmo Pull Request cancelam automaticamente execuções anteriores em andamento, economizando minutos de runner e acelerando o feedback para a equipe de engenharia.
