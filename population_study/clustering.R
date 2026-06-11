library(readODS)
library(dplyr)
library(tidyr)
library(ggplot2)

# ---- K=5 ----
file <- 'C:/Users/Valeria/Desktop/admixture/k5/1777278390/K=5/CLUMPP.files/ClumppIndFile.output'
Q <- read.table(file, header = FALSE, fill = TRUE)
cat("Filas:", nrow(Q), "| Columnas:", ncol(Q), "\n")

# Para K=5 las probabilidades están en V6:V10, para 6 en v6:11
prob_cols <- paste0("V", 6:10)

# Cargar lista de muestras
names_list <- read.table('C:/Users/Valeria/Desktop/admixture/samples_maf_cluster.txt')

# Cargar metadatos
meta <- read_ods("C:/Users/Valeria/Desktop/Afum_metadata.ods", sheet = 4)
mini_meta <- meta[, c("Sample_Name", "BioinfoName")]

# Identificar Sample_Names con múltiples lecturas
nombres_duplicados <- mini_meta %>%
  group_by(Sample_Name) %>%
  filter(n() > 1) %>%
  pull(Sample_Name) %>%
  unique()

# Construir tabla de nombres
samples <- data.frame(BioinfoName = names_list$V1) %>%
  left_join(mini_meta %>% distinct(BioinfoName, .keep_all = TRUE), by = "BioinfoName") %>%
  mutate(display_name = case_when(
    is.na(Sample_Name) ~ BioinfoName,                                    # no está en metadata
    Sample_Name %in% nombres_duplicados ~ paste0(Sample_Name, "_", BioinfoName),  # varias lecturas → CM237_SRR001
    TRUE ~ Sample_Name                                                    # único → nombre limpio
  ))

cat("Muestras en lista:", nrow(samples), "\n")
cat("Nombres únicos:", length(unique(samples$display_name)), "\n")

# Verificar que coincidan
stopifnot(nrow(Q) == nrow(samples))

# Agregar nombres
Q$sample_name <- samples$display_name

# Cluster dominante
Q$cluster <- apply(Q[, prob_cols], 1, which.max)

# Ordenar por cluster
Q$max_prob <- apply(Q[, prob_cols], 1, max)          # pureza = prob máxima
Q_ordenado  <- Q[order(Q$cluster, -Q$max_prob), ]    # 1º cluster, 2º pureza desc

# Formato largo
Q_long <- Q_ordenado %>%
  select(sample_name, all_of(prob_cols)) %>%
  pivot_longer(cols = all_of(prob_cols),
               names_to = "cluster",
               values_to = "probabilidad") %>%
  mutate(cluster = recode(cluster,
                          V6  = "Cluster 5",
                          V7  = "Cluster 4",
                          V8  = "Cluster 1",
                          V9  = "Cluster 2",
                          V10 = "Cluster 3"))
                          #V11 = "Cluster 6"))

Q_long$sample_name <- factor(Q_long$sample_name, levels = unique(Q_ordenado$sample_name))

mis_colores <- c(
  "Cluster 1" = "red",
  "Cluster 2" = "#2196F3",
  "Cluster 3" = "#2A9D8F",
  "Cluster 4" = "purple",
  "Cluster 5" = "orange",
  "Cluster 6" = "navy"
)

cluster_plot <- ggplot(Q_long, aes(x = sample_name, y = probabilidad, fill = cluster)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = mis_colores) +
  labs(x = "Individuo", y = "Porcentaje", fill = "Cluster") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 3))

cluster_plot
ggsave('C:/Users/Valeria/Desktop/resultados_tfm/Figuras/admixture/k5/clustering_japanese_5.svg', plot = cluster_plot, width = 20, height = 12, units = "in", dpi = 1200)
ggsave('C:/Users/Valeria/Desktop/admixture/k5/clustering_japanese_5.pdf', plot = cluster_plot, width = 20, height = 12, units = "in", dpi = 1200)

# Poner en negrita las muestras españolas
# install.packages("ggtext")

library(ggtext)

