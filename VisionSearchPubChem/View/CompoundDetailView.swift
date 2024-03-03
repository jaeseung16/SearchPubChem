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
            VStack {
                HStack {
                    Text("Formula: \(compound.formula ?? "")")
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("Molecular Weight (gram/mol): \(molecularWeightFormatter.string(from: NSNumber(value: compound.molecularWeight)) ?? "Unknown")")
                        .font(.callout)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    
                    if let imageData = compound.image, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Text("N/A")
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    
                    if conformer != nil {
                        Toggle(isOn: $presentConformer) {
                            Text("3D")
                        }
                        .toggleStyle(.button)
                    }
                    
                    Spacer()
                }
                .onChange(of: presentConformer) { oldValue, newValue in
                    viewModel.isConformerViewOpen = newValue
                    if newValue {
                        openWindow(id: WindowId.conformer.rawValue)
                    } else {
                        dismissWindow(id: WindowId.conformer.rawValue)
                    }
                }
                .onChange(of: viewModel.isConformerViewOpen) { oldValue, newValue in
                    if oldValue && !newValue {
                        presentConformer = false
                    }
                }
                    
                HStack(alignment: .top) {
                    VStack {
                        ForEach(tags) { tag in
                            Text(tag.name ?? "")
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }

                Spacer()
                
                HStack {
                    Text("PubChem CID: \(compound.cid ?? "")")
                        .font(.callout)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Text("IUPAC Name: \(compound.nameIUPAC ?? "")")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .scaledToFit()
                    
                    Spacer()
                }
            }
            .padding()
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
        }
        .toolbar {
            HStack {
                if let urlForPubChem {
                    Link(destination: urlForPubChem) {
                        Image(systemName: "link")
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
        .navigationTitle(Text(compound.name ?? ""))
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
    
    private func delete() -> Void {
        viewModel.delete(compound: compound)
        presentationMode.wrappedValue.dismiss()
    }
    
}

