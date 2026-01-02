//
//  UIKitTextField.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import SwiftUI
import UIKit

struct UIKitTextField: UIViewRepresentable {
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField
        init(_ parent: UIKitTextField) { self.parent = parent }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }

    @Binding var text: String
    var placeholder: String

    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var autocorrectionType: UITextAutocorrectionType = .no
    var isSecure: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.textContentType = textContentType
        tf.autocapitalizationType = autocapitalizationType
        tf.autocorrectionType = autocorrectionType
        tf.isSecureTextEntry = isSecure
        tf.borderStyle = .roundedRect
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChangeSelection(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        uiView.isSecureTextEntry = isSecure
    }
}
