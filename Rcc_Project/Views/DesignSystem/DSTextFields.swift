//
//  DSTextFields.swift
//  RCC Pay
//
//  Text input. Two layers:
//
//   • `DSFieldRow`  — the chrome (icon, focus tint, trailing accessory) with the actual
//                     input passed in. Use when you need an unusual control in the slot.
//   • `DSTextField` — the common case, generic over the caller's `@FocusState` enum so
//                     next-field submit chains keep working.
//
//  `DSFieldGroup` stacks rows into one bordered card, the way Settings groups inputs.
//

import SwiftUI

// MARK: - Field chrome

struct DSFieldRow<Input: View, Accessory: View>: View {

    let systemImage: String
    let isActive: Bool
    var isInvalid: Bool = false
    @ViewBuilder var input: Input
    @ViewBuilder var accessory: Accessory

    private var tint: Color { isInvalid ? .dsDanger : .dsBrand }

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Image(systemName: systemImage)
                .font(.system(.footnote, weight: .semibold))
                .foregroundStyle(isActive || isInvalid ? tint : Color.secondary)
                .frame(width: DS.IconSlot.md, height: DS.IconSlot.md)
                .background(Circle().fill(tint.opacity(isActive || isInvalid ? 0.14 : 0.07)))
                .accessibilityHidden(true)

            input
                .font(.dsBody)

            accessory
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, DS.Space.sm + 2)
        // A tinted wash rather than a moving border: it marks focus without shifting layout.
        .background(isActive ? tint.opacity(0.06) : Color.clear)
        .animation(DS.Motion.fade, value: isActive)
        .animation(DS.Motion.fade, value: isInvalid)
    }
}

extension DSFieldRow where Accessory == EmptyView {
    init(
        systemImage: String,
        isActive: Bool,
        isInvalid: Bool = false,
        @ViewBuilder input: () -> Input
    ) {
        self.init(
            systemImage: systemImage,
            isActive: isActive,
            isInvalid: isInvalid,
            input: input,
            accessory: { EmptyView() })
    }
}

// MARK: - Text field

/// `Field` is the caller's `@FocusState` enum, so `.onSubmit` chains between rows
/// still work — the previous screens all hand-rolled this.
struct DSTextField<Field: Hashable>: View {

    let placeholder: String
    @Binding var text: String
    let systemImage: String

    var focus: FocusState<Field?>.Binding
    let field: Field

    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var capitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    var isInvalid: Bool = false
    /// Shows a green tick once the field holds something valid.
    var showsValidTick: Bool = false
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false

    private var isActive: Bool { focus.wrappedValue == field }

    var body: some View {
        DSFieldRow(systemImage: systemImage, isActive: isActive, isInvalid: isInvalid) {
            Group {
                if isSecure && !isRevealed {
                    SecureField(placeholder, text: $text)
                        .focused(focus, equals: field)
                } else {
                    TextField(placeholder, text: $text)
                        .focused(focus, equals: field)
                }
            }
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
        } accessory: {
            if isSecure {
                Button {
                    withAnimation(DS.Motion.fade) { isRevealed.toggle() }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(.footnote))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
            } else if showsValidTick && !text.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.footnote))
                    .foregroundStyle(Color.dsSuccess)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                    .accessibilityHidden(true)
            }
        }
        .animation(DS.Motion.quick, value: text.isEmpty)
    }
}

// MARK: - Field group

/// Stacks field rows into a single bordered card with hairlines between them.
struct DSFieldGroup<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .dsSurface(radius: DS.Radius.md, elevation: .low, fill: .dsSurface)
    }
}

/// Divider tuned for `DSFieldGroup` — aligned to the text, past the icon slot.
struct DSFieldDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsSeparator.opacity(0.45))
            .frame(height: 0.5)
            .padding(.leading, DS.Space.sm + DS.IconSlot.md + DS.Space.sm)
    }
}

// MARK: - Labelled well

/// Label above a single boxed input. Used on the forms that aren't grouped
/// (Edit Profile, Password & Security) where each field has its own caption.
struct DSLabeledField<Input: View>: View {

    let label: String
    var systemImage: String? = nil
    var isInvalid: Bool = false
    @ViewBuilder var input: Input

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(.secondary)

            HStack(spacing: DS.Space.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(.footnote))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                }
                input.font(.dsBody)
            }
            .padding(.horizontal, DS.Space.sm + 2)
            .padding(.vertical, DS.Space.sm + 1)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .fill(Color.dsSurfaceSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .strokeBorder(isInvalid ? Color.dsDanger.opacity(0.5) : Color.dsHairline, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

private struct DSTextFieldPreview: View {
    enum F { case email, password }
    @FocusState private var focus: F?
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            DSFieldGroup {
                DSTextField(
                    placeholder: "Enter your email",
                    text: $email,
                    systemImage: "envelope.fill",
                    focus: $focus,
                    field: F.email,
                    keyboard: .emailAddress,
                    showsValidTick: true)
                DSFieldDivider()
                DSTextField(
                    placeholder: "Enter your password",
                    text: $password,
                    systemImage: "lock.fill",
                    focus: $focus,
                    field: F.password,
                    isSecure: true,
                    submitLabel: .done)
            }

            DSLabeledField(label: "Name", systemImage: "person.fill") {
                TextField("Your name", text: .constant(""))
            }
        }
        .padding(DS.Space.page)
        .background(Color.dsBackground)
    }
}

#Preview("Text fields") { DSTextFieldPreview() }
