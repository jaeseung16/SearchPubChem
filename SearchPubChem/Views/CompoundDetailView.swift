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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State var compound: Compound
    @State private var presentConformerView = false
    @State private var presentTagView = false
    
    private let imageScaleFactor = 0.6
    
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
            for conformerEntity in conformers {
                if let entity = conformerEntity as? ConformerEntity {
                    var atoms = [AtomEntity]()
                    entity.atoms?.forEach({ atom in
                        if let atom = atom as? AtomEntity {
                            atoms.append(atom)
                        }
                    })
                    
                    return Conformer(cid: compound.cid ?? "", conformerEntity: entity, atomEntities: atoms)
                }
            }
        }
        return nil
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
                Group {
                    ZStack(alignment: .top) {
                        HStack {
                            tagListView()
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            formulaAndWeight()
                            Spacer()
                        }
                        
                        if conformer != nil {
                            HStack {
                                Spacer()
                                conformerButton()
                            }
                        }
                    }
                    .padding(5)
                    .frame(maxWidth: 0.9 * geometry.size.width)
                    
                    if let imageData = compound.image, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: maxImageLength(in: geometry), maxHeight: maxImageLength(in: geometry))
                    } else {
                        Text("N/A")
                    }
                    
                    cidANDIUPAC()
                        .frame(maxWidth: 0.9 * geometry.size.width)

                }
                
                solutionListView()
                    .background {
                        Color(UIColor.systemBackground)
                    }
            }
            .background {
                Color(red: 0.95, green: 0.95, blue: 0.95)
            }
        }
        .sheet(isPresented: $presentConformerView) {
            if let conformer = conformer {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ConformerView(scene: viewModel.makeScene(conformer), name: compound.name ?? "", molecularFormula: compound.formula ?? "")
                } else {
                    ConformerSceneView(scene: viewModel.makeScene(conformer), name: compound.name ?? "", molecularFormula: compound.formula ?? "")
                }
            }
        }
        .sheet(isPresented: $presentTagView) {
            CompoundTagView(compound: compound, tags: compound.tags as? Set<CompoundTag>)
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
    
    private func maxImageLength(in geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width > geometry.size.height ? 0.6 * geometry.size.height : 0.7 * geometry.size.width
    }
    
    private var molecularWeightFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 10
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 4
        return formatter
    }
    
    private func cidANDIUPAC() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("PubChem CID:")
                Text("IUPAC Name:")
            }
            
            VStack(alignment: .leading) {
                Text("\(compound.cid ?? "")")
                Text("\(compound.nameIUPAC ?? "")")
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .font(.callout)
        .foregroundColor(.black)
    }
    
    private func tagListView() -> some View {
        VStack {
            ForEach(tags) { tag in
                Text(tag.name ?? "")
                    .foregroundColor(.black)
            }
        }
    }
    
    private func formulaAndWeight() -> some View {
        VStack {
            Text(compound.formula ?? "")
                .foregroundColor(.black)
            Text("\(molecularWeightFormatter.string(from: NSNumber(value: compound.molecularWeight)) ?? "0.0") gram/mol")
                .font(.callout)
                .foregroundColor(.black)
        }
    }
    
    private func conformerButton() -> some View {
        Button {
            presentConformerView = true
        } label: {
            Label("3D", systemImage: "rotate.3d")
                .padding(10)
        }
        .foregroundColor(.primary)
        .glassEffect()
    }
    
    private func delete() -> Void {
        viewModel.delete(compound: compound)
        dismiss.callAsFunction()
    }
    
    private func solutionListView() -> some View {
        VStack {
            Spacer(minLength: 10)
            
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
                                .id(solution)
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
}

