//
//  SolutionDetailView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SolutionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    var solution: Solution
    
    @State private var absoluteRelative: AbsoluteRelatve = .absolute
    @State private var unit: Unit = .gram
    @State private var presentCompoundMiniDetailView = false
    @State private var presentShareSheet = false
    @State private var presentAlert = false
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter
    }
    
    private var ingradients: [SolutionIngradientDTO] {
        var ingradients = [SolutionIngradientDTO]()
        solution.ingradients?.forEach { entity in
            if let entity = entity as? SolutionIngradient {
                if let compound = entity.compound, let unitRawValue = entity.unit, let unit = Unit(rawValue: unitRawValue) {
                    let dto = SolutionIngradientDTO(compound: compound, amount: entity.amount, unit: unit)
                    ingradients.append(dto)
                }
            }
        }
        return ingradients
    }
    
    private var compounds: [Compound] {
        var compounds = [Compound]()
        solution.ingradients?.forEach({ ingradient in
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound {
                compounds.append(compound)
            }
        })
        return compounds
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(solution.name?.uppercased() ?? "")
                    .font(.headline)
                
                Text("Created on " + dateFormatter.string(from: solution.created ?? Date()))
                    .font(.caption)
                    
                Divider()
                
                columnHeads(geometry: geometry)
                
                ingradientList()
            }
            .toolbar {
                toolbarContent()
            }
            .sheet(isPresented: $presentShareSheet) {
                if let name = solution.name, let date = solution.created, let url = viewModel.generateCSV(solutionName: name, created: date, ingradients: ingradients) {
                    ShareActivityView(url: url, applicationActivities: nil, failedToRemoveItem: $presentAlert)
                }
            }
            .alert(isPresented: $presentAlert, content: {
                Alert(title: Text("Failed to remove files"),
                      message: Text("Files generated for \(solution.name ?? "") couldn't be deleted from the document directory"),
                      dismissButton: .default(Text(Action.Dismiss.rawValue)))
            })
        }
        .padding()
    }
    
    private func columnHeads(geometry: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            Spacer()
            
            Text("Ingradients")
                .frame(width: geometry.size.width * 0.4)
            
            Spacer()
            
            VStack {
                Text("Amount")

                Picker("", selection: $absoluteRelative) {
                    ForEach(AbsoluteRelatve.allCases) { item in
                        Text(item.rawValue)
                            .tag(item)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                HStack {
                    Spacer()
                    
                    Text("UNIT:")
                        .font(.caption)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(Unit.allCases) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width * 0.4)
            
            Spacer()
        }
    }
    
    private func ingradientList() -> some View {
        List {
            ForEach(ingradients) { ingradient in
                Button {
                    presentCompoundMiniDetailView = true
                } label: {
                    if let name = ingradient.compound.name {
                        HStack {
                            Text(name)
                            
                            Spacer()
                            
                            if let amount = amountsToDisplay[name] {
                                Text("\(amount)")
                            }
                        }
                    }
                }
                .sheet(isPresented: $presentCompoundMiniDetailView) {
                    CompoundMiniDetailView(compound: ingradient.compound)
                }
            }
        }
        .listStyle(PlainListStyle())
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
        var factor = 1.0
        if absoluteRelative == .relative {
            switch unit {
            case .gram:
                factor = 100.0 / sum(of: amounts)
            case .mg:
                factor = 100.0 / sum(of: amountsInMg)
            case .mol:
                factor = 100.0 / sum(of: amountsMol)
            case .mM:
                factor = 100.0 / sum(of: amountsInMiliMol)
            }
        }
        
        var amountsToDisplay = [String: Double]()
        
        switch unit {
        case .gram:
            for name in amounts.keys {
                if let amount = amounts[name] {
                    amountsToDisplay[name] = amount * factor
                }
            }
        case .mg:
            for name in amounts.keys {
                if let amountsInMg = amountsInMg[name] {
                    amountsToDisplay[name] = amountsInMg * factor
                }
            }
        case .mol:
            for name in amountsMol.keys {
                if let amountMol = amountsMol[name] {
                    amountsToDisplay[name] = amountMol * factor
                }
            }
        case .mM:
            for name in amountsMol.keys {
                if let amountsInMiliMol = amountsInMiliMol[name] {
                    amountsToDisplay[name] = amountsInMiliMol * factor
                }
            }
        }
        
        return amountsToDisplay
    }
    
    private func sum(of amounts: [String: Double]) -> Double {
        return amounts.values.reduce(0.0, { x, y in x + y })
    }
    
    private func delete() -> Void {
        if let compounds = solution.compounds {
            for compound in compounds {
                if let compound = compound as? Compound {
                    compound.removeFromSolutions(solution)
                }
            }
        }
        
        viewContext.delete(solution)
        
        viewModel.save(viewContext: viewContext) { _ in
            
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
}
