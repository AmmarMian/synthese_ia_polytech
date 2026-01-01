# Synthèse sur l'IA dans l'enseignement supérieur

Document de synthèse de 20 pages analysant l'impact de l'intelligence artificielle générative dans l'enseignement supérieur français, avec application au cas de Polytech Annecy-Chambéry.

## 📋 Aperçu

- **Auteur** : Ammar Mian, Maître de conférences (USMB / Polytech)
- **Langue** : Français académique
- **Format** : LaTeX (pdflatex + bibtex + makeglossaries)
- **Pages cibles** : ~20 pages
- **Dernière mise à jour** : 29 décembre 2024

## 📁 Structure du document

```
content/
├── 0_abstract.tex              # Résumé FR + Abstract EN
├── 1_methodology.tex           # Méthodologie (3 subsections)
├── 2_axes_definition.tex       # Définition des 7 axes
├── 3_axe1_fondements.tex       # Fondements techniques & réglementaires
├── 4_axe2_ethique.tex          # Enjeux éthiques et conformité
├── 5_axe4_usages.tex           # État des usages (étudiants, enseignants)
├── 6_axe5_gouvernance.tex      # Gouvernance institutionnelle
├── 7_recommandations.tex       # Recommandations + feuille de route
└── glossary.tex                # Définitions des acronymes

configuration.tex               # Packages LaTeX et préambule
version.tex                     # Numéro version et date
references.bib                  # Bibliographie (~50+ références)
main.tex                        # Fichier principal
```

## 🎯 Contenu par section

| Section | Pages | Contenu |
|---------|-------|---------|
| **Abstract** | 0.5 | Résumé français + Abstract anglais |
| **1. Méthodologie** | ~2 | Stratégie recherche, corpus, transparence IA |
| **2. Définition axes** | ~1.2 | Genèse des 7 axes, justification, articulation |
| **3. Fondements (Axe 1)** | ~6-7 | IA générative : définitions, état de l'art, cadre réglementaire |
| **4. Éthique (Axe 2)** | ~3 | AI Act, intégrité académique, impact environnemental |
| **5. Usages (Axe 4)** | ~3 | État des usages Polytech, freins/leviers |
| **6. Gouvernance (Axe 5)** | ~4 | Écosystème français, chartes, formations, stratégie Polytech |
| **7. Recommandations** | ~2 | 8 recommandations, feuille de route 2026-2028 |
| **Bibliographie** | 1-2 | References.bib compilée |

**Total : ~19.5 pages (cible : 20)**

## 🚀 Compilation

### Prérequis
- `pdflatex` (TeX Live / MacTeX)
- `bibtex`
- `makeglossaries` (glossaries package)

### Commande complète
```bash
cd document_synthèse
rm -f *.aux *.bbl *.blg *.fls *.glg *.gls *.out  # Nettoyage
pdflatex main.tex
bibtex main
makeglossaries main
pdflatex main.tex
pdflatex main.tex    # 3ème passe pour références finales
```

### Ou via script (si disponible)
```bash
./compile.sh
```

### Résultat
Génère `main.pdf` (document compilé)

## 📚 Éléments visuels

### Tableaux
- Utilise `booktabs` pour style académique
- Placés avec `\begin{table}[htbp]...\end{table}`
- Titres et labels `\caption{}` / `\label{}`

### Figures
- Diagrammes TikZ pour schémas conceptuels
- Graphiques pgfplots pour données chiffrées
- Figures scientifiques en haute qualité

### Boîtes de définition
- Environnement `definitionbox` (tcolorbox)
- Utilisé pour concepts clés et définitions institutionnelles
- Barre de titre noire, contenu blanc

### Listes encadrées
- Format énuméré numéroté `\begin{enumerate}[label=\textbf{\arabic*.}]`
- Concepts clés en gras, descriptions courtes
- Utilisé pour limites techniques, applications, risques

## 🔗 Références

- Toutes les références sont dans `references.bib`
- **NE PAS MODIFIER** references.bib directement
- Utiliser `\cite{clé}` dans le texte
- Format : IEEE (bibliographystyle{IEEEtran})

