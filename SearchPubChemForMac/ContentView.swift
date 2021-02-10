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
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundEntity.firstCharacterInName, ascending: true)],
        animation: .default)
    private var items: FetchedResults<CompoundEntity>

    @State private var showSearchByNameView = false
    
    var body: some View {
        List {
            ForEach(items) { item in
                Text("Item at \(item.created!, formatter: itemFormatter)")
                Text("Name \(item.name ?? "")")
                Text("Formula \(item.formula ?? "")")
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            Button(action: { self.showSearchByNameView = true }) {
                Label("Add Item", systemImage: "plus")
            }
            .sheet(isPresented: $showSearchByNameView, content: {
                SearchByNameView(presenting: $showSearchByNameView)
            })
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = CompoundEntity(context: viewContext)
            newItem.created = Date()

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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
