# Bloqueador Quickshell

Processo independente da barra, com `WlSessionLock` e autenticação PAM
pela política instalada de Hyprlock. A senha nunca é enviada em argumentos
ou gravada em arquivos. Apenas sucesso do PAM libera a sessão.

`rice-lock` abre o bloqueador; `rice-lock --preview` abre só a prévia visual.
`rice-lock --suspend` espera a confirmação de bloqueio antes de suspender.
O serviço `rice-lock-bridge` integra pedidos de Lock e suspensão via logind.

O visual usa o tema escolhido na barra: relógio/data no alto e campo de
senha em cápsula abaixo. Clique ou digitação revela o campo; movimento do
mouse não ativa. Um aviso com fundo mostra erros de autenticação.

- [Uso e atalhos](../../../docs/uso.md)
- [Isolamento, PAM, suspensão e recuperação](../../../docs/arquitetura.md)
- [Migração e fallback Hyprlock](../../../docs/migracao.md)

A prévia não é uma tela de bloqueio. Validação de autenticação real,
suspensão e hotplug exige teste interativo na máquina de destino.
