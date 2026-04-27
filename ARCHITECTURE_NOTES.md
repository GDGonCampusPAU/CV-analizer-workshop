# CV Analyzer Workshop — Architecture Notes
# (Agent Handoff Reference)

## Project Overview

A Google Cloud Shell workshop tutorial that teaches participants to build a CV analysis web app
using Vertex AI Gemini 2.5 Flash and deploy it to Cloud Run.

---

## Critical Architecture Decisions

### 1. PDF Delivery to Gemini: Part.from_data() — NOT Part.from_uri()

Reference project (YouTube Summarizer) used `Part.from_uri()` with a YouTube URL.
This project uses `Part.from_data()` with raw PDF bytes because:
- PDFs are user-uploaded files, not public URIs
- No Cloud Storage intermediate step needed for this workshop scope
- Keeps the tutorial simple and avoids additional IAM/Storage complexity

```python
pdf_part = Part.from_data(data=pdf_bytes, mime_type="application/pdf")
```

Gemini 2.5 Flash supports up to 20MB inline data. Workshop CVs are always well under this.

### 2. Prompt Injection Defense: system_instruction Parameter

The most important security decision. The system instruction is passed at MODEL INITIALIZATION,
not as a user message. This means it cannot be overridden by content in the PDF or job description.

```python
model = GenerativeModel(
    "gemini-2.5-flash",
    system_instruction=SYSTEM_INSTRUCTION  # Not overrideable by user input
)
```

The system instruction explicitly:
- Locks the model to CV analysis only
- Instructs the model to IGNORE any instructions found inside CV or job description
- Defines the exact output format (structured, no emojis, no emotions)
- Handles graceful rejection for non-CV documents

### 3. PDF Validation: Magic Bytes Only (No PyPDF2)

Rather than adding a heavy dependency (PyPDF2), we validate the PDF magic bytes:
```python
def validate_pdf(file_bytes: bytes) -> bool:
    return file_bytes[:4] == b"%PDF"
```
This is sufficient for workshop use. Malformed PDFs that pass this check will be rejected
by Gemini with an error that the Flask app catches and returns as a user-friendly message.

### 4. Service Name: cv-analyzer

Cloud Run service name: `cv-analyzer`
Region: `us-central1`
Memory: `512Mi` (more than YouTube summarizer's default — PDF processing needs headroom)
Timeout: `120s` (Gemini PDF analysis can take 15-30s; gunicorn also configured with --timeout 120)

### 5. Flask MAX_CONTENT_LENGTH: 10MB

```python
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
```
This is set server-side. Cloud Run's request body limit is 32MB, but we restrict to 10MB
to keep Gemini API calls fast and credit consumption low.

---

## IAM Roles Required

| Role | Service Account | Reason |
|------|----------------|--------|
| roles/aiplatform.user | Compute SA | Call Gemini API via Vertex AI |
| roles/storage.admin | Compute SA | Cloud Build source upload |
| roles/logging.logWriter | Compute SA | Cloud Run application logs |
| roles/artifactregistry.writer | Cloud Build SA | Push Docker image |
| roles/run.admin | Cloud Build SA | Deploy Cloud Run service |
| roles/iam.serviceAccountUser | Cloud Build SA | Act as Compute SA |

---

## GitHub Repository Setup (REQUIRED before tutorial works)

1. Create a new GitHub repo named `cv-analyzer-workshop`
2. Push this entire directory to the `main` branch
3. Replace `YOUR_GITHUB_USERNAME` in:
   - `README.md` — Cloud Shell badge URL and clone commands
   - `tutorial.md` — Step 5 (Vertex AI Izin Kurulumu) — `export REPO=` line and curl command

The tutorial references scripts via raw.githubusercontent.com. They MUST be publicly accessible.

---

## Output Format Contract

The system instruction defines this exact structure that Gemini MUST produce:

```
---
CV ANALYSIS REPORT
---

CANDIDATE PROFILE SUMMARY
[2-3 sentence summary]

STRENGTHS
- [point]

AREAS FOR IMPROVEMENT
- [point]

RECOMMENDED ADDITIONS FOR THIS ROLE
- [point]

OVERALL ASSESSMENT
[2-3 sentence assessment]
---
```

No emojis. No emotions. No markdown formatting. Plain text only.
Report language = job description language (auto-detected by Gemini).

---

## Files and Their Roles

| File | Role |
|------|------|
| cv-analyzer-app/app.py | Flask app, Vertex AI integration, validation, security |
| cv-analyzer-app/requirements.txt | Flask, google-cloud-aiplatform, vertexai, gunicorn |
| cv-analyzer-app/Dockerfile | python:3.11-slim, gunicorn with --timeout 120 |
| cv-analyzer-app/.gcloudignore | Excludes __pycache__, .env, *.pdf |
| cv-analyzer-app/templates/index.html | Dark-mode GitHub-style UI, PDF drop zone, char counter |
| setup-iam.sh | IAM permissions for Compute SA + Cloud Build SA |
| deploy.sh | Creates Artifact Registry repo + deploys to Cloud Run |
| tutorial.md | Cloud Shell interactive tutorial (Turkish, 16 steps) |
| README.md | GitHub landing page + Cloud Shell badge |

---

## Known Limitations (Workshop Scope)

- PDFs are held in memory (not persisted). No logging of CV content. Privacy-friendly.
- No authentication on the Cloud Run service (--allow-unauthenticated). Workshop demo only.
- No rate limiting. For production, add Cloud Armor or request quotas.
- Gemini may occasionally produce output that deviates from the strict format. The system
  instruction significantly reduces this but does not eliminate it entirely.
