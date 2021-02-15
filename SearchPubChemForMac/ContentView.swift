//
//  ContentView.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData
import SceneKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: CompoundEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundEntity.firstCharacterInName, ascending: true)],
        animation: .default)
    private var items: FetchedResults<CompoundEntity>

    @State private var showSearchByNameView = false
    @State private var selected: CompoundEntity?
    
    private func geometryNode(conformers: NSSet?) -> SCNNode {
        guard let conformers = conformers else {
            return SCNNode()
        }
        
        let entity = conformers.allObjects.first as! ConformerEntity
        
        guard let atomEntities = entity.atoms?.allObjects as? Array<AtomEntity> else {
            return SCNNode()
        }
        
        let conformer = Conformer()
        conformer.conformerId = entity.conformerId!
        
        var atoms = Array<Atom>()
        for atomEntity in atomEntities {
            let atom = Atom()
            atom.number = Int(atomEntity.atomicNumber)
            atom.location = [atomEntity.coordX, atomEntity.coordY, atomEntity.coordZ]
            atoms.append(atom)
        }
        
        conformer.atoms = atoms
        print("conformer = \(conformer)")
        return GeometryGenerator.generate(from: conformer)
    }
    
    @State private var showingDetail = false
    var body: some View {
        HStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(200)), count: 3)) {
                    ForEach(items) { item in
                        VStack {
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
                            .onTapGesture {
                                print("\(geometryNode(conformers: item.conformers))")
                                self.selected = item
                                self.showingDetail = true
                            }
                            .sheet(isPresented: $showingDetail) {
                                ConformerView(geometryNode: geometryNode(conformers: selected != nil ? selected!.conformers! : items[0].conformers!), presenting: $showingDetail)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
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
