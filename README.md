# Weedy API

Weedy API is a Ruby on Rails backend service designed to manage a network of medical and retail dispensaries. It works in tandem with the Weedy frontend application to provide a professional platform for shop owners to list their points of presence, manage their profiles, and publish them to a wider network.

## Requirements

* **Ruby 3.4.4**
* **Rails 7.1.x**
* **Postgres 16+** (Uses **UUID v7** with **SQL Schema format**)
* **Redis** (for Sidekiq and caching)
* **Cloudinary** (for persistent media storage)

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
   - `CLOUDINARY_URL`: For persistent image storage.
   - `ANALYTICS_USER_ID` & `ANALYTICS_SECRET_KEY`: For tracking endpoints.

4. **Running the Services**
   ```bash
   bin/dev
   ```

## Media Storage & Security

Weedy implements a **Masked Storage System** via Active Storage:
- **Proxy URLs**: All internal storage paths are hidden behind `/uploads/:signed_id/:filename`.
- **Persistent Cloud**: Integrated with **Cloudinary** for stability across deployments.

## Deployment

The project is pre-configured for **Render** via `render.yaml`.

## Verification & Quality Assurance

We maintain high code quality standards. Run the full verification pipeline with:

```bash
./bin/verify
```

## Dispensary API

### Endpoints
- `GET /api/v1/dispensaries` - Retrieve all dispensaries for the authenticated user.
- `POST /api/v1/dispensaries` - Create a new dispensary record with images.
- `PUT /api/v1/dispensaries/:id` - Update an existing dispensary profile.
- `DELETE /api/v1/dispensaries/:id` - Delete a dispensary record.

### Analytics & Health
- `POST /api/v1/health/ping` - Obfuscated endpoint for page view tracking.
- `POST /api/v1/health/pulse` - Obfuscated endpoint for engagement tracking.
