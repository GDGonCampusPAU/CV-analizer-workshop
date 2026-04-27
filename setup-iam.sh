#!/bin/bash
# CV Analyzer Workshop — IAM Izin Kurulum Scripti

set -e

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "Hata: Proje ID gerekli!"
  echo "Kullanim: bash setup-iam.sh PROJECT_ID"
  exit 1
fi

echo "Proje: $PROJECT_ID icin izinler veriliyor..."

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "Proje numarasi: $PROJECT_NUMBER"

COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

echo "Compute service account izinleri veriliyor: $COMPUTE_SA"

# Vertex AI erişimi
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/aiplatform.user" --quiet

# Cloud Build source deploy için storage erişimi
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/storage.admin" --quiet

# Cloud Run logları
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/logging.logWriter" --quiet

# Yeni GCP projelerinde gcloud run deploy --source, image push için
# Compute SA'yı kullanır — bu nedenle artifactregistry.writer buraya da verilmeli
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/artifactregistry.writer" --quiet

echo "Cloud Build service account izinleri veriliyor: $CLOUDBUILD_SA"

# Eski proje davranışı veya doğrudan Cloud Build trigger için de gerekli
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/artifactregistry.writer" --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/run.admin" --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser" --quiet

echo "Tum izinler verildi. IAM propagation icin 30 saniye bekleniyor..."
sleep 30
echo "Hazir! Deploy adimina gecebilirsiniz."
