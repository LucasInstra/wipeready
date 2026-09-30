# InventarioPC

App com interface gráfica para fazer o inventário do PC **antes de formatar**: hardware, chave do Windows, programas (com checklist do que manter), tamanho das pastas, backup de drivers e Wi-Fi, e kit de reinstalação via `winget`.

## Uso (no PC que será formatado, como administrador)

```powershell
powershell -ExecutionPolicy Bypass -File InventarioPC.ps1
```

## Abas

- **Resumo** — máquina, CPU, RAM, GPU, sistema e chave; exporta drivers e Wi-Fi; gera `relatorio.html`
- **Programas** — marque o que quer manter e salve a seleção (`selecao.json`/`selecao.csv`)
- **Pastas & Backup** — tamanho das pastas do usuário + lembrete do que copiar pro HD externo
- **Pós-formatação** — exporta `reinstalar.json` do winget

## Depois de formatar

```powershell
winget import -i reinstalar.json --accept-source-agreements --accept-package-agreements
```

## Saída

Tudo vai para `Desktop\inventario-pc\`. Copie essa pasta para o HD externo junto com seus arquivos.

## Licença

MIT
