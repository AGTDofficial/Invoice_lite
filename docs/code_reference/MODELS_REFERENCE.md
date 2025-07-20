# Code Reference: Models and Types

This document provides a comprehensive reference of all models, types, and their relationships in the Invoice Lite application.

## Core Models

### Account
**File:** `lib/models/account.dart`  
**Type:** `@freezed` class  
**Hive Type:** `typeId: 0`  
**Fields:**
- `String? id` - Unique identifier
- `String name` - Account name
- `String? email` - Contact email
- `String? phone` - Contact phone
- `String? address` - Physical address
- `String? gstNumber` - GST identification
- `String? panNumber` - PAN number
- `String? state` - State for tax purposes
- `String? stateCode` - State code
- `String? accountType` - Type of account (customer/supplier)

### InvoiceItem
**File:** `lib/models/invoice_item.dart`  
**Type:** `@freezed` class  
**Hive Type:** `typeId: 1`  
**Fields:**
- `String? id` - Unique identifier
- `String name` - Item name
- `String? description` - Item description
- `String? hsnCode` - HSN/SAC code
- `double price` - Unit price
- `double quantity` - Item quantity
- `double discount` - Discount percentage
- `double taxRate` - Tax rate percentage
- `String? unit` - Unit of measurement
- `double? cgst` - CGST amount
- `double? sgst` - SGST amount
- `double? igst` - IGST amount
- `double? cess` - CESS amount

### Invoice
**File:** `lib/models/invoice.dart`  
**Type:** `@freezed` class  
**Hive Type:** `typeId: 2`  
**Fields:**
- `String? id` - Unique identifier
- `String invoiceNumber` - Invoice number
- `DateTime invoiceDate` - Date of invoice
- `DateTime? dueDate` - Due date
- `Account? customer` - Customer account
- `Account? seller` - Seller account
- `List<InvoiceItem> items` - List of invoice items
- `double subtotal` - Subtotal before tax
- `double taxAmount` - Total tax amount
- `double total` - Grand total
- `double? discount` - Total discount
- `String? notes` - Additional notes
- `String? terms` - Payment terms
- `String status` - Invoice status (draft/paid/unpaid)
- `String? reference` - Reference number
- `String? paymentMethod` - Payment method
- `double? paidAmount` - Amount paid
- `double? balance` - Remaining balance

## State Management

### InvoiceState
**File:** `lib/models/invoice_state.dart`  
**Purpose:** Manages the state of invoices in the application  
**Properties:**
- `List<Invoice> invoices` - List of all invoices
- `bool isLoading` - Loading state indicator
- `String? error` - Error message if any

### AccountState
**File:** `lib/models/account_state.dart`  
**Purpose:** Manages the state of accounts in the application  
**Properties:**
- `List<Account> accounts` - List of all accounts
- `bool isLoading` - Loading state indicator
- `String? error` - Error message if any

## Type Definitions

### Hive Type Adapters
- Account: `typeId: 0`
- InvoiceItem: `typeId: 1`
- Invoice: `typeId: 2`
- DateTime: Handled by Hive's built-in adapter

### Enums
```dart
enum InvoiceStatus {
  draft,
  paid,
  unpaid,
  cancelled,
  overdue
}

enum AccountType {
  customer,
  supplier,
  both
}
```

## Relationships
1. **Invoice to Account (Many-to-One)**
   - An Invoice has one Customer (Account)
   - An Invoice has one Seller (Account)
   - An Account can have multiple Invoices

2. **Invoice to InvoiceItem (One-to-Many)**
   - An Invoice contains multiple InvoiceItems
   - Each InvoiceItem belongs to one Invoice

## Data Flow
1. **Invoice Creation Flow**
   - User selects/creates a Customer (Account)
   - User adds multiple InvoiceItems
   - System calculates totals and taxes
   - Invoice is saved to Hive database

2. **Account Management**
   - Accounts are created/edited in the Account screen
   - Accounts are stored in Hive with typeId: 0
   - Accounts can be associated with multiple invoices

## Important Notes
- All monetary values are stored as `double`
- Dates are stored as `DateTime` objects
- Hive TypeIds must be unique across all model classes
- Freezed is used for immutable models with value equality
- All models implement `fromJson`/`toJson` for serialization
