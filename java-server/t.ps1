# t.ps1 - Tail logs for Cloud Run service 'learning-lab-server'
gcloud beta logging tail `
  'resource.type="cloud_run_revision" AND resource.labels.service_name="learning-lab-server"' `
  --project="social-learning-32741" `
  --format="table(timestamp,severity,textPayload)"