### Acronymes disponibles
Gérés via `glossaries` package. Utiliser `\gls{acronyme}` dans le texte :
```latex
\gls{ia}        → Intelligence Artificielle (IA) [1ère fois], puis IA
\glspl{llm}     → Pluriel
\Gls{ia}        → Majuscule début phrase
```

**Acronymes clés** : `ia`, `genai`, `llm`, `men`, `aiact`, `rgpd`, `cnil`, etc.

## ✏️ Guide de rédaction

### Style
- Français académique naturel (pas de "il est important de noter que...")
- Phrases variées (longueurs, structures, connecteurs)
- Ton informatif mais engagé

### Conventions LaTeX

**Citations multiples** :
```latex
\cite{pascal2025ia}                    % Simple
\cite{wang2025meta,deng2025chatgpt}    % Multiple
```

**Tableaux** :
```latex
\begin{table}[htbp]
\centering
\caption{Titre}
\label{tab:exemple}
\begin{tabular}{lcc}
\toprule
Col1 & Col2 & Col3 \\
\midrule
Données & ... & ... \\
\bottomrule
\end{tabular}
\end{table}
```

**Définitions** :
```latex
\begin{definitionbox}[Titre]
Contenu avec \gls{acronymes} et \cite{références}.
\end{definitionbox}
```

**Listes encadrées** :
```latex
\begin{enumerate}[label=\textbf{\arabic*.}, leftmargin=1.5cm]
  \item \textbf{Concept} : Description courte
  \item \textbf{Concept} : Description courte
\end{enumerate}
```

**Espacement** :
```latex
\bigskip   % Espace large (entre concepts majeurs)
\medskip   % Espace moyen (entre sections)
```

## 📝 État d'avancement

- ✅ **Sections rédigées** : 7/7 (100%)
- ✅ **Abstract** : Complet (FR + EN)
- ✅ **Éléments visuels** : Tableaux, figures TikZ, definitionbox, listes
- ✅ **Références** : ~50+ sources, toutes citées
- ✅ **Acronymes** : 20+ définitions, utilisation systématique
- ⏳ **Conclusion** : À rédiger dans main.tex (dernier élément manquant)

## 🔄 Workflow de travail

1. **Éditer une section** : Modifier fichier dans `content/`
2. **Compiler** : Lancer compilation complète (voir section Compilation)
3. **Vérifier** : Ouvrir `main.pdf` et valider rendu
4. **Mettre à jour CLAUDE.md** : Documenter modifications

## ⚙️ Configuration LaTeX

**Fichier** : `configuration.tex`

Inclut :
- Packages standard (babel, inputenc, geometry, hyperref)
- Packages spécialisés (booktabs, tcolorbox, tikz, pgfplots)
- Préambule commun et environnements personnalisés
- Définition couleurs, polices, marges

**À modifier si** : Ajout packages, changement mise en page, nouvelles commandes

## 🐛 Problèmes courants

### Compilation échoue
```bash
# Nettoyer les fichiers auxiliaires
rm -f *.aux *.bbl *.blg *.fls *.glg *.gls *.out *.log
# Relancer compilation
pdflatex main.tex
```

### Acronymes n'apparaissent pas
- Vérifier `makeglossaries main` a été lancé
- Relancer `pdflatex` après `makeglossaries`

### Références manquantes
- Vérifier `\cite{clé}` correspond à clé dans `references.bib`
- Relancer `bibtex main` et `pdflatex`

### Figures TikZ mal rendues
- Vérifier syntaxe TikZ dans section correspondante
- Vérifier packages tikz + pgfplots dans configuration.tex

## 📞 Support

Pour questions sur la rédaction, consulter :
- `/CLAUDE.md` — Suivi complet du projet
- Historique des sessions (dans CLAUDE.md)
- Commentaires dans fichiers content/ (si présents)

---

**Dernière compilation** : À faire
**Version du document** : V. \version (voir version.tex)
