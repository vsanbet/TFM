library(ggplot2)
library(dplyr)

# Media por K
mean_cv <- doc %>%
  group_by(K) %>%
  summarise(mean_CV = mean(CV), .groups = "drop") %>%
  arrange(K) %>%
  mutate(
    slope      = (mean_CV - lag(mean_CV)) / (K - lag(K)),
    slope_label = ifelse(!is.na(slope), sprintf("%.4f", slope), NA),
    K_mid      = K - 0.5,
    CV_mid     = (mean_CV + lag(mean_CV)) / 2
  )

# Gráfica
ggplot() +
  geom_jitter(data = doc,
              aes(x = K, y = CV),
              width = 0.15, size = 1.8, alpha = 0.5,
              color = "#378ADD") +
  geom_line(data = mean_cv,
            aes(x = K, y = mean_CV),
            color = "#D85A30", linewidth = 0.8) +
  geom_point(data = mean_cv,
             aes(x = K, y = mean_CV),
             color = "#D85A30", size = 3) +
  geom_label(data = filter(mean_cv, !is.na(slope)),
             aes(x = K_mid, y = CV_mid, label = slope_label),
             size = 3, color = "#3B6D11", fill = "white",
             label.size = 0.3) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    x = "K",
    y = "CV error",
    title = "ADMIXTURE — Cross-validation error por K",
    subtitle = "Puntos = runs individuales · Línea = media · Etiquetas = pendiente entre K consecutivos"
  ) +
  theme_classic(base_size = 13) +
  theme(
    plot.title    = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray50")
  )