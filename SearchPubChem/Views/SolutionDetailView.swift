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
    
    var solution: Solution
    
    @State private var absoluteRelative: AbsoluteRelatve = .absolute
    @State private var unit: Unit = .gram
    @State private var presentCompoundMiniDetailView = false
    
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
                    print("dto=\(dto)")
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
        var amounts = [String: Double]()
        guard solution.ingradients != nil else {
            return amounts
        }
        for ingradient in solution.ingradients! {
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound, let name = compound.name {
                if let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    switch unit {
                    case .gram:
                        amounts[name] = ingradient.amount
                    case .mol:
                        amounts[name] = ingradient.amount * compound.molecularWeight
                    }
                }
            }
        }
        return amounts
    }
    
    private var amountsMol: [String: Double] {
        var amountsMol = [String: Double]()
        guard solution.ingradients != nil else {
            return amountsMol
        }
        for ingradient in solution.ingradients! {
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound, let name = compound.name {
                if let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    switch unit {
                    case .gram:
                        amountsMol[name] = ingradient.amount / compound.molecularWeight
                    case .mol:
                        amountsMol[name] = ingradient.amount
                    }
                }
            }
        }
        return amountsMol
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(solution.name?.uppercased() ?? "")
                    .font(.headline)
                
                Text("Created on " + dateFormatter.string(from: solution.created ?? Date()))
                    .font(.caption)
                    
                Divider()
                
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

                        Picker("", selection: $unit) {
                            ForEach(Unit.allCases) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .frame(width: geometry.size.width * 0.4)
                    
                    Spacer()
                }
                
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
            .toolbar {
                Button {
                    delete()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .padding()
    }
    
    private var amountsToDisplay: [String: Double] {
        var factor = 1.0
        if absoluteRelative == .relative {
            switch unit {
            case .gram:
                factor = 100.0 / sumOf(amounts)
            case .mol:
                factor = 100.0 / sumOf(amountsMol)
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
        case .mol:
            for name in amountsMol.keys {
                if let amountMol = amountsMol[name] {
                    amountsToDisplay[name] = amountMol * factor
                }
            }
        }
        
        return amountsToDisplay
    }
    
    private func sumOf(_ amounts: [String: Double]) -> Double {
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
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving: \(error.localizedDescription)")
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

enum AbsoluteRelatve: String, CaseIterable, Identifiable {
    case absolute = "actual"
    case relative = "%"
    
    var id: String {
        self.rawValue
    }
}

enum Unit: String, CaseIterable, Identifiable {
    case gram
    case mol
    
    var id: String {
        self.rawValue
    }
}
