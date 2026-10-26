# Regras Não-Negociáveis e Diretrizes de Engenharia — FilmCraft

Este documento estabelece as regras mandatórias que regem todos os colaboradores humanos e agentes de IA que atuam no repositório do FilmCraft. Em qualquer situação de divergência, estas regras prevalecem sobre qualquer outro documento ou preferência pessoal.

---

## 0. Regra Fundamental: NUNCA DÊ CRASH ("Never Crash")

Os usuários confiam ao FilmCraft horas ininterruptas de trabalho criativo. Um arquivo malformado, um comando inválido, um parâmetro corrompido, um atalho incomum ou disco cheio devem **sempre** resultar em um erro tratável pelo usuário, **nunca em encerramento abrupto (crash) e nunca em perda de trabalho**.

> **Esta regra outorga prioridade absoluta sobre o desenvolvimento de novas funcionalidades.** Não entregue uma funcionalidade adicionando caminhos de pânico. Corrija qualquer crash antes de construir sobre ele.

### Diretrizes Operacionais da Regra 0:
1. **Propagação com `Result<T, E>`**: Todas as funções passíveis de falha devem retornar `Result` e propagar erros com o operador `?`. Adicione contexto útil (`map_err`) em vez de descartar a causa raiz. Na interface gráfica, exiba o erro na barra de status ou em diálogo modal e continue a execução.
2. **Proibição de Atalhos com Pânico em Código de Produção**:
   - É terminantemente proibido o uso de `unwrap()`, `expect()`, `panic!()`, `unreachable!()`, `todo!()` ou `unimplemented!()` fora do diretório de testes (`tests/`).
   - Use `?`, `ok_or(..)?`, `let Some(x) = .. else { return Err(..) }`, `if let`, ou um valor padrão comprovadamente seguro (nunca um que corrompa silenciosamente o projeto).
   - Funcionalidades incompletas retornam erro de "não suportado".
   - A única exceção para `#[allow(clippy::expect_used)]` é para código comprovadamente infalível localmente (ex.: parser de constante estática ou literal estático), com justificativa explícita no comentário.
3. **Proibição de Código `unsafe`**:
   - O workspace adota `unsafe_code = "forbid"`.
   - A única exceção é `crates/platform` (`unsafe_code = "deny"`), exclusiva para comunicação FFI com APIs de decodificação de hardware do sistema operacional (VideoToolbox, Media Foundation / Direct3D 11, VA-API, NVDEC). Todo bloco `unsafe` exige comentário `// SAFETY:` minucioso, API pública segura retornando `Result` e fallback nativo em Rust testado.
4. **Todo Dado Derivado de Entrada é Hostil**:
   - Arquivos de mídia, projetos, presets, fontes, parâmetros de linha de comando/MCP/RPC e estados de interface não são confiáveis.
   - Indexe slices e coleções com `.get()` em vez de indexação direta `[i]`.
   - Fatie strings apenas em fronteiras de caracteres válidas (`char_indices`).
   - Use aritmética segura (`checked_*`, `saturating_*`) para durações, tamanhos e offsets.
   - **Nunca divida por valores que possam ser zero** (taxas de quadros, escalas de tempo, taxas de amostragem de áudio, dimensões).
   - Não converta valores negativos ou `NaN` diretamente para inteiros.
   - Limite o tamanho de alocações de memória orientadas por dados de arquivo.
5. **Recursão e Laços Bounded**: Projetos podem conter sequências aninhadas recursivas ou loops cíclicos. Caminhe sobre grafos com conjuntos de visitação (`HashSet`) ou limites estritos de profundidade.
6. **Não Propagação em Cascata**: Envenenamento de travas (`RwLock`/`Mutex`) não deve matar a thread: use `lock().unwrap_or_else(PoisonError::into_inner)`. Tarefas em segundo plano (exportação, proxies, decodificação) rodam sob `catch_unwind` para que uma falha isolada de worker não trave a aplicação.

---

## 1. Diretrizes de Clean-Room e Licenciamento de Ativos

Esta regra é absoluta. A infração destas diretrizes acarreta remoção imediata do código ou ativo.

1. **Proibição de Ativos Proprietários (Adobe)**:
   - Nunca use iconografia, imagens, cursores, logotipos, telas de abertura (splash screens) ou capturas de tela do Adobe Premiere Pro ou produtos correlatos.
   - Nunca importe fontes, tabelas LUT, predefinições, modelos ou áudios da Adobe.
   - Nossos ícones podem seguir convenções visuais genéricas do mercado (play, lâmina de corte, cronômetro), mas devem ser desenhados do zero em código ou vetor livre.
2. **Todo Ativo Deve Ser Aberto e Licenciado**:
   - Licenças aceitas: MIT, Apache-2.0, BSD, ISC, zlib, SIL OFL, Domínio Público / CC0, ou Creative Commons (CC BY ou CC BY-SA; proibido NC/ND).
   - Caso a licença de uma mídia seja duvidosa, ela não entra no repositório.
3. **Sidecar de Atribuição Obrigatório (`.attribution`)**:
   - Todo arquivo de mídia ou recurso visual `X` deve possuir um arquivo irmão `X.attribution` especificando: ativo, título, autor, fonte, licença e notas de confecção.
   - Uma entrada correspondente deve ser adicionada em `ATTRIBUTION.md`. O comando `cargo xtask assets` é executado no CI e falhará caso qualquer ativo não esteja catalogado.
4. **Código Clean-Room**:
   - Nunca desmonte ou examine binários de aplicações proprietárias.
   - Nunca copie código GPL/LGPL/AGPL (FFmpeg, x264, x265, MLT, Kdenlive, Shotcut).
   - Implemente codecs e especificações técnicas a partir de padrões abertos (ITU-T, ISO/IEC, IETF RFC, SMPTE). FFmpeg/ffprobe podem ser usados exclusivamente como ferramentas externas de teste de oráculo e geração de amostras em `target/fixtures/` — nunca linkados ou distribuídos com o binário.

---

## 2. Padrões de Qualidade e Gates de CI (Quality Gates)

Antes de qualquer commit, a suíte local de qualidade deve ser satisfeita:

```powershell
# 1. Checagem de formatação:
cargo fmt --check

# 2. Análise estática profunda (zero warnings tolerados):
cargo clippy --workspace --all-targets -- -D warnings

# 3. Testes unitários e de integração do workspace:
cargo test --workspace

# 4. Verificação de arquitetura de camadas:
cargo xtask layers

# 5. Verificação de integridade e licenciamento de ativos:
cargo xtask assets

# 6. Verificação de compatibilidade WASM (camadas L0 a L4):
cargo xtask wasm

# Execução consolidada de todos os gates:
cargo xtask ci
```
