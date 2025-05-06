# r.ps1 – Build & deploy Spring Boot app to Cloud Run

Write-Host "▶ Building JAR..."
.\gradlew.bat clean build

Write-Host "▶ Submitting build to Google Cloud..."
gcloud builds submit --tag gcr.io/social-learning-32741/learning-lab-server

Write-Host "▶ Deploying to Cloud Run..."
gcloud run deploy learning-lab-server `
  --image gcr.io/social-learning-32741/learning-lab-server `
  --platform managed `
  --region us-central1 `
  --allow-unauthenticated

Write-Host "✅ Deployment complete."
