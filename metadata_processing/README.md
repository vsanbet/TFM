# metadata_processing

Scripts de Python para construir y curar el metadata de la cohorte (`Afum_metadata.ods`): fusión de datos de distintas fuentes (SRA, colaboradores, ADMIXTURE, mutaciones de *cyp51A*) y reconciliación de nombres de muestra entre datasets.

No es un pipeline secuencial, son scripts puntuales usados durante el TFM para resolver cruces de datos concretos.

## Requisitos
```bash
pip install pandas biopython thefuzz odfpy --break-system-packages
```

> Los scripts tienen rutas absolutas hardcodeadas de las máquinas usadas en el TFM (`/mnt/c/Users/Valeria/...`, `/home/bettini/...`). Hay que adaptarlas antes de reutilizarlos.

## Scripts

| Script | Función |
|---|---|
| `parse_xml.py` | Extrae accession/título de un XML de SRA y lo cruza con datos de la colaboradora Emilia. |
| `re_coincidences_emilia.py` | Extrae claves numéricas de `Sample_Name` para emparejar nombres entre datasets. |
| `unique_repeat_samples.py` | Funciones varias para reconciliar nombres de muestra: separar duplicados, unir tablas, limpiar sufijos, *fuzzy matching*. |
| `unique_runs.py` | Compara runs descargados vs. esperados y lista los que faltan. |
| `list_reads.py` | Genera la lista de FASTQ esperados a partir del metadata. |
| `asign_cluster.py` | Asigna cluster de ADMIXTURE (K=6, vía CLUMPAK) a cada muestra y lo añade al metadata. |
| `get_organisims_cluster.py` | Selecciona muestras representativas por cluster de ADMIXTURE (prob. ≥ 0.99). |
| `merge_afum.py` / `merge_cluster_metadata.py` | Añaden clusters de ADMIXTURE (K=5/K=6) al metadata. |
| `cluster_change.py` | Renumera los IDs de cluster según un mapeo manual. |
| `cyp_cluster.py` | Asigna cluster filogenético de *cyp51A* a partir de listas de muestras por clado. |
| `aa_mut_cyp.py` | Detecta mutaciones de aminoácidos en *cyp51A* frente a la referencia y las añade al metadata. |
| `mutations_reduction.py` | Agrupa las mutaciones detectadas en categorías simplificadas (TR, WT, SNPs...). |
| `merge_emilia_metadata.py` | Añade al metadata propio los datos de mutaciones/origen de la colaboradora Emilia. |
