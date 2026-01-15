stroke <- read.csv("data/healthcare-dataset-stroke-data.csv")
head(stroke)
names(stroke)
str(stroke)
summary(stroke)
stroke$bmi[stroke$bmi == "N/A"] <- NA
str(stroke$bmi)
stroke$bmi <- as.numeric(stroke$bmi)
str(stroke$bmi)
hist(stroke$bmi)
summary(stroke$bmi)
stroke_clean = stroke[
  !is.na(stroke$bmi) & stroke$bmi >= 15 & stroke$bmi <= 60,
]
str(stroke_clean)
hist(stroke_clean$bmi)
summary(stroke_clean$bmi)

# BMI SINIFLARINI OLUSTURUYORUM
stroke_clean$bmi_group <- cut(
  stroke_clean$bmi,
  breaks = c(15, 24.9, 29.9, 60),
  labels = c("Normal", "Ortalama", "Obez"),
  right = TRUE
)

# Stroke Hesaplama

library(dplyr)


stroke_summary <- stroke_clean %>%
  group_by(bmi_group) %>%
  summarise(
    total = n(),
    stroke_count = sum(stroke),
    stroke_percent = round((stroke_count / total) * 100, 2)
  )

stroke_summary

# RDS formatında veri kaydet
saveRDS(stroke_clean, "stroke_clean.rds")

# Veya CSV olarak kaydet
write.csv(stroke_clean, "stroke_clean.csv", row.names = FALSE)

stroke_clean <- readRDS("stroke_clean.rds")


library(dplyr)

# Yaş gruplarını oluşturuyoruz

stroke_clean$age_group <- cut(
  stroke_clean$age,
  breaks = c(0, 39, 59, 79, 120),
  labels = c("0-39", "40-59", "60-79", "80+"),
  right = TRUE
)

# Yaş grubuna göre stroke oranı

age_summary <- stroke_clean %>%
  group_by(age_group) %>%
  summarise(
    total = n(),
    stroke_count = sum(stroke),
    stroke_percent = round((stroke_count / total) * 100, 2)
  )

age_summary


hypertension_summary <- stroke_clean %>%
  group_by(hypertension) %>%
  summarise(
    total = n(),
    stroke_count = sum(stroke),
    stroke_percent = round((stroke_count / total) * 100, 2)
  )

hypertension_summary

bmi_summary <- stroke_clean %>%
  group_by(bmi_group) %>%
  summarise(
    total = n(),
    stroke_count = sum(stroke),
    stroke_percent = round((stroke_count / total) * 100, 2)
    
  )

bmi_summary

bmi_ht_summary <- stroke_clean %>%
  group_by(bmi_group, hypertension) %>%
  summarise(
    total = n(),
    stroke_count = sum(stroke),
    stroke_percent = round((stroke_count / total) * 100, 2),
    .groups = "drop"
  )

bmi_ht_summary

model <- glm(
  stroke ~ age + hypertension + heart_disease + bmi,
  data = stroke_clean,
  family = binomial
)

summary(model)

set.seed(42)

n <- nrow(stroke_clean)

train_index <- sample(seq_len(n), size = 0.7 * n)

train_data <- stroke_clean[train_index, ]
test_data  <- stroke_clean[-train_index, ]

nrow(train_data)
nrow(test_data)

prop.table(table(train_data$stroke))
prop.table(table(test_data$stroke))


model_ml <- glm(
  stroke ~ age + hypertension + heart_disease + bmi,
  data = train_data,
  family = binomial
)

summary(model_ml)

test_probs <- predict(
  model_ml,
  newdata = test_data,
  type = "response"
)

head(test_probs)

test_pred <- ifelse(test_probs >= 0.5, 1, 0)

table(
  Gercek = test_data$stroke,
  Tahmin = test_pred
)

test_pred_03 <- ifelse(test_probs >= 0.3, 1, 0)

table(
  Gercek = test_data$stroke,
  Tahmin = test_pred_03
)

test_pred_02 <- ifelse(test_probs >= 0.2, 1, 0)

table(
  Gercek = test_data$stroke,
  Tahmin = test_pred_02
)

model_weighted <- glm(
  stroke ~ age + hypertension + heart_disease,
  data = train_data,
  family = binomial,
  weights = ifelse(train_data$stroke == 1, 10, 1)
)

summary(model_weighted)

test_probs_w <- predict(
  model_weighted,
  newdata = test_data,
  type = "response"
)

test_pred_w_03 <- ifelse(test_probs_w >= 0.3, 1, 0)

table(
  Gercek = test_data$stroke,
  Tahmin = test_pred_w_03
)

install.packages("pROC")

