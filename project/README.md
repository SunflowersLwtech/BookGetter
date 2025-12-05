# BookGetter - Online Bookstore System

A comprehensive, full-stack online bookstore application built with standard Java Enterprise technologies. This project demonstrates a complete e-commerce workflow including user authentication, product management, shopping cart functionality, order processing, and an administrative dashboard.

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![Java](https://img.shields.io/badge/Java-17-orange.svg)
![Tomcat](https://img.shields.io/badge/Tomcat-11.0-yellow.svg)
![Gradle](https://img.shields.io/badge/Gradle-8.5-blue.svg)

## 📖 Table of Contents

-   [Features](#-features)
-   [Technology Stack](#-technology-stack)
-   [Project Structure](#-project-structure)
-   [Prerequisites](#-prerequisites)
-   [Installation & Deployment](#-installation--deployment)
-   [Usage Guidelines](#-usage-guidelines)
-   [API Documentation](#-api-documentation)
-   [Troubleshooting](#-troubleshooting)

## 🚀 Features

### Front-Office (Customer)
-   **Authentication**: Secure registration and login system with session management.
-   **Book Discovery**: 
    -   Browse books by dynamic categories (Fiction, Technology, etc.).
    -   Advanced search functionality (Title, Author, Category).
    -   Rich book details with cover images and descriptions.
-   **Shopping Experience**:
    -   Persistent shopping cart.
    -   Real-time stock validation.
    -   Easy quantity adjustment and item removal.
-   **Order Management**:
    -   Streamlined checkout process.
    -   Order history tracking.
    -   Shipping address management.
-   **User Profile**: View and update personal information.

### Back-Office (Admin)
-   **Dashboard**: Real-time statistics (Total Revenue, Orders, Users, Books).
-   **Inventory Management**: 
    -   Add, Edit, and Delete books.
    -   **Image Upload**: Local file upload support for book covers.
-   **Order Fulfillment**: 
    -   View all customer orders.
    -   Update order status (`Pending` -> `Shipped` -> `Completed`).
-   **User Management**: View registered user details.

## 🛠 Technology Stack

### Backend
-   **Core**: Java SE 17
-   **Web Framework**: Jakarta Servlet 6.0
-   **Server**: Apache Tomcat 11.0
-   **Build Tool**: Gradle 8.5
-   **Data Persistence**: File-based JSON storage (Gson library) with thread-safe access.

### Frontend
-   **Core**: HTML5, CSS3, JavaScript (ES6+)
-   **Styling**: Custom responsive CSS (Flexbox/Grid), no external frameworks.
-   **Communication**: Fetch API for asynchronous REST calls.

### Development Tools
-   **Automation**: PowerShell scripts for one-click build and deployment.
-   **Version Control**: Git

## 📂 Project Structure

```text
BookGetter/
├── project/
│   ├── dev/                        # Deployment Automation Scripts
│   │   ├── deploy.ps1              # Build, clean, and deploy to Tomcat
│   │   ├── start.ps1               # Start Tomcat server
│   │   └── stop.ps1                # Stop Tomcat server
│   ├── src/main/
│   │   ├── java/com/bookgetter/
│   │   │   ├── models/             # POJOs (Book, User, Order, Cart)
│   │   │   ├── servlets/           # REST API Controllers
│   │   │   ├── services/           # Business Logic Layer
│   │   │   └── utils/              # JSON, File, Session utilities
│   │   └── webapp/                 # Frontend Assets
│   │       ├── css/                # Stylesheets
│   │       ├── js/                 # Client-side Logic
│   │       ├── data/               # Runtime Data Storage (JSON)
│   │       ├── images/             # Uploaded Book Covers
│   │       └── *.html              # View Templates
│   ├── build.gradle                # Dependencies & Build Config
│   └── settings.gradle             # Project Name Config
├── 项目技术栈信息.md                # Environment Configuration Reference
└── README.md                       # Documentation
```

## 📋 Prerequisites

Before running the project, ensure your environment meets the following requirements. The `deploy.ps1` script can auto-detect these if installed in standard locations.

-   **Java Development Kit (JDK)**: Version 17 or higher.
-   **Apache Tomcat**: Version 11.0 or compatible 10.x.
-   **PowerShell**: Version 5.1+ (Standard on Windows 10/11).

> **Tip**: Project paths for Java and Tomcat can be configured in `项目技术栈信息.md` if they are in non-standard locations.

## 💿 Installation & Deployment

This project includes advanced PowerShell scripts to automate the entire build and deployment lifecycle.

### 1. Clone the Repository
```powershell
git clone https://github.com/SunflowersLwtech/BookGetter.git
cd BookGetter/project
```

### 2. Automated Deployment (Recommended)
Run the deployment script to build the WAR file, stop any running server, deploy the artifact, and restart the server.

```powershell
# Run from project root
.\dev\deploy.ps1
```

**What this script does:**
1.  Checks for JDK and Tomcat availability.
2.  Stops Tomcat if it's currently running.
3.  Cleans old deployments.
4.  Runs `./gradlew war` to build the application.
5.  Copies `BookGetter.war` to Tomcat's `webapps` directory.
6.  Starts Tomcat and opens the application.

### 3. Server Control
-   **Start Server**: `.\dev\start.ps1`
-   **Stop Server**: `.\dev\stop.ps1`

## 📖 Usage Guidelines

### Accessing the Application
Once deployed, access the application at:
**http://localhost:8080/BookGetter/**

### Default Credentials
You can register a new account or use the existing data if available.

-   **Admin Role**: Select "Admin" during registration (or manually update `users.json`).
-   **Regular User**: Select "Customer" during registration.

### Data Storage
Data is stored securely in JSON format within the deployment directory. To reset data, delete the `.json` files in the `data/` folder, and the application will regenerate them (or load defaults for books).

## 🔌 API Documentation

All API endpoints accept and return JSON.

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| **Auth** | | | |
| `POST` | `/api/login` | Authenticate user | No |
| `POST` | `/api/register` | Create account | No |
| `DELETE` | `/api/login` | Logout | Yes |
| **Books** | | | |
| `GET` | `/api/books` | List all books (supports filtering) | No |
| `GET` | `/api/books?id={id}` | Get book details | No |
| `POST` | `/api/admin/books` | Create new book | **Admin** |
| `POST` | `/api/upload` | Upload book cover image | **Admin** |
| **Cart** | | | |
| `GET` | `/api/cart` | Get current cart | Yes |
| `POST` | `/api/cart` | Add item to cart | Yes |
| `PUT` | `/api/cart` | Update item quantity | Yes |
| **Orders** | | | |
| `GET` | `/api/orders` | Get order history | Yes |
| `POST` | `/api/orders` | Place new order | Yes |
| `PUT` | `/api/admin/orders/{id}` | Update order status | **Admin** |

## 🔧 Troubleshooting

### Common Issues

1.  **Port 8080 Application Issue**
    -   **Symptom**: "Port 8080 is already in use".
    -   **Fix**: Run `.\dev\stop.ps1` to kill the process occupying the port.

2.  **Environment Variables Not Found**
    -   **Symptom**: `deploy.ps1` complains about missing Java or Tomcat.
    -   **Fix**: Ensure `Start-Process` can find `java` in PATH, or set `JAVA_HOME` and `CATALINA_HOME` environment variables manually. Alternatively, edit `项目技术栈信息.md` to point to your specific paths.

3.  **Image Upload Fails**
    -   **Symptom**: "Failed to upload image".
    -   **Fix**: Ensure the Tomcat process has write permissions to the deployment directory `webapps/BookGetter/images`.

---
**Developed by LIUWEI**
*All rights reserved.*
