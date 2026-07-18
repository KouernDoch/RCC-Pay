//
//  ForgotPasswordViewModel.swift
//  RCC Pay
//
//  Owns the whole four-step password-reset flow: email → OTP → new password → done.
//  The views below it are stateless renderers; every transition, timer and error
//  decision lives here so the flow can be reasoned about (and tested) in one place.
//

import Foundation

// MARK: - Displayable message

/// A message destined for the UI, which may be either one of our own localized strings
/// or a sentence the backend wrote (rate-limit waits, validation details). Keeping the
/// two cases distinct lets the ViewModel stay free of `LocalizationManager`.
enum FlowMessage: Equatable {
    case key(String)    // looked up in Localizable.strings by the view
    case text(String)   // shown verbatim — already human-readable, English only

    func resolved(_ lm: LocalizationManager) -> String {
        switch self {
        case .key(let key):   return lm[key]
        case .text(let text): return text
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ForgotPasswordViewModel: ObservableObject {

    /// Mirrors the backend's OTP time-to-live *and* its resend cooldown — both are 60s,
    /// so a single countdown can drive "code expires in…" and "resend available in…".
    static let otpLifetime = 60

    enum Step: Int, Comparable {
        case email = 1, otp, reset, success
        static func < (a: Step, b: Step) -> Bool { a.rawValue < b.rawValue }
    }

    // MARK: Flow state

    @Published private(set) var step: Step = .email

    /// Set when the backend says the verified-OTP window lapsed. The reset screen turns
    /// this into a "request a new code" affordance instead of a dead-end error.
    @Published private(set) var mustRestart = false

    // MARK: Inputs

    @Published var email = ""

    /// Kept to digits only and capped at six, so paste and keyboard input can't put the
    /// field into a state the backend would reject on its `\d{6}` pattern.
    @Published var otp = "" {
        didSet {
            let cleaned = String(otp.filter(\.isNumber).prefix(6))
            if cleaned != otp { otp = cleaned }   // terminates: second pass is a no-op
        }
    }

    @Published var newPassword = ""
    @Published var confirmPassword = ""

    // MARK: Output state

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: FlowMessage?
    @Published private(set) var infoMessage: FlowMessage?
    @Published private(set) var secondsRemaining = 0

    /// Bumped on every failure, including one identical to the last. The view keys its
    /// shake animation off this rather than off `errorMessage`, which wouldn't change —
    /// and so wouldn't animate — when the same error repeats.
    @Published private(set) var errorNonce = 0

    private var countdownTask: Task<Void, Never>?

    // MARK: - Derived state

    /// Trimmed and lower-cased to match the backend, which normalizes the same way before
    /// looking the account up. Sending the raw text would break OTP lookup for "  A@b.com".
    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isEmailValid: Bool {
        normalizedEmail.range(
            of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
            options: .regularExpression) != nil
    }

    var isOtpComplete: Bool { otp.count == 6 }

    var canResend: Bool { secondsRemaining == 0 && !isLoading }

    /// `mm:ss` for the countdown label.
    var countdownText: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    // MARK: Password policy

    /// One requirement from the backend's `ResetPasswordRequest` regex, surfaced
    /// individually so the reset screen can show a live checklist rather than making the
    /// user guess after a server rejection.
    struct PasswordRule: Identifiable {
        let id: String
        let labelKey: String
        let isMet: Bool
    }

    var passwordRules: [PasswordRule] {
        let p = newPassword
        // Regex-matched rather than character-set matched so the client agrees exactly
        // with the server's `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$`.
        func has(_ pattern: String) -> Bool {
            p.range(of: pattern, options: .regularExpression) != nil
        }
        return [
            // utf16.count mirrors Java's @Size, which counts UTF-16 units, not graphemes.
            .init(id: "length", labelKey: "fp_rule_length",
                  isMet: (8...128).contains(p.utf16.count)),
            .init(id: "case",   labelKey: "fp_rule_case",
                  isMet: has("[a-z]") && has("[A-Z]")),
            .init(id: "digit",  labelKey: "fp_rule_digit",  isMet: has("[0-9]")),
            .init(id: "symbol", labelKey: "fp_rule_symbol", isMet: has("[^A-Za-z0-9]")),
        ]
    }

    var isPasswordPolicyMet: Bool { passwordRules.allSatisfy(\.isMet) }
    var passwordsMatch: Bool { !confirmPassword.isEmpty && newPassword == confirmPassword }
    var canSubmitReset: Bool { isPasswordPolicyMet && passwordsMatch && !isLoading }

    // MARK: - Lifecycle

    /// Seeds the email from the login screen so the user doesn't retype it.
    func prefill(email seed: String) {
        guard email.isEmpty else { return }
        email = seed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Must be called when the flow leaves the screen — the countdown holds a `Task` that
    /// would otherwise tick on for up to a minute after the view is gone.
    func stopCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    // MARK: - Step 1: request the OTP

    func sendOtp() async {
        guard isEmailValid else {
            setError(.key("email_invalid"))
            return
        }
        await perform {
            try await BackendAPI.requestPasswordResetOtp(email: self.normalizedEmail)
            // Always advances, even for an unknown address: the backend answers
            // identically either way, and revealing the difference here would let anyone
            // test whether an email has an RCC Pay account.
            self.advance(to: .otp)
            self.startCountdown()
        }
    }

    // MARK: - Step 2: verify

    func verifyOtp() async {
        guard isOtpComplete else {
            setError(.key("fp_error_otp_incomplete"))
            return
        }
        await perform {
            _ = try await BackendAPI.verifyPasswordResetOtp(
                email: self.normalizedEmail, otp: self.otp)
            self.stopCountdown()          // the 60s TTL stops mattering once verified
            self.advance(to: .reset)
        }
    }

    // MARK: - Step 3: resend

    func resendOtp() async {
        guard canResend else { return }
        await perform {
            _ = try await BackendAPI.resendPasswordResetOtp(email: self.normalizedEmail)
            self.otp = ""
            self.startCountdown()
            self.infoMessage = .key("fp_otp_resent")
        }
    }

    // MARK: - Step 4: reset

    func resetPassword() async {
        guard isPasswordPolicyMet else {
            setError(.key("fp_error_password_policy"))
            return
        }
        guard newPassword == confirmPassword else {
            setError(.key("password_mismatch"))
            return
        }
        await perform {
            _ = try await BackendAPI.resetPassword(
                email: self.normalizedEmail,
                newPassword: self.newPassword,
                confirmPassword: self.confirmPassword)
            self.advance(to: .success)
        }
    }

    // MARK: - Navigation

    /// Handles the back button. Returns `false` when there is no earlier step to fall back
    /// to, which the view answers by dismissing the whole flow.
    @discardableResult
    func goBack() -> Bool {
        switch step {
        case .email, .success:
            return false
        case .otp:
            otp = ""
            stopCountdown()
            advance(to: .email)
            return true
        case .reset:
            // Deliberately not a step back. The OTP is already verified and stays usable
            // for ten minutes, while only five codes may be issued per hour — bouncing the
            // user back to request another would spend a scarce resource for nothing.
            return false
        }
    }

    /// Full restart, used by the "request a new code" affordance after the reset window lapses.
    func restart() {
        stopCountdown()
        otp = ""
        newPassword = ""
        confirmPassword = ""
        mustRestart = false
        advance(to: .email)
    }

    /// Single funnel for failures so the nonce can never drift out of sync.
    private func setError(_ message: FlowMessage) {
        errorMessage = message
        errorNonce += 1
    }

    private func advance(to next: Step) {
        step = next
        errorMessage = nil
        infoMessage = nil
    }

    // MARK: - Countdown

    private func startCountdown() {
        stopCountdown()
        let deadline = Date().addingTimeInterval(TimeInterval(Self.otpLifetime))
        secondsRemaining = Self.otpLifetime

        // Derived from a wall-clock deadline rather than by decrementing, so the timer
        // stays truthful across backgrounding and dropped ticks.
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard let self, !Task.isCancelled else { return }
                let remaining = max(0, Int(deadline.timeIntervalSinceNow.rounded(.up)))
                if remaining != self.secondsRemaining { self.secondsRemaining = remaining }
                if remaining == 0 { return }
            }
        }
    }

    // MARK: - Request plumbing

    /// Runs one network step with the shared loading/error handling every step needs.
    private func perform(_ work: @escaping () async throws -> Void) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await work()
        } catch {
            let message = Self.message(for: error)
            setError(message)
            if message == .key("fp_error_reset_window") { mustRestart = true }
        }
    }

