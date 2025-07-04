//
//  AppButtonStyle.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/27/25.
//

import SwiftUI

struct AppButtonStyle {
    /// Primary button styling.
    ///
    /// Usage:
    /// ```
    /// Button("Save") { action() }
    /// .buttonStyle(AppButtonStyle.Primary())
    /// ```
    struct Primary: ButtonStyle {
        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            return configuration.label
                .font(.appButtonPrimary)
                .foregroundStyle(isEnabled ? .appButtonPrimaryOnSurface : .appOnSurfaceDisabled)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(isEnabled ? .appButtonPrimarySurface : .appSurfaceDisabled)
                .cornerRadius(8)
        }
    }
}


// MARK: - Previews

#Preview("Light") {
    ButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButtonPreview()
        .preferredColorScheme(.dark)
}

fileprivate struct ButtonPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
            }, label: {
                Label("Button", systemImage: "house")
            })
            .buttonStyle(AppButtonStyle.Primary())

            // disabled
            Button(action: {
            }, label: {
                Label("Button", systemImage: "house")
            })
            .buttonStyle(AppButtonStyle.Primary())
            .disabled(true)
        }
    }
}

