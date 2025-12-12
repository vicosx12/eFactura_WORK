# Arhitectura Modernizării VFP 9.0 - Diagrama Vizuală

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          APLICAȚIA VFP 9.0 MODERNIZATĂ                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                    UI LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐         ┌──────────────────┐                         │
│  │  VFP Forms       │         │   WebView2       │                         │
│  │  (Existent)      │         │   (Modern UI)    │                         │
│  │                  │         │                  │                         │
│  │  - CodeJock      │    →    │  - HTML5/CSS3    │                         │
│  │  - Native VFP    │         │  - JavaScript    │                         │
│  │  - OCX Controls  │         │  - Dashboard     │                         │
│  └──────────────────┘         └──────────────────┘                         │
│         ↓                              ↓                                     │
│         └──────────────┬───────────────┘                                     │
└────────────────────────┼─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTEGRATION LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────┐            │
│  │                    wwDotNetBridge                          │            │
│  │              (Punte VFP 32-bit ↔ .NET 64-bit)             │            │
│  └────────────────────────────────────────────────────────────┘            │
│                                ↓                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                   │
│  │   Chilkat    │   │  HttpClient  │   │  WebView2    │                   │
│  │   ActiveX    │   │    .NET      │   │   Control    │                   │
│  │              │   │              │   │              │                   │
│  │ - HTTP/REST  │   │ - Modern API │   │ - Browser    │                   │
│  │ - JSON       │   │ - OAuth2     │   │ - JavaScript │                   │
│  │ - TLS 1.2+   │   │ - Async      │   │ - Interop    │                   │
│  └──────────────┘   └──────────────┘   └──────────────┘                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BUSINESS LOGIC LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │  ANAF Client    │  │  Bank Recon.    │  │  Connection     │            │
│  │                 │  │  Manager        │  │  Pool           │            │
│  │ - Upload XML    │  │                 │  │                 │            │
│  │ - Sign Digital  │  │ - Parse CAMT    │  │ - Pool Mgmt     │            │
│  │ - Validate XSD  │  │ - Parse MT940   │  │ - Validation    │            │
│  │ - Download Msg  │  │ - Auto-Match    │  │ - Monitoring    │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                                  │
│  │ Circuit Breaker │  │  Retry Logic    │                                  │
│  │                 │  │                 │                                  │
│  │ - State Mgmt    │  │ - Exponential   │                                  │
│  │ - Auto-Recovery │  │ - Backoff       │                                  │
│  └─────────────────┘  └─────────────────┘                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DATA ACCESS LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐         ┌──────────────────┐                         │
│  │  ODBC Driver 18  │         │  MySQL ODBC 8.0  │                         │
│  │  (SQL Server)    │         │                  │                         │
│  │                  │         │                  │                         │
│  │  - TLS 1.2+      │         │  - TLS Support   │                         │
│  │  - Performance   │         │  - Modern        │                         │
│  │  - Pooling       │         │  - UTF-8         │                         │
│  └──────────────────┘         └──────────────────┘                         │
│         ↓                              ↓                                     │
└─────────┼──────────────────────────────┼───────────────────────────────────┘
          ↓                              ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATABASE LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐         ┌──────────────────┐                         │
