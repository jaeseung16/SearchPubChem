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
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @State var compound: Compound
    @State private var presentConformer = false
    @State private var presentTagView = false
    
    private let maxHeightFactor = 0.6
    private let maxWidthFactor = 0.95
    
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
            HStack {
                VStack {
                    if let imageData = compound.image, let image = UIImage(data: imageData) {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    
                    Spacer()
                    
                    if conformer != nil {
                        Toggle(isOn: $presentConformer) {
                            Text("3D")
                        }
                        .toggleStyle(.button)
                        .onChange(of: presentConformer) { _, newValue in
                            if viewModel.isConformerViewOpen != newValue {
                                viewModel.isConformerViewOpen = newValue
                                if newValue {
                                    openWindow(id: WindowId.conformer.rawValue)
                                } else {
                                    dismissWindow(id: WindowId.conformer.rawValue)
                                }
                            }
                        }
                        .onChange(of: viewModel.isConformerViewOpen) { oldValue, newValue in
                            if oldValue && !newValue {
                                presentConformer = false
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 0.5 * geometry.size.width)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Formula")
                                .foregroundColor(.secondary)
                            
                            Text("\(compound.formula ?? "")")
                                .foregroundColor(.primary)
                        }
                        
                        GridRow {
                            Text("Molecular Weight")
                                .foregroundColor(.secondary)
                            
                            Text("\(molecularWeightFormatter.string(from: NSNumber(value: compound.molecularWeight)) ?? "Unknown") gram/mol")
                                .foregroundColor(.primary)
                        }
                        
                        GridRow {
                            Text("PubChem CID")
                                .foregroundColor(.secondary)
                            
                            Text("\(compound.cid ?? "")")
                                .foregroundColor(.primary)
                        }
                        
                        GridRow(alignment: .top) {
                            Text("IUPAC Name")
                                .foregroundColor(.secondary)
                            
                            Text("\(compound.nameIUPAC ?? "")")
                                .foregroundColor(.primary)
                        }
                        
                        GridRow(alignment: .top) {
                            Button {
                                presentTagView = true
                            } label: {
                                Label {
                                    Text("Tags")
                                        .foregroundColor(.secondary)
                                } icon: {
                                    Image(systemName: "tag.circle")
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(tags.compactMap {$0.name}.joined(separator: ", "))")
                                .foregroundColor(.primary)
                        }
                        .sheet(isPresented: $presentTagView) {
                            CompoundTagView(compound: compound, tags: compound.tags as? Set<CompoundTag>)
                                .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 0.5 * geometry.size.width, alignment: .leading)
                
            }
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if let urlForPubChem {
                    Link(destination: urlForPubChem) {
                        Image(systemName: "link")
                    }
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    delete()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(compound.solutions != nil && compound.solutions!.count > 0)
            }
        }
        .navigationTitle(Text(compound.name ?? ""))
        .padding()
        .onAppear {
            if !presentConformer && viewModel.isConformerViewOpen {
                presentConformer = true
            }
        }
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
    
    private func delete() -> Void {
        viewModel.delete(compound: compound)
        presentationMode.wrappedValue.dismiss()
    }
    
}