library(pROC)

# Test olasılıkları (weighted model)
test_probs_w <- predict(
  model_weighted,
  newdata = test_data,
  type = "response"
)

# ROC objesi
roc_obj <- roc(
  response = test_data$stroke,
  predictor = test_probs_w
)

# AUC değeri
auc(roc_obj)

library(pROC)

roc_obj <- roc(
  response = test_data$stroke,
  predictor = test_probs_w
)

plot(
  roc_obj,
  col = "purple",
  lwd = 3,
  main = "ROC Curve – Weighted Logistic Regression"
)
abline(a = 0, b = 1, lty = 2, col = "gray")

text(
  0.6, 0.2,
  labels = paste("AUC =", round(auc(roc_obj), 3)),
  cex = 1.2
)

# ============================================
# PROFESYONEL GORSELLESTIRMELER
# ============================================

library(ggplot2)
library(dplyr)

# Genel tema ayarlari
tema <- theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray30"),
    axis.title = element_text(face = "bold", size = 11),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

# ============================================
# 1. BMI DAGILIMI VE INME DURUMU
# ============================================

ggplot(stroke_clean, aes(x = bmi, fill = as.factor(stroke))) +
  geom_histogram(bins = 35, alpha = 0.8, position = "identity") +
  scale_fill_manual(
    values = c("0" = "#3498db", "1" = "#e74c3c"),
    labels = c("Inme Yok", "Inme Var"),
    name = "Durum"
  ) +
  labs(
    title = "BMI Dagilimi ve Inme Durumu",
    subtitle = "Inme geciren hastalarin BMI degerleri daha yuksek",
    x = "Vucut Kitle Indeksi (BMI)",
    y = "Hasta Sayisi"
  ) +
  tema

# ============================================
# 2. YAS VE INME RISKI ILISKISI
# ============================================

ggplot(stroke_clean, aes(x = age, y = stroke)) +
  geom_point(alpha = 0.15, color = "#3498db", size = 2) +
  geom_smooth(
    method = "glm",
    method.args = list(family = "binomial"),
    color = "#e74c3c",
    fill = "#e74c3c",
    alpha = 0.2,
    size = 1.5
  ) +
  labs(
    title = "Yas ve Inme Riski Iliskisi",
    subtitle = "Yas arttikca inme riski ustel olarak artiyor",
    x = "Yas",
    y = "Inme Olasiligi"
  ) +
  tema

# ============================================
# 3. YAS GRUPLARINA GORE INME ORANLARI
# ============================================

age_plot_data <- stroke_clean %>%
  group_by(age_group) %>%
  summarise(
    stroke_rate = mean(stroke) * 100,
    n = n()
  )

ggplot(age_plot_data, aes(x = age_group, y = stroke_rate, fill = stroke_rate)) +
  geom_col(width = 0.7, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%\n(n=", n, ")")),
    vjust = -0.5,
    fontface = "bold",
    size = 4
  ) +
  scale_fill_gradient(
    low = "#3498db",
    high = "#e74c3c",
    name = "Inme Orani (%)"
  ) +
  labs(
    title = "Yas Gruplarina Gore Inme Oranlari",
    subtitle = "80+ yas grubunda risk dramatik sekilde artiyor",
    x = "Yas Grubu",
    y = "Inme Orani (%)"
  ) +
  tema +
  ylim(0, max(age_plot_data$stroke_rate) * 1.15)

# ============================================
# 4. BMI GRUPLARINA GORE INME ORANLARI
# ============================================

bmi_plot_data <- stroke_clean %>%
  group_by(bmi_group) %>%
  summarise(
    stroke_rate = mean(stroke) * 100,
    n = n()
  )

ggplot(bmi_plot_data, aes(x = bmi_group, y = stroke_rate, fill = bmi_group)) +
  geom_col(width = 0.7, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%\n(n=", n, ")")),
    vjust = -0.5,
    fontface = "bold",
    size = 4
  ) +
  scale_fill_manual(
    values = c("#2ecc71", "#f39c12", "#e74c3c"),
    name = "BMI Kategorisi"
  ) +
  labs(
    title = "BMI Kategorilerine Gore Inme Oranlari",
    subtitle = "Obez bireylerde risk belirgin sekilde yuksek",
    x = "BMI Kategorisi",
    y = "Inme Orani (%)"
  ) +
  tema +
  theme(legend.position = "none") +
  ylim(0, max(bmi_plot_data$stroke_rate) * 1.15)

# ============================================
# 5. HIPERTANSIYON VE INME
# ============================================

