import Foundation

/// High-level, typed wrappers around every backend endpoint the app uses.
/// Views/ViewModels call these instead of touching ``APIClient`` directly.
enum BackendAPI {

    private static var client: APIClient { .shared }

    // MARK: Auth

    static func login(email: String, password: String) async throws -> LoginResponseDTO {
        try await client.post("/auth/login", body: LoginRequestDTO(email: email, password: password))
    }

    static func register(_ body: RegisterRequestDTO) async throws -> LoginResponseDTO {
        try await client.post("/auth/register", body: body)
    }

    // MARK: Users

    static func currentUser() async throws -> UserDTO {
        try await client.get("/users/me")
    }

    static func changePassword(current: String, new: String) async throws {
        try await client.putVoid(
            "/users/me/password",
            body: ChangePasswordRequestDTO(currentPassword: current, newPassword: new))
    }

    static func listUsers() async throws -> [UserDTO] {
        try await client.get("/users")
    }

    static func createUser(_ body: UserCreateRequestDTO) async throws -> UserDTO {
        try await client.post("/users", body: body)
    }

    static func updateUser(id: Int, _ body: UserUpdateRequestDTO) async throws -> UserDTO {
        try await client.put("/users/\(id)", body: body)
    }

    static func deleteUser(id: Int) async throws {
        try await client.delete("/users/\(id)")
    }

    // MARK: Invoices

    static func listInvoices() async throws -> [InvoiceDTO] {
        try await client.get("/invoices")
    }

    static func monthlySummary(year: Int, month: Int) async throws -> InvoiceSummaryDTO {
        try await client.get(
            "/invoices/me/summary",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
            ])
    }

    static func createInvoice(_ body: InvoiceCreateRequestDTO) async throws -> InvoiceDTO {
        try await client.post("/invoices", body: body)
    }

    static func bulkIssue(amount: Double, issueDate: String) async throws -> BulkInvoiceIssueDTO {
        try await client.post(
            "/invoices/bulk",
            body: InvoiceBulkIssueRequestDTO(amount: amount, issueDate: issueDate))
    }

    static func updateInvoice(id: Int, _ body: InvoiceUpdateRequestDTO) async throws -> InvoiceDTO {
        try await client.put("/invoices/\(id)", body: body)
    }

    static func deleteInvoice(id: Int) async throws {
        try await client.delete("/invoices/\(id)")
    }

    // MARK: Payments

    static func listPayments() async throws -> [PaymentDTO] {
        try await client.get("/payments")
    }

    /// Pays down the current user's open invoice for this month (backend resolves the invoice).
    static func payForCurrentUser(amount: Double, paidDate: String) async throws -> PaymentDTO {
        try await client.post(
            "/payment/pay",
            body: PaymentPayRequestDTO(amount: amount, paidDate: paidDate))
    }

    /// Admin: record a full payment against a specific invoice (marks it paid).
    static func createPayment(invoiceId: Int, paidAmount: Double, paidDate: String) async throws -> PaymentDTO {
        try await client.post(
            "/payments",
            body: PaymentCreateRequestDTO(
                invoiceId: invoiceId, paidAmount: paidAmount, paidDate: paidDate))
    }

    static func deletePayment(id: Int) async throws {
        try await client.delete("/payments/\(id)")
    }

    // MARK: Notifications

    static func listNotifications() async throws -> [NotificationDTO] {
        try await client.get("/notifications")
    }

    static func createNotification(_ body: NotificationCreateRequestDTO) async throws -> NotificationDTO {
        try await client.post("/notifications", body: body)
    }

    static func markNotificationRead(id: Int) async throws -> NotificationDTO {
        try await client.send("/notifications/\(id)/read", method: .patch)
    }

    static func markAllNotificationsRead() async throws {
        let _: [String: Int] = try await client.send("/notifications/read-all", method: .post)
    }

    static func deleteNotification(id: Int) async throws {
        try await client.delete("/notifications/\(id)")
    }
}
