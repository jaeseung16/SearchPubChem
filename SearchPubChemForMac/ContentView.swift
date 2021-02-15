//
//  ContentView.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: CompoundEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundEntity.firstCharacterInName, ascending: true)],
        animation: .default)
    private var items: FetchedResults<CompoundEntity>

    @State private var showSearchByNameView = false
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(200)), count: 3)) {
                ForEach(items) { item in
                    CompoundInfoView(
                        name: item.name ?? "",
                        formula: item.formula ?? "",
                        molecularWeight: item.molecularWeight,
                        cid: item.cid ?? "",
                        nameIUPAC: item.nameIUPAC ?? "",
                        added: item.created!,
                        image: item.image != nil ? NSImage(data: item.image!)! : NSImage(named: "water")!
                    )
                    .frame(width: 250, height: 250, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .toolbar {
            Button(action: { self.showSearchByNameView = true }) {
                Label("Add Item", systemImage: "plus")
            }
            .sheet(isPresented: $showSearchByNameView, content: {
                SearchByNameView(presenting: $showSearchByNameView)
                    .environment(\.managedObjectContext, self.viewContext)
            })
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
