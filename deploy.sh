#!/bin/bash
# CV Analyzer Workshop — Cloud Run Deploy Scripti

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "Hata: Proje ID gerekli!"
  echo "Kullanim: bash deploy.sh PROJECT_ID"
  exit 1
fi

SVC=cv-analyzer
REGION=us-central1
REPO=cloud-run-source-deploy
IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SVC"

echo "Servis: $SVC"
echo "Bolge: $REGION"
echo "Proje: $PROJECT_ID"

# Artifact Registry deposu yoksa olustur
echo "Artifact Registry deposu kontrol ediliyor..."
gcloud artifacts repositories describe $REPO \
  --location=$REGION \
  --project=$PROJECT_ID > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Artifact Registry deposu olusturuluyor..."
  gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --project=$PROJECT_ID
fi

echo "Cloud Run'a deploy ediliyor..."
gcloud run deploy $SVC \
  --source . \
  --region $REGION \
  --project $PROJECT_ID \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --timeout 120 \
  --set-env-vars GOOGLE_CLOUD_PROJECT=$PROJECT_ID

echo ""
echo "Deploy tamamlandi!"
echo "Servis URL'si:"
gcloud run services describe $SVC \
  --region $REGION \
  --project $PROJECT_ID \
  --format="value(status.url)"