bioinfo_negrita <- c(
  "CM3249", "CM3249b", "CM3720", "CM4602", "CM3262", "CM2733", "CM2730",
  "30", "313", "CM2495", "13888", "4863", "4819", "CM4946", "CM3248",
  "CM7632", "CM237", "CM2580", "CM5419", "29", "AF293", "CM2141", "CM5757",
  "CM6126", "CM6458", "CM7510", "CM7555", "CM7570", "akuBKU80", "ATCC46645",
  "CEA10", "2762619", "CM2123", "CM3271", "CM3819", "CM3820", "CM4599",
  "CM4862", "CM4896", "CM5390", "CM5536", "CM5703", "CM5907", "CM6051",
  "CM6616", "CM7467", "CM7496", "CM7582", "CM7609", "CM8190", "CM8535",
  "CM8714", "CM8900", "CM9103", "ES36254", "ES4649", "ES48850", "ES5784",
  "H-104", "M10731", "R13", "T18", "T22", "TP-14988", "TP-391", "TP-436",
  "TP-494", "TP-579", "TP-90812", "CM2097", "CM2159", "CM3273", "CM3277",
  "CM3936", "CM4023", "CM4050", "CM4594", "CM6052", "CM8755", "CM8940",
  "CM9114", "ES7601", "ES7913", "ES36359", "ES42518", "ES49519", "ES59287",
  "TP16", "TP17", "TP5", "CM9103R", "CM8057R", "CM9396", "CM9339", "CM9364",
  "CM9399", "CM9554", "CM9670", "CM9701", "CM9886", "CM9971", "T11R",
  "CM10027", "CM10052", "CM10079", "TP1003", "TP1004", "TP10", "ETP3",
  "TP1005", "H100", "H208", "CM10227", "CM10228", "CM10238", "CM10311",
  "CM10332", "ETP1", "ETP2", "CM10198", "CM10305", "CM9702", "CM9820",
  "CM9821", "CM9501", "CM9551", "CM9640", "CM8726", "CM9676", "CM9368",
  "CM9471", "CM9494", "CM9512", "CM9709", "CM9735", "CM9956", "CM9974",
  "CM9882", "CM9892", "P-195", "P-341", "P-498", "P-536", "P-549", "P-561",
  "P-630", "P-633", "P-637", "P-641", "P-671", "P-675", "M96-181", "M03-669",
  "M05-416", "M22-450", "M23-48", "M23-49", "M23-66", "M23-71", "M23-72",
  "M23-73", "M23-74", "M23-96", "M23-112", "M23-128", "M23-129", "M23-135",
  "M23-153", "M23-155", "M23-161", "M23-162", "M23-163", "M23-164", "M23-166",
  "M23-167", "M23-177", "M23-200", "M23-216", "M23-217", "M23-226", "M23-231",
  "M23-243", "M23-244", "M23-245", "M23-246", "M23-247", "M23-256", "M23-280",
  "M23-288", "M23-324", "M23-326", "M23-335", "M23-364", "M23-396", "M23-401",
  "M23-428", "M23-429", "M23-430", "M23-438", "M23-454", "M23-468", "A9", "B1",
  "H2482", "H2285", "H2489", "H2495", "H2417", "H2504", "H2528", "M21-411",
  "M22-32", "M22-35", "M22-155", "M22-239", "M22-339", "M22-366", "M22-417",
  "M22-439", "M22-446", "M22-458", "M22-10", "M22-19", "M22-37", "M22-39",
  "M22-47", "M22-49", "M22-129", "M22-146", "M22-170", "M22-172", "M22-174",
  "M22-188", "M22-213", "M22-226", "M22-227", "M22-228", "M22-287", "M22-293",
  "M22-303", "M22-311", "M22-316", "M22-324", "M22-333", "M22-354", "M22-380",
  "M22-381", "M22-387", "M22-443", "M22-500", "M22-507", "M22-513", "M22-45"
)

muestras_negrita <- samples$display_name[samples$BioinfoName %in% bioinfo_negrita]
orden_eje <- levels(Q_long$sample_name)
colores_eje <- ifelse(orden_eje %in% muestras_negrita, "red", "black")

cluster_plot <- ggplot(Q_long, aes(x = sample_name, y = probabilidad, fill = cluster)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = mis_colores) +
  labs(x = "Individuo", y = "Porcentaje", fill = "Cluster") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 3,
                                   colour = colores_eje))

cluster_plot

ggsave('C:/Users/Valeria/Desktop/resultados_tfm/Figuras proyecto/clusters.pdf', plot = cluster_plot, width = 20, height = 12, units = "in", dpi = 1200)