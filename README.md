# Carcini Calc 🦐

Aplicativo **offline** de calculadoras de carcinicultura para pequenos produtores
sem internet. Flutter web + Android, com banco local (sembast / IndexedDB).

## O que tem

- **12 calculadoras** de manejo (densidade, povoamento, sobrevivência, peso
  médio, ganho de peso, crescimento semanal, TCE, biomassa, arraçoamento, CAA,
  produtividade, renovação de água).
- **Viveiros** com biometria semanal + qualidade de água (faixas ABCC).
- **Projeção do ciclo** (aba): crescimento esperado × biometria e planilha
  diária de arraçoamento.
- **Recomendação de arraçoamento** diária — *Litopenaeus vannamei*, tabela
  FAO, com interpolação da taxa por peso, nº de tratos e uso de bandeja.

## Rodar localmente

```bash
flutter pub get
flutter run -d chrome        # web
flutter run                  # ou num dispositivo Android
```

Testes e análise:

```bash
flutter test
flutter analyze
```

## Publicar a versão web (gratuito, sempre atualizada)

O repositório tem um workflow (`flutter build web` + GitHub Pages) que publica
o app automaticamente a cada `push` na branch `main`. Na primeira vez:

1. Suba o repositório para o GitHub e rode, na primeira subida, o workflow
   "Deploy web (GitHub Pages)".
2. No GitHub: **Settings → Pages → Source: GitHub Actions**.
3. O link fica em `https://<usuario>.github.io/<repositorio>/`.

Depois, qualquer `git push` recompila e republica sozinho (alguns minutos).

> O app usa rotas com `#` (`/#/projecao`) para funcionar em host estático,
> inclusive com refresh em qualquer tela.
