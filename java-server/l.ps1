# l.ps1 - Show last 50 logs for Cloud Run service 'learning-lab-server'
gcloud logging read `
  'resource.type="cloud_run_revision" AND resource.labels.service_name="learning-lab-server"' `
  --project="social-learning-32741" `
  --limit=50 `
  --order=desc `
  --format="text"
