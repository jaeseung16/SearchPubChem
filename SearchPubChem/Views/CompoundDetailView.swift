//
//  CompoundDetailView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct CompoundDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State var compound: Compound
    @State private var presentConformerView = false
    @State private var presentTagView = false
    
    private let maxHeightFactor = 0.6
    private let maxWidthFactor = 0.95
    
    private var solutions: [Solution] {
        var solutions = [Solution]()
        compound.solutions?.forEach { solution in
            if let solution = solution as? Solution {
                solutions.append(solution)
            }
        }
        return solutions
    }
    
    private var tags: [CompoundTag] {
        var tags = [CompoundTag]()
        compound.tags?.forEach { tag in
            if let tag = tag as? CompoundTag {
                tags.append(tag)
            }
        }
        return tags
    }
    
    private var conformer: Conformer? {
        guard compound.conformerDownloaded else {
            return nil
        }
        
        if let conformers = compound.conformers, conformers.count > 0 {
            print("conformers = \(conformers)")
            for conformerEntity in conformers {
                if let entity = conformerEntity as? ConformerEntity {
                    var atoms = [AtomEntity]()
                    entity.atoms?.forEach({ atom in
                        if let atom = atom as? AtomEntity {
                            atoms.append(atom)
                        }
                    })
                    
                    return populateConformer(for: entity, with: atoms)
                }
            }
        }
        return nil
    }
    
    private func populateConformer(for conformerEntity: ConformerEntity, with atomEntities: [AtomEntity]) -> Conformer {
        let conformer = Conformer()
        conformer.cid = compound.cid ?? ""
        conformer.conformerId = conformerEntity.conformerId ?? ""
        
        conformer.atoms = [Atom]()
        for atomEntity in atomEntities {
            let atom = Atom()
            atom.number = Int(atomEntity.atomicNumber)
            atom.location = [atomEntity.coordX, atomEntity.coordY, atomEntity.coordZ]
            
            conformer.atoms.append(atom)
        }
        return conformer
    }
    
    private var urlForPubChem: URL? {
        guard let cid = compound.cid else {
            return nil
        }
        
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForWeb + "\(cid)"
        
        return component.url
    }
    
    private func commonURLComponents() -> URLComponents {
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        
        return component
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    if let imageData = compound.image, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Text("N/A")
                    }
                    
                    info()
                }
                .frame(maxWidth: maxWidthFactor * geometry.size.width, minHeight: determineMinHeight(in: geometry), maxHeight: maxHeightFactor * geometry.size.height)
                .scaledToFit()
                
                Divider()
                
                HStack {
                    Text("SOLUTIONS")
                        .bold()
                    Spacer()
                }
                
                List {
                    ForEach(solutions) { solution in
                        HStack {
                            NavigationLink {
                                SolutionDetailView(solution: solution)
                            } label: {
                                Text(solution.name ?? "")
                                Spacer()
                                Text(solution.created ?? Date(), style: .date)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $presentConformerView) {
            if let conformer = conformer {
                ConformerView(conformer: conformer, name: compound.name ?? "", formula: compound.formula ?? "")
            }
        }
        .sheet(isPresented: $presentTagView) {
            CompoundTagView(compound: compound, tags: compound.tags as? Set<CompoundTag>)
                .environment(\.managedObjectContext, viewContext)
        }
        .toolbar {
            HStack {
                Button {
                    presentTagView = true
                } label : {
                    Image(systemName: "tag")
                }
                
                if urlForPubChem != nil {
                    Link(destination: urlForPubChem!) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                Button {
                    delete()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(compound.solutions != nil && compound.solutions!.count > 0)
            }
        }
        .navigationTitle(Text(compound.name?.uppercased() ?? ""))
        .padding()
    }
    
    private func determineMinHeight(in geometry: GeometryProxy) -> CGFloat {
        var factor = 10.0 * geometry.size.width / geometry.size.height
        factor.round(.towardZero)
        return factor < 6 ? 0.1 * CGFloat(factor) * geometry.size.height : maxHeightFactor * geometry.size.height
    }
    
    private var molecularWeightFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 10
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 4
        return formatter
    }
    
    private func info() -> some View {
        VStack {
            ZStack(alignment: .top) {
                HStack {
                    ForEach(tags) { tag in
                        Text(tag.name ?? "")
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    if conformer != nil {
                        Button {
                            presentConformerView = true
                        } label: {
                            Text("3D")
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack {
                        Text(compound.formula ?? "")
                            .foregroundColor(.black)
                        Text("\(molecularWeightFormatter.string(from: NSNumber(value: compound.molecularWeight)) ?? "0.0") gram/mol")
                            .font(.callout)
                            .foregroundColor(.black)
                    }
                    Spacer()
}
            }
            
            Spacer()
            
            VStack {
                Text("PubChem CID: \(compound.cid ?? "")")
                    .font(.callout)
                    .foregroundColor(.black)
                Text("IUPAC Name: \(compound.nameIUPAC ?? "")")
                    .font(.callout)
                    .foregroundColor(.black)
                    .scaledToFit()
            }
        }
    }
    
    private func delete() -> Void {
        if let tags = compound.tags {
            for tag in tags {
                if let compoundTag = tag as? CompoundTag {
                    compoundTag.removeFromCompounds(compound)
                    compoundTag.compoundCount -= 1
                }
            }
        }
        
        viewContext.delete(compound)
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving: \(error.localizedDescription)")
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
}

