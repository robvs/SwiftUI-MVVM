//
//  HomeCategoryListRow.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import SwiftUI

/// Layout for a single row in the category list on the Home screen.
struct HomeCategoryListRow: View {
    let categoryName: String

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(categoryName.capitalized)
                    .appBodyText().bold()

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.appTextLink)
            }

            Divider()
                .frame(height: 1)
                .overlay(.appBorder)
        }
        .padding(.top, 8)
    }
}


// MARK: - Previews

#Preview("Light") {
    VStack(spacing: 0) {
        HomeCategoryListRow(categoryName: "Category Name")
        HomeCategoryListRow(categoryName: "Category Name")
        HomeCategoryListRow(categoryName: "Category Name")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        HomeCategoryListRow(categoryName: "Category Name")
        HomeCategoryListRow(categoryName: "Category Name")
        HomeCategoryListRow(categoryName: "Category Name")
    }
    .preferredColorScheme(.dark)
}
