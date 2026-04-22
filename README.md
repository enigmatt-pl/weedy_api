# Weedy API

Weedy API is a Ruby on Rails backend service designed to automate and manage the profiling of medical and retail dispensaries. It works in tandem with the Weedy frontend application and leverages **Google Gemini 2.0** to analyze dispensary data and images to generate professional profiles, verified descriptions, and market-accurate potential ratings.

## Requirements

* **Ruby 3.4.4**
* **Rails 7.1.x**
* **Postgres 16+** (Uses **UUID v7** with **SQL Schema format**)
* **Redis** (for Sidekiq and caching)
* **Cloudinary** (for persistent media storage)
* **Gemini API** (for AI generation)

## Getting Started

1. **Install Dependencies**
   Ensure you have Ruby 3.4.4 and bundler installed, then run:
   ```bash
   bundle install
   ```

2. **Database Setup**
   The application uses PostgreSQL with sequential UUIDs. Run:
   ```bash
   bin/rails db:prepare
   ```

3. **Environment Setup**
   Copy the `.env.example` file and set your credentials:
   ```bash
   cp .env.example .env
   ```
   Required production/cloud variables:
   - `GEMINI_API_KEY`: For AI generation.
   - `CLOUDINARY_URL`: For persistent image storage.
   - `APP_HOST`: (Optional) Custom domain for media links.
   - `RENDER_EXTERNAL_HOSTNAME`: Auto-set by Render.

4. **Running the Services**
   ```bash
   bin/dev
   ```

## Media Storage & Security

Weedy implements a **Masked Storage System** via Active Storage:
- **Proxy URLs**: All internal storage paths are hidden behind `/uploads/:signed_id/:filename`.
- **Persistent Cloud**: Integrated with **Cloudinary** for stability across deployments.
- **Stable Signatures**: Frontend can safely cache image URLs without expiration issues.

## Deployment

The project is pre-configured for **Render** via `render.yaml`:
- **Web Service**: Rails API.
- **Worker Service**: Sidekiq Background Processing.
- **Managed DB/Redis**: Centralized secret management via `envVarGroups`.

## Verification & Quality Assurance

We maintain high code quality standards. Run the full verification pipeline (Tests, Linting, Security Audit) with one command:

```bash
./bin/verify
```

This script executes:
- **Bundler Audit**: Checks for security vulnerabilities in dependencies.
- **RuboCop**: Ensures idiomatic Ruby and Rails style guides.
- **RSpec**: Runs the full test suite.

## Dispensary Profiling API

The Weedy backend supports an AI-powered dispensary profiling flow.

### Endpoints
- `GET /api/v1/dispensaries` - Retrieve all dispensaries for the authenticated user.
- `POST /api/v1/dispensaries/generate` - Upload dispensary name/address and images to initiate asynchronous profiling (Sidekiq) via **Gemini 2.0**.
- `POST /api/v1/dispensaries` - Create a new dispensary record.
- `PUT /api/v1/dispensaries/:id` - Update an existing dispensary profile.
- `DELETE /api/v1/dispensaries/:id` - Delete a dispensary record.

### Analytics & Health
- `POST /api/v1/health/ping` - Obfuscated endpoint for page view tracking.
- `POST /api/v1/health/pulse` - Obfuscated endpoint for engagement tracking.

### Setup
Ensure you have configured your `.env` file with `GEMINI_API_KEY` before starting the server.
