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
        ZStack {
            if let image = image {
                Image(uiImage: image)
            }
            
            VStack {
                Spacer()
                
                Text(name)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(formula)
                    .foregroundColor(.black)
                
                Spacer()
            }
        }
        .padding()
        .onTapGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