ht_plot_data <- stroke_clean %>%
  group_by(hypertension) %>%
  summarise(
    stroke_rate = mean(stroke) * 100,
    n = n()
  ) %>%
  mutate(ht_label = ifelse(hypertension == 1, "Hipertansiyon Var", "Hipertansiyon Yok"))

ggplot(ht_plot_data, aes(x = ht_label, y = stroke_rate, fill = ht_label)) +
  geom_col(width = 0.6, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%\n(n=", n, ")")),
    vjust = -0.5,
    fontface = "bold",
    size = 5
  ) +
  scale_fill_manual(
    values = c("Hipertansiyon Yok" = "#3498db", "Hipertansiyon Var" = "#e74c3c")
  ) +
  labs(
    title = "Hipertansiyona Gore Inme Oranlari",
    subtitle = "Hipertansiyon riski yaklasik 2.5 kat artiriyor",
    x = "",
    y = "Inme Orani (%)"
  ) +
  tema +
  theme(legend.position = "none") +
  ylim(0, max(ht_plot_data$stroke_rate) * 1.15)

# ============================================
# 6. BMI VE HIPERTANSIYON KOMBINASYONU
# ============================================

bmi_ht_plot <- stroke_clean %>%
  group_by(bmi_group, hypertension) %>%
  summarise(
    stroke_rate = mean(stroke) * 100,
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(ht_label = ifelse(hypertension == 1, "HT Var", "HT Yok"))

ggplot(bmi_ht_plot, aes(x = bmi_group, y = ht_label, fill = stroke_rate)) +
  geom_tile(color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%")),
    color = "white",
    fontface = "bold",
    size = 5
  ) +
  scale_fill_gradient2(
    low = "#3498db",
    mid = "#f39c12",
    high = "#e74c3c",
    midpoint = median(bmi_ht_plot$stroke_rate),
    name = "Inme Orani (%)"
  ) +
  labs(
    title = "BMI ve Hipertansiyonun Birlikte Etkisi",
    subtitle = "En yuksek risk: Obez + Hipertansiyon kombinasyonu",
    x = "BMI Kategorisi",
    y = "Hipertansiyon Durumu"
  ) +
  tema

# ============================================
# 7. KALP HASTALIGI VE INME
# ============================================

heart_plot_data <- stroke_clean %>%
  group_by(heart_disease) %>%
  summarise(
    stroke_rate = mean(stroke) * 100,
    n = n()
  ) %>%
  mutate(hd_label = ifelse(heart_disease == 1, "Kalp Hastaligi Var", "Kalp Hastaligi Yok"))

ggplot(heart_plot_data, aes(x = hd_label, y = stroke_rate, fill = hd_label)) +
  geom_col(width = 0.6, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%\n(n=", n, ")")),
    vjust = -0.5,
    fontface = "bold",
    size = 5
  ) +
  scale_fill_manual(
    values = c("Kalp Hastaligi Yok" = "#2ecc71", "Kalp Hastaligi Var" = "#e74c3c")
  ) +
  labs(
    title = "Kalp Hastaligi Durumuna Gore Inme Oranlari",
    subtitle = "Kalp hastaligi onemli bir risk faktoru",
    x = "",
    y = "Inme Orani (%)"
  ) +
  tema +
  theme(legend.position = "none") +
  ylim(0, max(heart_plot_data$stroke_rate) * 1.15)

# ============================================
# 8. RISK FAKTORLERI KARSILASTIRMASI
# ============================================

risk_comparison <- data.frame(
  factor = c("Hipertansiyon", "Kalp Hastaligi", "Obezite", "Yaslilik (60+)"),
  stroke_rate = c(
    mean(stroke_clean$stroke[stroke_clean$hypertension == 1]) * 100,
    mean(stroke_clean$stroke[stroke_clean$heart_disease == 1]) * 100,
    mean(stroke_clean$stroke[stroke_clean$bmi_group == "Obez"]) * 100,
    mean(stroke_clean$stroke[stroke_clean$age >= 60]) * 100
  )
) %>%
  arrange(desc(stroke_rate))

ggplot(risk_comparison, aes(x = reorder(factor, stroke_rate), y = stroke_rate, fill = factor)) +
  geom_col(width = 0.7, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(stroke_rate, 1), "%")),
    hjust = -0.2,
    fontface = "bold",
    size = 5
  ) +
  scale_fill_brewer(palette = "Set1") +
  coord_flip() +
  labs(
    title = "Risk Faktorlerine Gore Inme Oranlari",
    subtitle = "En etkili risk faktorleri",
    x = "",
    y = "Inme Orani (%)"
  ) +
  tema +
  theme(legend.position = "none")

cat("\n✓ Tum gorsellestirmeler olusturuldu!\n")y



