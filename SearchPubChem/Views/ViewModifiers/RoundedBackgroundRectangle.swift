//
//  RoundedBackgroundRectangle.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/25/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct RoundedBackgroundRectangle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
    }
}

extension View {
    func roundedBackgroundRectangle() -> some View {
        modifier(RoundedBackgroundRectangle())
    }
}
