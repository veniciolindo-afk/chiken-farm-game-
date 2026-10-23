# Arquitetura técnica

- **Engine:** Godot 4.3
- **Linguagem:** GDScript
- **Renderização:** GL Compatibility para celulares e navegadores
- **Persistência:** save JSON em `user://`
- **Arte v0.1:** primitivas 3D, sem dependências externas

A cena `scenes/main.tscn` inicia `scripts/main.gd`, que monta o mundo, a interface e o loop econômico. Em versões futuras, economia, save, visual e HUD serão separados em módulos próprios.

O workflow em `.github/workflows` valida o projeto, exporta Web e gera um APK Android de teste. Uma versão de loja exigirá assinatura release, ícones finais, política de privacidade e cadastro na Play Console.
