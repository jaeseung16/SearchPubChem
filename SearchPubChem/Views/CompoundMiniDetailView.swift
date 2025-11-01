//
//  CompoundMiniDetailView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/4/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundMiniDetailView: View {

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
        GeometryReader { geometry in
            HStack {
                Spacer()
                
                VStack(alignment: .center) {
                    Spacer()
                    
                    Text(name)
                        .foregroundColor(.black)
                    
                    if let image = image {
                        Image(uiImage: image)
                    }
                    
                    Text(formula)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
        }
        
    }
}

