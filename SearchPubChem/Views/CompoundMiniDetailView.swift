//
//  CompoundMiniDetailView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/4/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundMiniDetailView: View {
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
        .onTapGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

