# LifeLog — Frontend

**Clark University · MSCS3999 Capstone · Team 7**

LifeLog is a cross-platform mobile application built with Flutter that serves as an all-in-one personal life tracking dashboard. Instead of juggling multiple apps, users can manage tasks, log expenses, track their mood, and write gratitude entries — all in one place, with AI-driven insights to help them understand their patterns and make better daily decisions.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Development Roadmap](#development-roadmap)
- [Team](#team)

---

## Project Overview

Most productivity and wellness tools only address one area of daily life. LifeLog brings together four key domains — **productivity**, **financial awareness**, **emotional well-being**, and **mindfulness** — into a single, coherent mobile experience. AI-generated feedback and data visualizations give users actionable insights rather than just raw logs.

**Project Duration:** February 3 – April 26, 2026  
**Methodology:** Agile (2-week sprints)  
**Backend Repo:** [Capstone_Backend](https://github.com/naween321/Capstone_Backend)

---

## Features

### To-Do List
- Full CRUD for tasks with status management (Backlog, In Progress, Completed)
- File and image attachments
- Push notifications for task reminders
- AI-based task scheduling suggestions

### Expense Tracker
- Log income and expenses manually or by uploading a receipt image (parsed automatically)
- Category-wise summaries and monthly logs
- Set daily spending limits
- View savings and investments via charts
- End-of-month push notification summary

### Mood Logger
- Daily mood entry with full CRUD
- LLM-powered supportive/encouraging AI responses
- Historical mood trend visualizations

### Gratitude Journal
- Daily gratitude entries with varying AI-generated prompts
- Streaks and progress tracking
- File and image uploads
- Date-based organisation and filtering

### Dashboard
- Overview of pending tasks, recent expenses, mood summaries, and latest gratitude entries
- Charts and summary cards for at-a-glance data visualisation

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile UI | Flutter (Dart) |
| State Management | TBD (sprint 3+) |
| Push Notifications | Google Cloud Messaging (FCM) |
| Backend API | Python Django REST Framework |
| Database | PostgreSQL + Redis |
| Cloud | AWS (EC2, S3, SES) |
| Containerisation | Docker |
| Infrastructure as Code | Terraform |
| CI/CD | GitHub Actions |
| Reverse Proxy | NGINX |
| Version Control | Git / GitHub |
| Project Management | Notion |

---

## Architecture

LifeLog uses a **Frontend–Backend** architecture:

- The **Flutter mobile app** handles all UI, local state, and API communication.
- A **Django REST Framework** backend exposes versioned JSON APIs consumed by the app.
- Backend is containerised with Docker and deployed to an **AWS EC2** instance, with static/media assets stored in **S3**.
- **Redis** caches frequent API calls (TTL: 20 minutes) to keep response times under 500 ms.
- **GitHub Actions** runs the full test suite on every push; a build cannot be deployed if any test fails.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.6.0`)
- Android Studio / Xcode (for emulator or device testing)
- A running instance of the [LifeLog backend](https://github.com/naween321/Capstone_Backend) (or a `.env` pointing to the dev server)

### Installation

```bash
# Clone the repository
git clone https://github.com/Watson-John/Capstone_Frontend.git
cd Capstone_Frontend/lifelog

# Install Flutter dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Running Tests

```bash
flutter test
```

---

## Project Structure

```
lifelog/
├── lib/
│   └── main.dart          # App entry point
├── android/               # Android platform files
├── ios/                   # iOS platform files
├── macos/                 # macOS platform files
├── web/                   # Web platform files
├── linux/                 # Linux platform files
├── windows/               # Windows platform files
├── pubspec.yaml           # Dependencies and Flutter config
└── analysis_options.yaml  # Lint rules
```

> Feature modules (expense tracker, mood logger, gratitude journal, to-do list, dashboard) will be added under `lib/` in upcoming sprints following a feature-first folder structure.

---

## Development Roadmap

| Sprint | Dates | Focus |
|--------|-------|-------|
| 1 | Feb 3 – Feb 14 | Requirements, system design, DB schema, wireframes |
| 2 | Feb 10 – Feb 21 | Environment setup (AWS, Docker, Terraform, CI/CD, Auth) |
| 3 | Feb 17 – Mar 1 | Expense Tracker module (API, DB, Flutter UI, tests) |
| 4 | Mar 2 – Mar 15 | Mood Logger + Gratitude Journal modules |
| 5 | Mar 16 – Mar 29 | To-Do List + Notifications integration |
| 6 | Mar 30 – Apr 12 | Dashboard, AI insights, full module integration |
| 7 | Apr 13 – Apr 20 | System testing, bug fixing, performance optimisation |
| 8 | Apr 21 – Apr 26 | Final deployment, documentation, demo preparation |

---

## Team

| Name | Role |
|------|------|
| John Watson | Project Manager / Mobile App Developer |
| Nabin Paudyal | Backend Developer / DevOps |
| Sneha Khatiwada | UI/UX Designer / QA / Frontend Developer |
| Prof. Sufyan Almajali | Supervisor / Advisor |

---

*Clark University · Spring 2026*
