//
//  WidgetEntryView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 6/20/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: WidgetEntry
    
    private var widgetURL: URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = SearchPubChemConstants.widgetURLScheme.rawValue
        urlComponents.path = "/\(entry.id)"
        urlComponents.query = "\(entry.name)"
        return urlComponents.url
    }

    private var futureDate: Date {
        let components = DateComponents(second: 75)
        let futureDate = Calendar.current.date(byAdding: components, to: Date())!
        return futureDate
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.secondary)
            
            if let image = entry.image, let uiImage = UIImage(data: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("SearchPubChemWidgetBackground")
                    .resizable()
                    .scaledToFit()
            }
                
            VStack {
                Text(entry.name)
                    .truncationMode(.tail)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                Spacer()
                    
                Text(entry.formula)
                    .truncationMode(.tail)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
            }
            .padding()
        }
        .widgetURL(widgetURL)
    }
}
