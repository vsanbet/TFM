import matplotlib.pyplot as plt
import pandas as pd

ruta = "/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods"

def plot_susceptibilidad(df, group_col, titulo, xlabel, output_path, figsize=(8, 5), rotation=0):
    counts = df.groupby([group_col, 'Azole_susceptibility']).size().unstack(fill_value=0)
    
    for col in ['R', 'S', 'I']:
        if col not in counts.columns:
            counts[col] = 0
    counts = counts[['R', 'S', 'I']]
    
    # Convertir a porcentaje
    percentages = counts.div(counts.sum(axis=1), axis=0) * 100
    
    ax = percentages.plot(kind='bar', stacked=True,
                          color={'R': 'red', 'S': 'green', 'I': 'orange'},
                          figsize=figsize)
    
    # Añadir etiquetas de porcentaje en cada segmento
    for container in ax.containers:
        ax.bar_label(container, fmt='%.1f%%', label_type='center', fontsize=8)
    
    plt.xlabel(xlabel)
    plt.ylabel('Porcentaje de muestras (%)')
    plt.title(titulo)
    plt.xticks(rotation=rotation, ha='right' if rotation > 0 else 'center')
    plt.ylim(0, 100)
    plt.legend(title='Susceptibilidad')
    plt.tight_layout()
    plt.savefig(output_path)
    plt.show()


# --- POR SUSCEPTIBILIDAD (cluster) ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[(metadata['Our Cluster'] != '-') & metadata['Our Cluster'].notna()].copy()

plot_susceptibilidad(
    df, 'Our Cluster',
    titulo='Susceptibilidad a azoles por cluster (%)',
    xlabel='Cluster',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/susceptibilidad_por_cluster.pdf'
)

# --- POR PAÍS ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[metadata['Country_of_origin'].notna()].copy()

plot_susceptibilidad(
    df, 'Country_of_origin',
    titulo='Susceptibilidad a azoles por país (%)',
    xlabel='País',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/susceptibilidad_por_pais.pdf',
    figsize=(12, 5), rotation=45
)

# --- POR SOURCE ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[metadata['Source'].notna()].copy()

plot_susceptibilidad(
    df, 'Source',
    titulo='Susceptibilidad a azoles por fuente de aislamiento (%)',
    xlabel='Source',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/susceptibilidad_por_source.pdf',
    figsize=(12, 5), rotation=45
)

### POR NUMEROS Y NO PORCENTAJE
import matplotlib.pyplot as plt
import pandas as pd

ruta = "/mnt/c/Users/Valeria/Desktop/Afum_metadata.ods"

def plot_susceptibilidad(df, group_col, titulo, xlabel, output_path, figsize=(8, 5), rotation=0):
    counts = df.groupby([group_col, 'Azole_susceptibility']).size().unstack(fill_value=0)
    
    for col in ['R', 'S', 'I']:
        if col not in counts.columns:
            counts[col] = 0
    counts = counts[['R', 'S', 'I']]
    
    ax = counts.plot(kind='bar', stacked=True,
                     color={'R': 'red', 'S': 'green', 'I': 'orange'},
                     figsize=figsize)
    
    # Etiquetas con números absolutos (ocultar si el valor es 0)
    for container in ax.containers:
        labels = [f'{int(v)}' if v > 0 else '' for v in container.datavalues]
        ax.bar_label(container, labels=labels, label_type='center', fontsize=8)
    
    plt.xlabel(xlabel)
    plt.ylabel('Número de muestras')
    plt.title(titulo)
    plt.xticks(rotation=rotation, ha='right' if rotation > 0 else 'center')
    plt.legend(title='Susceptibilidad')
    plt.tight_layout()
    plt.savefig(output_path)
    plt.show()


# --- POR SUSCEPTIBILIDAD (cluster) ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[(metadata['Our Cluster'] != '-') & metadata['Our Cluster'].notna()].copy()

plot_susceptibilidad(
    df, 'Our Cluster',
    titulo='Susceptibilidad a azoles por cluster (n)',
    xlabel='Cluster',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/n_susceptibilidad_por_cluster.pdf'
)

# --- POR PAÍS ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[metadata['Country_of_origin'].notna()].copy()

plot_susceptibilidad(
    df, 'Country_of_origin',
    titulo='Susceptibilidad a azoles por país (n)',
    xlabel='País',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/n_susceptibilidad_por_pais.pdf',
    figsize=(12, 5), rotation=45
)

# --- POR SOURCE ---
metadata = pd.read_excel(ruta, sheet_name='final_metadata', engine='odf')
df = metadata[metadata['Source'].notna()].copy()

plot_susceptibilidad(
    df, 'Source',
    titulo='Susceptibilidad a azoles por fuente de aislamiento (n)',
    xlabel='Source',
    output_path='/mnt/c/Users/Valeria/Desktop/resultados_tfm/Figuras/stacked_plots/n_susceptibilidad_por_source.pdf',
    figsize=(12, 5), rotation=45
)