//
//  IngredientDetailView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/16/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct IngredientDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var compound: Compound
    
    private var name: String {
        compound.name ?? ""
    }
    
    private var formula: String {
        compound.formula ?? ""
    }
    
    private var image: UIImage? {
        if let data = compound.image {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(name)
                .foregroundColor(.primary)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            Text(formula)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Dismiss") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
    }
}

