# CLAUDE.md

## Project Overview

Build a native iOS application called "RCC Payment Management".

The application is for tenants and administrators to manage house rentals, invoices, and payments.

Backend API:

* Spring Boot
* PostgreSQL
* JWT Authentication

The iOS app consumes REST APIs.

Platform:

* iOS 18+
* Swift 6
* SwiftUI

Architecture:

* MVVM
* Repository Pattern
* Dependency Injection

---

## User Roles

### Tenant

Tenant can:

* Login
* View dashboard summary
* View paid amount
* View remaining balance
* View invoices
* Filter payment history
* View invoice details
* Display QR code for payment
* Download invoice PDF
* Update profile

### Admin

Admin can:

* Login
* View dashboard
* Manage tenants
* Manage houses
* Generate invoices
* View payment reports
* Manage user accounts

---

## SwiftUI Requirements

Use:

* SwiftUI only
* NavigationStack
* Async/Await
* ObservableObject
* @StateObject
* @EnvironmentObject

Avoid:

* UIKit unless absolutely necessary
* Storyboards
* XIB files

---

## Folder Structure

RentHouseApp

├── App
├── Core
│   ├── Networking
│   ├── Storage
│   ├── Utilities
│   └── Extensions
│
├── Models
│
├── Services
│
├── ViewModels
│
├── View
│   ├── Auth
│   ├── Dashboard
│   ├── Invoice
│   ├── Payment
│   ├── House
│   ├── Tenant
│   ├── Profile
│   └── Admin
│
│
├── Resources
│
└── Preview

---

## Screens

### Authentication

* Splash Screen
* Login Screen

### Tenant

* Dashboard
* Invoice List
* Invoice Detail
* Payment History
* QR Payment
* Profile

### Admin

* Dashboard
* Tenant List
* Tenant Detail
* House List
* House Detail
* Invoice Management
* Revenue Report

---

## Dashboard Design

Tenant Dashboard shows:

* Total Paid
* Remaining Balance
* Current Month Status
* Recent Invoice
* Payment History

Admin Dashboard shows:

* Total Houses
* Occupied Houses
* Vacant Houses
* Total Tenants
* Revenue
* Pending Invoices

---

## API Layer

Use:

* URLSession
* Async/Await

Create:

* APIClient
* Endpoint
* NetworkError

Example:

APIClient.shared.request()

All API calls must use strongly typed DTOs.

---

## Authentication

Use JWT.

Store:

* Access Token
* Refresh Token

Storage:

* Keychain

Requirements:

* Auto login
* Auto refresh token
* Logout support

---

## State Management

Each feature must contain:

* View
* ViewModel
* Models

Business logic belongs inside ViewModel.

Views should remain lightweight.

---

## Models

Examples:

User
House
Rental
Invoice
Payment

Use:

Codable
Identifiable
Sendable

---

## UI Components

Reusable components:

* PrimaryButton
* SecondaryButton
* LoadingView
* EmptyStateView
* ErrorView
* DashboardCard
* InvoiceCard
* PaymentCard

---

## Design System

Follow Apple Human Interface Guidelines.

Requirements:

* Dark Mode Support
* Dynamic Type Support
* Accessibility Labels
* Native iOS Look and Feel

Use:

* SF Symbols
* System Colors
* Standard Spacing

Avoid custom design systems.

---

## Error Handling

Handle:

* Network Error
* Unauthorized
* Validation Error
* Server Error

Display user-friendly alerts.

---

## Testing

Generate:

* Unit Tests
* Mock Services
* Mock Repositories

Test:

* ViewModels
* Repositories
* Authentication Flow

---

## Performance

Requirements:

* LazyVStack for lists
* Async image loading
* Pagination support
* Efficient state updates

---

## Code Style

Requirements:

* SOLID Principles
* Clean Architecture
* Small reusable views
* Dependency Injection
* No force unwraps
* No hardcoded strings
* No duplicated code

Always generate production-ready SwiftUI code.
