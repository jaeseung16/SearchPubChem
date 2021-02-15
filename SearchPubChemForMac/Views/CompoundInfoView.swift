//
//  CompoundInfoView.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/14/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundInfoView: View {
    var name: String
    var formula: String
    var molecularWeight: Double
    var cid: String
    var nameIUPAC: String
    var added: Date
    var image: NSImage
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    
                Text("\(name)")
                    .font(.title)
                    .foregroundColor(.black)
            }
            .frame(width: 150, height: 150, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            
            Text("\(formula)")
                .font(.title2)
            Text("\(molecularWeight)")
                .font(.title3)
            
            Text("\(itemFormatter.string(from: added))")
                .font(.body)
        }
        .foregroundColor(.primary)
    }
    
    private func entryView(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.black)
        }
    }
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct CompoundInfoView_Previews: PreviewProvider {
    static let name = "water"
    static let formula = "H2O"
    static let molecularWeight = 18.015
    static let cid = "962"
    static let nameIUPAC = "oxidane"
    static let added = Date()
    static let image = NSImage(named: "water")!
    
    static var previews: some View {
        CompoundInfoView(
            name: CompoundInfoView_Previews.name,
            formula: CompoundInfoView_Previews.formula,
            molecularWeight: CompoundInfoView_Previews.molecularWeight,
            cid: CompoundInfoView_Previews.cid,
            nameIUPAC: CompoundInfoView_Previews.nameIUPAC,
            added: CompoundInfoView_Previews.added,
            image: image
        )
    }
}
