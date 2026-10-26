# Protocolo de Controle Remoto e Automação (MCP) — FilmCraft

O FilmCraft foi desenhado desde o primeiro dia com um princípio fundamental: **tudo o que pode ser feito por um operador humano via mouse e teclado pode ser acionado programaticamente por agentes e ferramentas de automação**.

Este documento especifica os dois canais de automação nativos: o **Servidor de Controle JSON** e o **Servidor MCP (Model Context Protocol)**.

---

## 1. Servidor de Controle JSON (Porta TCP 9876)

Ao executar a aplicação desktop com a flag `--control [porta]`:

```powershell
cargo run --release -p filmcraft -- --control 9876
```

O FilmCraft inicia um servidor TCP local que escuta mensagens no formato **JSON-Lines** (cada mensagem é um objeto JSON delimitado por quebra de linha `\n`).

### Formato de Mensagens:

#### 1.1 Requisição:
```json
{
  "id": 1,
  "method": "app.state",
  "params": {}
}
```

#### 1.2 Resposta de Sucesso:
```json
{
  "id": 1,
  "result": {
    "version": "0.13.0",
    "project_open": true,
    "active_sequence": "Seq_01",
    "playhead_tick": 10160640000000
  }
}
```

#### 1.3 Resposta de Erro:
```json
{
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Comando desconhecido ou parâmetros inválidos"
  }
}
```

### Principais Métodos Disponíveis:

| Método | Descrição | Parâmetros de Exemplo |
|---|---|---|
| `app.state` | Retorna o estado geral da aplicação e do projeto ativo. | `{}` |
| `cmd.exec` | Despacha um comando registrado no barramento da engine. | `{"id": "edit.cut", "params": {}}` |
| `cmd.list` | Lista todos os comandos disponíveis, atalhos e rótulos. | `{}` |
| `project.open` | Abre um projeto existente a partir do caminho de arquivo. | `{"path": "C:/Projetos/Demo.fcproj"}` |
| `project.save` | Salva o projeto atualmente aberto. | `{}` |
| `timeline.seek` | Posiciona o cursor de reprodução (`playhead`) no Tick exato. | `{"tick": 2540160000000}` |
| `ui.screenshot` | Captura uma imagem PNG do frame atual ou de um painel específico. | `{"target": "program_monitor"}` |
| `ui.inspect` | Retorna a árvore de acessibilidade e identificadores de automação. | `{}` |

---

## 2. Servidor MCP (Model Context Protocol)

O FilmCraft implementa a especificação oficial do **Model Context Protocol** em modo headless através da crate `apps/filmcraft-cli`:

```powershell
cargo run --release -p filmcraft-cli -- mcp
```

### Casos de Uso:
- Conexão nativa com agentes autônomos (Claude Desktop, IDEs inteligentes e scripts orquestradores).
- O agente tem acesso a ferramentas declarativas padronizadas:
  - `import_media(file_path)`: Importa mídias para a pasta de projeto.
  - `create_sequence(name, fps, width, height)`: Cria nova sequência de montagem.
  - `insert_clip(track_id, clip_id, start_tick, duration_tick)`: Insere cortes na timeline.
  - `apply_effect(clip_id, effect_id, parameters)`: Aplica ajustes de cor ou filtros.
  - `export_sequence(output_path, preset)`: Dispara renderização e exportação de arquivo final.

### Vantagens do MCP Headless:
1. **Zero Sobrecarga Gráfica**: Não requer GPU ou inicialização de janelas de UI para testes em lote ou render farms.
2. **Determinismo**: Cada operação produz um estado serializável e reproduzível.
3. **Resiliência a Falhas**: Operações executadas sob MCP possuem tratamento estrito de erros, sem risco de pânico no processo.
