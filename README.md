# Hotel Management App — Full Stack (Backend + Flutter)

This archive contains both halves of the hybrid offline/online hotel
management system:

```
hotel-management-app/
├── hotel-backend/   Node.js + Express + MySQL API
└── hotel_app/       Flutter frontend (offline-first, syncs to hotel-backend)
```

## 📖 Key Documentation Guides

- **[Getting Started & Operations Guide](file:///d:/Z-React/POS-Flutter/hotel-management-app/Getting_Started_Guide.md)**: Complete step-by-step setup from zero to running the app, initial admin configuration, room setup, staff roles, and daily operations.
- **[Customer Journey & Application Workflow](file:///d:/Z-React/POS-Flutter/hotel-management-app/Workflow.md)**: Detailed explanation of how the customer journey works (Booking $\rightarrow$ Check-In $\rightarrow$ Food & Services $\rightarrow$ Housekeeping $\rightarrow$ Check-Out & Invoicing) and the behind-the-scenes offline sync.


## Quick start

```bash
# 1. Backend
cd hotel-backend
npm install
cp .env.example .env        # edit with your MySQL credentials
npm run migrate
npm run seed                # creates default admin: admin / admin123
npm start                   # listens on :5000

# 2. Flutter app (in a separate terminal)
cd ../hotel_app
flutter create hotel_app_shell
cp -r lib pubspec.yaml test hotel_app_shell/
cd hotel_app_shell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<backend-host>:5000/api
```

## Connection between the two — verified

The Flutter app's `ApiEndpoints`, sync payload field names, and pulled
response shapes were cross-checked against every matching backend route
and controller. That pass found and fixed three real bugs (a wrong sync
pull path, reference-data pulls that would have thrown on real data, and
a dead token-refresh path), plus a design gap where an offline check-in/
checkout never produced the same room-status and invoice side effects
that the direct REST endpoints give — all detailed in each project's own
README:

- `hotel-backend/README.md` → section "Backend ↔ Flutter connection —
  verified"
- `hotel_app/README.md` → section "Backend ↔ Flutter connection —
  verified"

Both projects have their own detailed README with setup, architecture,
and testing instructions — start there for anything specific to that half
of the stack.