│  │   SQL Server     │         │      MySQL       │                         │
│  │                  │         │                  │                         │
│  │  - Facturi       │         │  - Alternative   │                         │
│  │  - Clienti       │         │  - Compatible    │                         │
│  │  - SAFT Data     │         │                  │                         │
│  └──────────────────┘         └──────────────────┘                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                       EXTERNAL INTEGRATIONS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   ANAF API       │  │   Bank SFTP      │  │   OAuth2 IdP     │         │
│  │   (e-Factura)    │  │   (Statements)   │  │   (Auth)         │         │
│  │                  │  │                  │  │                  │         │
│  │ - Upload Invoice │  │ - CAMT.053       │  │ - Token          │         │
│  │ - Download Msg   │  │ - MT940          │  │ - Refresh        │         │
│  │ - OAuth2         │  │ - Scheduled      │  │ - Validation     │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY & COMPLIANCE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   TLS 1.2+       │  │   Certificates   │  │   GDPR           │         │
│  │                  │  │                  │  │                  │         │
│  │ - All Traffic    │  │ - X.509          │  │ - Data Rights    │         │
│  │ - Encrypted      │  │ - Digital Sign   │  │ - Audit Trail    │         │
│  │ - Verified       │  │ - Validation     │  │ - Encryption     │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                                │
│  │   UAC Win 10/11  │  │   Backup & DR    │                                │
│  │                  │  │                  │                                │
│  │ - Manifest       │  │ - Automated      │                                │
│  │ - Permissions    │  │ - Encrypted      │                                │
│  │ - Locations      │  │ - Tested         │                                │
│  └──────────────────┘  └──────────────────┘                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        MONITORING & LOGGING                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Performance     │  │   Security       │  │   Business       │         │
│  │  Monitoring      │  │   Audit          │  │   Metrics        │         │
│  │                  │  │                  │  │                  │         │
│  │ - Pool Usage     │  │ - Access Log     │  │ - Invoices/Day   │         │
│  │ - Query Time     │  │ - GDPR Events    │  │ - API Calls      │         │
│  │ - API Latency    │  │ - Auth Attempts  │  │ - Success Rate   │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
                            TECHNOLOGY STACK
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  PLATFORM           │  COMPONENTS                                            │
├─────────────────────┼────────────────────────────────────────────────────────┤
│  VFP 9.0            │  Core Application, Business Logic, UI Forms           │
│  .NET Framework 4.8 │  wwDotNetBridge, HttpClient, Cryptography              │
│  .NET Core 6.0+     │  Backend Services, Web API, Microservices              │
│  Windows 10/11      │  Target Platform, UAC, Modern Security                 │
│  SQL Server         │  Primary Database, ODBC Driver 18                      │
│  MySQL              │  Alternative Database, ODBC 8.0                        │
│  WebView2/Chromium  │  Modern UI, HTML5, JavaScript                          │
│  OAuth2             │  Authentication, Token Management                      │
│  TLS 1.2+/1.3       │  Encrypted Communications                              │
│  X.509              │  Digital Certificates, Signing                         │
│  ISO 20022          │  Banking (CAMT.053)                                    │
│  UBL 2.1            │  e-Invoicing (ANAF)                                    │
│  GDPR               │  Data Protection, Privacy                              │
└─────────────────────┴────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
                          IMPLEMENTATION PHASES
═══════════════════════════════════════════════════════════════════════════════

Phase 1: Quick Wins (0-3 months)
  ├─ Week 1-2:   Audit & Setup
  ├─ Week 3-4:   Infrastructure (ODBC, wwDotNetBridge)
  ├─ Week 5-6:   Database (Connection Pool)
  ├─ Week 7-8:   API Integration (First calls)
  ├─ Week 9-10:  ANAF Integration
  └─ Week 11-12: WebView2 UI Prototype

Phase 2: Mid-Term (3-12 months)
  ├─ Month 3-4:  Backend Services (.NET Core API)
  ├─ Month 5-6:  Bank Reconciliation
  ├─ Month 7-8:  Security Hardening (OAuth2, Certificates)
  ├─ Month 9-10: Comprehensive Testing
  └─ Month 11-12: Documentation & Training

Phase 3: Long-Term (12+ months)
  ├─ Pilot Deployment (5-10% users)
  ├─ Staged Rollout (25% → 100%)
  ├─ UI Migration (Complete hybrid)
  ├─ Legacy Decommissioning
  └─ Full Production with Monitoring

═══════════════════════════════════════════════════════════════════════════════

Legend:
  ┌─┐  Component/Module
  │    Data flow / Dependency
  ↓    Direction of flow
  →    Transformation / Evolution
  ═══  Major boundary
  ───  Component boundary

Last Updated: December 12, 2024
Version: 1.0.0
```