    // MARK: - Error mapping

    /// Turns anything thrown by the networking layer into something a user can act on.
    private static func message(for error: Error) -> FlowMessage {
        guard let apiError = error as? APIError else { return .key("fp_error_generic") }

        switch apiError {
        case .unauthorized, .decoding:
            return .key("fp_error_generic")

        case .network(let underlying):
            switch (underlying as? URLError)?.code {
            case .some(.timedOut):
                return .key("fp_error_timeout")
            case .some(.notConnectedToInternet), .some(.networkConnectionLost),
                 .some(.cannotConnectToHost), .some(.cannotFindHost),
                 .some(.dataNotAllowed):
                return .key("fp_error_offline")
            default:
                return .key("fp_error_network")
            }

        case .server(let status, let message):
            switch status {
            case 429:
                // The backend's own wording carries the exact wait ("…wait 37 seconds…"),
                // which is more useful than anything we could pre-translate.
                return .text(message)
            case 404:
                return .key("fp_error_user_not_found")
            case 500...599:
                return .key("fp_error_server")
            case 400:
                // Every OTP failure shares status 400 on purpose (a status that varied with
                // account state would leak whether the account exists), so the specific
                // cause has to be read out of the message text.
                return classify(message) ?? .text(message)
            default:
                return .text(message)
            }
        }
    }

    private static func classify(_ message: String) -> FlowMessage? {
        let m = message.lowercased()
        // Order matters: the reset-window message also contains "expired".
        if m.contains("window has expired") || m.contains("has not been verified") {
            return .key("fp_error_reset_window")
        }
        if m.contains("expired")     { return .key("fp_error_otp_expired") }
        if m.contains("invalid otp") { return .key("fp_error_otp_invalid") }
        if m.contains("do not match") { return .key("password_mismatch") }
        return nil
    }
}
