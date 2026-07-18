import Foundation

/// High-level, typed wrappers around every backend endpoint the app uses.
/// Views/ViewModels call these instead of touching ``APIClient`` directly.
enum BackendAPI {

    private static var client: APIClient { .shared }

    // MARK: Auth

    static func login(email: String, password: String, fcmToken: String? = nil) async throws -> LoginResponseDTO {
     
        try await client.post(
            "/auth/login",
            body: LoginRequestDTO(email: email, password: password, fcmToken: fcmToken))
    }

    static func register(_ body: RegisterRequestDTO) async throws -> LoginResponseDTO {
        try await client.post("/auth/register", body: body)
    }

    // MARK: Password reset (OTP)
    //
    // Four public endpoints, all unauthenticated. The OTP lives for 60s, resends are
    // rate-limited to one per 60s and five per rolling hour, and the reset itself must
    // land within 10 minutes of a successful verification.

    /// Step 1 — email the user a 6-digit OTP.
    ///
    /// Succeeds even when no account exists for `email`: the backend deliberately returns
    /// the same message either way so the endpoint can't be used to enumerate accounts.
    /// Callers must therefore always advance to the OTP screen and never report
    /// "account not found" here.
    @discardableResult
    static func requestPasswordResetOtp(email: String) async throws -> MessageResponseDTO {
        try await client.post("/auth/forgot-password", body: ForgotPasswordRequestDTO(email: email))
    }

    /// Step 2 — verify the code the user typed.
    ///
    /// Throws `APIError.server(status: 400, …)` when the OTP is wrong or has expired, and
    /// `status: 429` once five wrong guesses lock the code.
    @discardableResult
    static func verifyPasswordResetOtp(email: String, otp: String) async throws -> VerifyOtpResponseDTO {
        try await client.post(
            "/auth/verify-forgot-password-otp",
            body: VerifyOtpRequestDTO(email: email, otp: otp))
    }

    /// Step 3 — issue a fresh OTP, retiring the previous one.
    ///
    /// Unlike step 1 this *does* report throttling (429 with the remaining wait in the
    /// message), because by this point the user already knows the account exists.
    @discardableResult
    static func resendPasswordResetOtp(email: String) async throws -> MessageResponseDTO {
        try await client.post(
            "/auth/resend-forgot-password-otp",
            body: ResendOtpRequestDTO(email: email))
    }

    /// Step 4 — set the new password. Requires a verified OTP that is still inside the
    /// backend's 10-minute verification window, otherwise it fails with 400.
    @discardableResult
    static func resetPassword(
        email: String,
        newPassword: String,
        confirmPassword: String
    ) async throws -> MessageResponseDTO {
        try await client.post(
            "/auth/reset-password",
            body: ResetPasswordRequestDTO(
                email: email,
                newPassword: newPassword,
                confirmPassword: confirmPassword))
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

    /// Update the signed-in user's own profile (name / gender / email / photo URL).
    static func updateCurrentUser(_ body: UserUpdateRequestDTO) async throws -> UserDTO {
        try await client.put("/users/me", body: body)
    }

    /// Uploads a profile photo to the backend, which persists it as the current user's
    /// `profileImage`. Returns the served file URL.
    static func uploadProfileImage(data: Data, filename: String, mimeType: String) async throws -> String {
        let payload: FileUploadDTO = try await client.upload(
            "/files/upload", fileData: data, fileName: filename, mimeType: mimeType)
        return payload.fileUrl
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
