//
//  MakeSolutionView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct MakeSolutionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
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
                        .background(RoundedRectangle(cornerRadius: 5.0)
                                        .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                } else {
                    TextField("", text: $solutionLabel)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.center)
                        .background(RoundedRectangle(cornerRadius: 5.0)
                                        .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                }
            }
            
            Button {
                presentSelectCompoundsView = true
            } label: {
                Text("Add compounds")
            }
            
            if !ingradients.isEmpty {
                List {
                    ForEach(0..<ingradients.count, id:\.self) { index in
                        HStack {
                            if let compound = ingradients[index].compound {
                                Text(compound.name ?? "")
                            }
    
                            Spacer()
                            
                            TextField("0.0", value: $ingradients[index].amount, formatter: numberFormatter)
                                .multilineTextAlignment(.trailing)
                                .background(RoundedRectangle(cornerRadius: 5.0)
                                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                                .frame(maxWidth: 100.0)
                                .keyboardType(.decimalPad)
                            
                            Picker("", selection: $ingradients[index].unit) {
                                ForEach(Unit.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 50.0)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(viewModel.$compounds) { compounds in
            compounds?.forEach { compound in
                let ingradient = SolutionIngradientDTO(compound: compound, amount: 0.0, unit: .gram)
                ingradients.append(ingradient)
            }
        }
        .sheet(isPresented: $presentSelectCompoundsView) {
            SelectCompoundsView(selectedCompounds: selectedCompounds)
                .environmentObject(viewModel)
        }
    }
    
    private func header() -> some View {
        ZStack {
            Text("Make a solution")
            
            HStack {
                Button {
                    viewModel.compounds = nil
                    viewModel.solutionLabel = ""
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }
                
                Spacer()
                
                Button {
                    let solution = Solution(context: viewContext)
                    solution.name = solutionLabel.isEmpty ? viewModel.solutionLabel : solutionLabel
                    
                    for ingradient in ingradients {
                        print("ingradient = \(ingradient)")
                        let entity = SolutionIngradient(context: viewContext)
                        
                        entity.compound = ingradient.compound
                        entity.compoundName = ingradient.compound.name
                        entity.compoundCid = ingradient.compound.cid
                        entity.amount = ingradient.amount
                        entity.unit = ingradient.unit.rawValue
                        
                        solution.addToIngradients(entity)
                        solution.addToCompounds(ingradient.compound)
                    }
                    
                    do {
                        try viewContext.save()
                    } catch {
                        NSLog("Error while saving by AppDelegate")
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Save")
                }
            }
        }
    }
}
