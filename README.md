#  GreenBasket - Mobile Farming & E-Commerce Application

GreenBasket is a comprehensive e-commerce and marketplace solution designed for local agricultural commerce. The platform directly connects **Producers (Farmers)** and **Consumers**, eliminating unnecessary intermediaries to ensure fair pricing, premium product freshness, and absolute supply chain transparency.

---

##  Project Contributors & Academic Information

| Student ID | Student Name | Role / Assignment | Email |
| :--- | :--- | :--- | :--- |
| **1900003285** | **Özlem Nur Bora** | **Group Leader / Developer** | 1900003285@stu.iku.edu.tr |
| 2100004806 | Songül Nur Öztürk | Developer | 2100004806@stu.iku.edu.tr |
| 2100004398 | Nisanur Karataş | Developer | 2100004398@stu.iku.edu.tr |
| 2100005460 | Mehmet Serdar Şimşek | Developer | 2100005460@stu.iku.edu.tr |
| 2100004402 | Erhan Arslan | Developer | 2100004402@stu.iku.edu.tr |

* **Course:** SEN0412 Mobile Programming I
* **Term:** Spring 2025/2026 Project Registration
* **Department:** Computer Engineering - Istanbul Kültür University

---

##  Core Architectural Features

GreenBasket is a high-performance mobile application developed with Flutter that connects local organic producers directly with consumers. The core of the application relies on a Cloud Firestore (Firebase) database to manage real-time inventory, user authentication, and order processing.

* **Session Persistence:** Secure, production-grade authentication flow featuring encrypted session tokens. Users remain securely authenticated across application lifecycle states and emulator recycles without re-entry constraints.
* **Smart Order Bundling & Telemetry:** Sophisticated cross-vendor order grouping algorithms. Multiple items purchased simultaneously are dynamically consolidated into unified timeline entries based on millisecond-accurate timestamps, protecting relational telemetry even under divergent multi-vendor status workflows.
* **Dynamic Content Hydration:** Reactive state management coupled with live document streaming directly from remote collections, featuring real-time visual loaders, custom pull-to-refresh pullers, and zero-flicker placeholder caching.
* **Responsive Viewport Adaptability:** Adaptive UI layouts optimized with reactive scroll-view layers and keyboard view-inset constraints, completely neutralizing vertical overflow vulnerabilities across diverse device profiles and low-tier viewports.

---

## 🛠️ Technological Stack & Infrastructure

* **Framework:** Flutter (Dart UI Architecture)
* **Backend Database:** Google Cloud Firestore (NoSQL Document-Model Schema Engine)
* **Authentication:** Firebase Auth SDK
* **State Management & Streaming:** Dart Async Streams & Reactive Async Snapshots
* **Project Architecture Type:** Database & Client-Server Mobile Application

---

##  System Folder Structure

```text
green_basket/
├── lib/
│   ├── models/       # Data representation schemas (Product, Cart, etc.)
│   ├── pages/        # Contextual viewport modules (Checkout, Orders, Settings, Detail)
│   ├── services/     # Decoupled infrastructure logic (Database Seeders, Firestore Streams)
│   ├── widgets/      # Modular, immutable UI fragments (Custom Refreshers, Global AppBars)
│   └── main.dart     # Application bootstrap and core middleware config
```

Local Installation & Development Deployment
To spin up a local development instance of GreenBasket from the project root directory, execute the following steps:

1. Navigate to the Project Root Folder:
Open your terminal/command prompt directly inside the green_basket project folder.

2. Fetch Package Dependencies:
```bash
flutter pub get
```
3. Verify Device Connectivity (Physical Device or Android Emulator):
```bash
flutter devices
```

4. Execute Target Runtime Compilation:
```bash
flutter run
```
