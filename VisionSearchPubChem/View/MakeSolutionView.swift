//
//  MakeSolutionView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/11/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct MakeSolutionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @State private var solutionLabel = ""
    @State private var presentSelectCompoundsView = false
    @State private var selectedCompounds = [Compound]()
    
    @State private var ingradients = [SolutionIngradientDTO]()
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 10
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 10
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                HStack {
                    Text("Solution Label")
                    
                    Spacer()
                    
                    if !viewModel.solutionLabel.isEmpty {
                        TextField("", text: $viewModel.solutionLabel)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                    } else {
                        TextField("", text: $solutionLabel)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 35)
                
                Button {
                    presentSelectCompoundsView = true
                } label: {
                    Text("Add compounds")
                }
                .accessibilityIdentifier("addCompoundsButton")
                
                if !ingradients.isEmpty {
                    ingradientList(geometry: geometry)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onReceive(viewModel.$compounds) { compounds in
                if let compounds = compounds {
                    var compoundsToAdd = [Compound]()
                    var compoundsToRemove = [Compound]()
                    
                    compounds.forEach { compound in
                        if !selectedCompounds.contains(compound) {
                            compoundsToAdd.append(compound)
                        }
                    }
                    
                    selectedCompounds.forEach { compound in
                        if !compounds.contains(compound) {
                            compoundsToRemove.append(compound)
                        }
                    }
                    
                    compoundsToRemove.forEach { compound in
                        if let index = selectedCompounds.firstIndex(of: compound) {
                            selectedCompounds.remove(at: index)
                        }
                        
                        if let index = ingradients.firstIndex(where: { $0.compound == compound }) {
                            ingradients.remove(at: index)
                        }
                    }
                    
                    compoundsToAdd.forEach { compound in
                        selectedCompounds.append(compound)
                        ingradients.append(SolutionIngradientDTO(compound: compound, amount: 0.0, unit: .gram))
                    }
                }
                
            }
            .sheet(isPresented: $presentSelectCompoundsView) {
                SelectCompoundsView(selectedCompounds: selectedCompounds)
                    .environmentObject(viewModel)
                    .frame(minWidth: 1.5 * geometry.size.width, minHeight: geometry.size.height)
            }
        }
    }
    
    private func header() -> some View {
        ZStack {
            Text("Make a solution")
            
            HStack {
                Button {
                    dissmiss()
                } label: {
                    Text(Action.Cancel.rawValue)
                }
                .accessibilityIdentifier("cancelMakeSolutionButton")
                
                Spacer()
                
                Button {
                    viewModel.saveSolution(solutionLabel: solutionLabel, ingradients: ingradients)
                    dissmiss()
                } label: {
                    Text(Action.Save.rawValue)
                }
            }
        }
    }
    
    private func dissmiss() -> Void {
        viewModel.compounds = nil
        viewModel.solutionLabel = ""
        presentationMode.wrappedValue.dismiss()
    }
    
    private func ingradientList(geometry: GeometryProxy) -> some View {
        List {
            ForEach(0..<ingradients.count, id:\.self) { index in
                HStack {
                    Text(ingradients[index].compound.name ?? "")
                        .multilineTextAlignment(.leading)

                    Spacer()
                    
                    TextField("0.0", value: $ingradients[index].amount, formatter: numberFormatter)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .frame(width: 0.25 * geometry.size.width)
                    
                    Picker("", selection: $ingradients[index].unit) {
                        ForEach(Unit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .frame(width: 0.25 * geometry.size.width)
                }
            }
        }
        
    }
}
