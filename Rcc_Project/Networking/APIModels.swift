import Foundation

// MARK: - Response envelope

/// Every backend endpoint wraps its result in this shape. Note the backend spells
/// the status field `statuse`; we only need `payload`, so the rest is optional.
struct APIEnvelope<T: Decodable>: Decodable {
    let message: String?
    let payload: T?
}

/// Shape of the backend `ErrorResponse` (used to extract a human-readable message).
struct APIErrorBody: Decodable {
    let status: Int?
    let error: String?
    let message: String?
    let fieldErrors: [String: String]?
}

// MARK: - Enums (mirror backend Role / Gender)

enum UserRole: String, Codable {
    case admin = "ADMIN"
    case user = "USER"
}

enum UserGender: String, Codable {
    case male = "MALE"
    case female = "FEMALE"
    case other = "OTHER"
    case unspecified = "UNSPECIFIED"
}

// MARK: - Domain DTOs (decode of backend responses)

struct UserDTO: Codable, Identifiable, Equatable {
    let userId: Int
    let name: String
    let email: String
    let gender: UserGender?
    let profileImage: String?
    let role: UserRole
    let createdAt: String?
    let updatedAt: String?

    var id: Int { userId }
}

struct LoginResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresInMs: Int
    let user: UserDTO
}

struct InvoiceDTO: Codable, Identifiable, Equatable {
    let invoiceId: Int
    let userId: Int
    let userEmail: String
    let amount: Double
    let issueDate: String     // "yyyy-MM-dd"
    let paid: Bool
    let createdAt: String?
    let updatedAt: String?

    var id: Int { invoiceId }
}

struct PaymentDTO: Codable, Identifiable, Equatable {
    let paymentId: Int
    let invoiceId: Int
    let invoiceOwnerUserId: Int
    let paidAmount: Double
    let paidDate: String?      // ISO local date-time
    let createdAt: String?
    let updatedAt: String?

    var id: Int { paymentId }
}

struct NotificationDTO: Codable, Identifiable, Equatable {
    let notificationId: Int
    let invoiceId: Int?
    let paymentId: Int?
    let senderId: Int
    let senderEmail: String
    let receiverId: Int
    let receiverEmail: String
    let title: String
    let message: String
    let read: Bool
    let createdAt: String?
    let updatedAt: String?

    var id: Int { notificationId }
}

struct InvoiceSummaryDTO: Codable, Equatable {
    let year: Int
    let month: Int
    let totalDue: Double
    let totalPaid: Double
    let remaining: Double
    let invoiceCount: Int
    let paidCount: Int
    let unpaidCount: Int
}

struct BulkInvoiceIssueDTO: Decodable {
    let createdCount: Int
    let invoices: [InvoiceDTO]
}

// MARK: - Request bodies (encode)

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
    var fcmToken: String? = nil
}

struct RegisterRequestDTO: Encodable {
    let name: String
    let email: String
    let gender: String        // MALE / FEMALE / OTHER / UNSPECIFIED
    let password: String
    var profileImage: String? = nil
    var fcmToken: String? = nil
}

struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct InvoiceCreateRequestDTO: Encodable {
    var userId: Int? = nil
    let amount: Double
    let issueDate: String      // yyyy-MM-dd
}

struct InvoiceBulkIssueRequestDTO: Encodable {
    let amount: Double
    let issueDate: String      // yyyy-MM-dd
}

struct InvoiceUpdateRequestDTO: Encodable {
    var amount: Double? = nil
    var issueDate: String? = nil
    var paid: Bool? = nil
}

struct PaymentPayRequestDTO: Encodable {
    let amount: Double
    let paidDate: String       // yyyy-MM-dd
}

struct PaymentCreateRequestDTO: Encodable {
    let invoiceId: Int
    let paidAmount: Double
    let paidDate: String       // yyyy-MM-dd'T'HH:mm:ss (LocalDateTime)
}

struct UserCreateRequestDTO: Encodable {
    let name: String
    let email: String
    let gender: String
    let password: String
    var profileImage: String? = nil
    let role: String           // ADMIN / USER
}

struct UserUpdateRequestDTO: Encodable {
    var name: String? = nil
    var email: String? = nil
    var gender: String? = nil
    var profileImage: String? = nil
    var role: String? = nil
}

struct NotificationCreateRequestDTO: Encodable {
    var invoiceId: Int? = nil
    var paymentId: Int? = nil
    let receiverId: Int
    let title: String
    let message: String
}
