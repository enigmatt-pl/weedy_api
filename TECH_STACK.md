# Weedy API — Tech Stack

This document outlines the current technical stack and key architectural decisions for the **Weedy API**.

## 🚀 Core Technologies
- **Ruby 3.4.4**: Latest stable Ruby version.
- **Rails 7.1.x (API Mode)**: Lightweight, performance-oriented backend framework.
- **PostgreSQL 16+**: Robust relational database using **UUID v7** for all keys.
- **Redis (Managed)**: In-memory data store for Sidekiq and caching.

## 🔑 Authentication & Security
- **Devise**: Standard Ruby on Rails authentication solution.
- **JWT (json-web-token)**: Stateless authentication for mobile and frontend consumers.
- **Active Record Encryption**: Native Rails encryption (GCM) used for sensitive data.

## 📦 Multimedia & Storage
- **Cloudinary**: Persistent cloud storage for product images and user avatars.
- **Masked Storage System**: Custom implementation hiding Active Storage paths behind `/uploads/:signed_id/:filename`.
- **Proxy Serving**: All media is proxied via Rails to ensure URL stability and bypass CORS/Expiration issues.
- **Image Processing**: Using `image_processing` gem for visual standardizations.

## 🤖 AI & External Integrations
- **Google Gemini 2.0 Pro/Flash**: Used for:
  - Computer Vision (Analyzing dispensary images and interiors).
  - Web-Grounded Analysis (Real-time data verification).
  - Professional Copywriting (Verified descriptions and SEO titles).
  - Mega-Prompt Architecture: Consolidated reasoning, analysis, and generation in a single high-fidelity pass.

## ⚙️ Background Processing
- **Sidekiq**: Asynchronous task execution.
- **Sidekiq Workers**: Using `Sidekiq::Worker` instead of ActiveJob for better performance and direct control.
- **Connection Pool**: Optimized database and redis connection management.

## 🧪 Testing & Quality Assurance
- **RSpec-Rails**: Behavior-Driven Development framework.
- **FactoryBot**: For concise and reusable test data generation.
- **RuboCop**: Enforces idiomatic Ruby/Rails style guides.
- **Bundler Audit**: Scans dependencies for known vulnerabilities.
- **WebMock**: Ensures no real network calls are made during tests.
- **Annotate**: Automatically documents model schemas, serializers, and routes as comments in source files for better developer visibility.
- **bin/verify**: A unified executable for running the full QA pipeline.

## 📄 Architectural Patterns
- **Service Objects**: Complex business logic (Dispensary profiling, AI parsing) is encapsulated in dedicated service classes (`app/services`).
- **UUID v7 Primary Keys**: All records use sortable UUIDs, removing the need for `id` vs `created_at` sorting hacks in many cases.
- **RESTful Design**: Standardized API endpoints following `api/v1` versioning.
