//
//  SearchResultViewForMac.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/9/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SearchResultView: View {
    @State private var compoundName = "water"
    @State private var molecularWeight = "18.0"
    @State private var cid = "962"
    @State private var iupacName = "oxidane"
    @State private var imageName = "Water"
    
    var body: some View {
        VStack {
            Text(compoundName)
            
            Spacer()
            
            Image(imageName)
            
            Spacer()
                
            molecularWeigtView
            
            cidView
            
            iupacNameView
        }
        .frame(width: 400, height: 500, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .padding()
    }
    
    private var molecularWeigtView: some View {
        VStack {
            Text("Molecular Weight (gram/mol)")
            Text(molecularWeight)
        }
    }
    
    private var cidView: some View {
        VStack {
            Text("PubChem Compound Identifier (CID)")
            Text(cid)
        }
    }
    
    private var iupacNameView: some View {
        VStack {
            Text("IUPAC Name")
            Text(iupacName)
        }
    }
}

struct SearchResultView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultView()
    }
}
