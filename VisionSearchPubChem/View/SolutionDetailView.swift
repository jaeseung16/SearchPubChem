//
//  SolutionDetailView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/11/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SolutionDetailView: View {
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @Binding var solution: Solution?
    
    @State private var absoluteRelative: AbsoluteRelatve = .absolute
    @State private var unit: Unit = .gram
    @State private var presentCompoundMiniDetailView = false
    @State private var presentShareSheet = false
    @State private var presentAlert = false
    
    private var ingradients: [SolutionIngradientDTO] {
        var ingradients = [SolutionIngradientDTO]()
        solution?.ingradients?.forEach { entity in
            if let entity = entity as? SolutionIngradient {
                if let compound = entity.compound, let unitRawValue = entity.unit, let unit = Unit(rawValue: unitRawValue) {
                    let dto = SolutionIngradientDTO(compound: compound, amount: entity.amount, unit: unit)
                    ingradients.append(dto)
                }
            }
        }
        return ingradients
    }
    
    private var amounts: [String: Double] {
        return getAmounts(in: .gram)
    }
    
    private var amountsInMg: [String: Double] {
        return getAmounts(in: .mg)
    }
    
    private var amountsMol: [String: Double] {
        return getAmounts(in: .mol)
    }
    
    private var amountsInMiliMol: [String: Double] {
        return getAmounts(in: .mM)
    }
    
    private func getAmounts(in unit: Unit) -> [String: Double] {
        return viewModel.getAmounts(of: ingradients, in: unit)
    }
    
    @State private var compound: Compound?
    @State private var selectedIngradient: SolutionIngradientDTO.ID?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(solution?.name?.uppercased() ?? "")
                    .font(.headline)
                
                created(on: solution?.created ?? Date())
                    .font(.caption)
                
                Divider()
                
                optionSelector(geometry: geometry)
                
                Table(ingradients, selection: $selectedIngradient) {
                    TableColumn("Ingradient") { ingradient in
                        Text("\(ingradient.compound.name ?? "")")
                    }
                    TableColumn("Amount") { ingradient in
                        if let name = ingradient.compound.name, let amount = amountsToDisplay[name] {
                            Text("\(amount)")
                        } else {
                            Text("")
                        }
                    }
                    TableColumn("%") { ingradient in
                        if let name = ingradient.compound.name, let amount = percentToDisplay[name] {
                            Text("\(amount)")
                        } else {
                            Text("")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        presentShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        delete()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(isPresented: $presentCompoundMiniDetailView) {
                if let compound = compound {
                    IngredientDetailView(compound: compound)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                }
            }
            .sheet(isPresented: $presentShareSheet) {
                if let name = solution?.name, let date = solution?.created, let url = viewModel.generateCSV(solutionName: name, created: date, ingradients: ingradients) {
                    ShareActivityView(url: url, applicationActivities: nil, failedToRemoveItem: $presentAlert)
                }
            }
            .alert(isPresented: $presentAlert) {
                Alert(title: Text("Failed to remove files"),
                      message: Text("Files generated for \(solution?.name ?? "") couldn't be deleted from the document directory"),
                      dismissButton: .default(Text(Action.Dismiss.rawValue)))
            }
            .onChange(of: selectedIngradient) { oldValue, newValue in
                if newValue != nil, let ingradient = ingradients.first(where: {$0.id == newValue!}) {
                    compound = ingradient.compound
                }
            }
            .onChange(of: compound) { oldValue, newValue in
                if newValue != nil {
                    presentCompoundMiniDetailView = true
                }
            }
            .onChange(of: presentCompoundMiniDetailView) { oldValue, newValue in
                if !newValue {
                    selectedIngradient = nil
                }
            }
        }
        .padding()
    }
    
    private func created(on date: Date) -> some View {
        Text("Created on ") + Text(date, style: .date)
    }
    
    private func optionSelector(geometry: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            Spacer()
            
            Text("UNIT:")
                .font(.caption)
            
            Picker("Unit", selection: $unit) {
                ForEach(Unit.allCases) { item in
                    Text(item.rawValue)
                        .tag(item)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private func toolbarContent() -> some View {
        HStack {
            Button {
                presentShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            
            Button {
                delete()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
    
    private var amountsToDisplay: [String: Double] {
        var amountsToDisplay = [String: Double]()
        
        switch unit {
        case .gram:
            amountsToDisplay = amounts
        case .mg:
            amountsToDisplay = amountsInMg
        case .mol:
            amountsToDisplay = amountsMol
        case .mM:
            amountsToDisplay = amountsInMiliMol
        }
        
        return amountsToDisplay
    }
    
    private var percentToDisplay: [String: Double] {
        var amountsToDisplay = [String: Double]()
        
        switch unit {
        case .gram:
            let factor = 100.0 / total(amounts)
            amountsToDisplay = amounts.mapValues { $0 * factor }
        case .mg:
            let factor = 100.0 / total(amountsInMg)
            amountsToDisplay = amountsInMg.mapValues { $0 * factor }
        case .mol:
            let factor = 100.0 / total(amountsMol)
            amountsToDisplay = amountsMol.mapValues { $0 * factor }
        case .mM:
            let factor = 100.0 / total(amountsInMiliMol)
            amountsToDisplay = amountsInMiliMol.mapValues { $0 * factor }
        }
        
        return amountsToDisplay
    }
    
    private func total(_ amounts: [String: Double]) -> Double {
        return amounts.values.reduce(0.0, { x, y in x + y })
    }
    
    private func delete() -> Void {
        if let solution {
            solution.compounds?.forEach { compound in
                if let compound = compound as? Compound {
                    compound.removeFromSolutions(solution)
                }
            }
            
            viewModel.delete(solution)
            
            viewModel.save()
            
            self.solution = nil
        }
    }
    
}
