# population_study

Scripts para el estudio de la estructura poblacional de la cohorte a partir del VCF filtrado: PCA, inferencia de ancestría con ADMIXTURE y visualización conjunta con el árbol filogenómico.

## Requisitos
```bash
pip install biopython numpy pandas scipy matplotlib odfpy --break-system-packages
```
R: `ggplot2`, `dplyr`, `tidyr`, `readODS`, `ggtext`, `plotly`
Otros: PLINK, ADMIXTURE 1.3.0, CLUMPAK (solo para `clustering.R`)


## Scripts

| Script | Función |
|---|---|
| `run_admixture.sh` | Array job (SLURM) que ejecuta ADMIXTURE para K=1–10 con 10 réplicas por K, cada una con su semilla y validación cruzada. |
| `cv_graph.R` | Grafica el error de validación cruzada frente a K para elegir el número óptimo de clusters. |
| `clustering.R` | Barplot de ancestría (K=5) a partir de la salida ya alineada por CLUMPAK, resaltando las muestras españolas. |
| `plink_pca.R` | PCA 3D interactivo y 2D (PC1–PC3) coloreado por cluster, a partir de los resultados de PLINK. |
| `plot_tree_admixture.py` | Combina el árbol filogenómico con las barras de ADMIXTURE en una sola figura, alineando los runs con el algoritmo húngaro (sin depender de CLUMPAK). |
