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
                    amounts[name] = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: unit, newUnit: .gram)
                }
            }
        }
        return amounts
    }
    
    private var amountsInMg: [String: Double] {
        var amountsInMg = [String: Double]()
        guard solution.ingradients != nil else {
            return amountsInMg
        }
        for ingradient in solution.ingradients! {
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound, let name = compound.name {
                if let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    amountsInMg[name] = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: unit, newUnit: .mg)
                }
            }
        }
        return amountsInMg
    }
    
    private var amountsMol: [String: Double] {
        var amountsMol = [String: Double]()
        guard solution.ingradients != nil else {
            return amountsMol
        }
        for ingradient in solution.ingradients! {
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound, let name = compound.name {
                if let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    amountsMol[name] = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: unit, newUnit: .mol)
                }
            }
        }
        return amountsMol
    }
    
    private var amountsInMiliMol: [String: Double] {
        var amountsInMiliMol = [String: Double]()
        guard solution.ingradients != nil else {
            return amountsInMiliMol
        }
        for ingradient in solution.ingradients! {
            if let ingradient = ingradient as? SolutionIngradient, let compound = ingradient.compound, let name = compound.name {
                if let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    amountsInMiliMol[name] = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: unit, newUnit: .mM)
                }
            }
        }
        return amountsInMiliMol
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
            .sheet(isPresented: $presentShareSheet) {
                if let url = prepareCSV(), let name = solution.name {
                    let title = "Sharing \(name).csv"
                    ShareActivityView(title: title, url: url, applicationActivities: nil)
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
            case .mg:
                factor = 100.0 / sumOf(amountsInMg)
            case .mol:
                factor = 100.0 / sumOf(amountsMol)
            case .mM:
                factor = 100.0 / sumOf(amountsInMiliMol)
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
    
    private func prepareCSV() -> URL? {
        let csvString = buildStringForCSV()

        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let filename = solution.name!.replacingOccurrences(of: "/", with: "-")
        let csvFileURL = path.appendingPathComponent("\(filename).csv")
        
        do {
            try csvString.write(to: csvFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save the csv file")
        }
        
        return csvFileURL
    }
    
    private func buildStringForCSV() -> String {
        var csvString = "CID, Compound, Molecular Weight (gram/mol), Amount (g), Amount (mol)\n"
        
        for ingradient in ingradients {
            let compound = ingradient.compound
            
            csvString += "\(compound.cid!), "
            csvString += "\(compound.name!), "
            csvString += "\(compound.molecularWeight), "
            
            let amountInGram = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: ingradient.unit, newUnit: .gram)
            let amountInMol = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: ingradient.unit, newUnit: .mol)
            
            csvString += "\(amountInGram), "
            csvString += "\(amountInMol)\n"
        }
        
        return csvString
    }
    
    private func convert(_ amount: Double, molecularWeight: Double, originalUnit: Unit, newUnit: Unit) -> Double {
        var convertedAmount = amount
        switch originalUnit {
        case .gram:
            switch newUnit {
            case .gram:
                convertedAmount = amount
            case .mg:
                convertedAmount = 1000.0 * amount
            case .mol:
                convertedAmount = amount / molecularWeight
            case .mM:
                convertedAmount = 1000.0 * amount / molecularWeight
            }
        case .mg:
            switch newUnit {
            case .gram:
                convertedAmount = amount / 1000.0
            case .mg:
                convertedAmount = amount
            case .mol:
                convertedAmount = amount / 1000.0 / molecularWeight
            case .mM:
                convertedAmount = amount / molecularWeight
            }
        case .mol:
            switch newUnit {
            case .gram:
                convertedAmount = amount * molecularWeight
            case .mg:
                convertedAmount = 1000.0 * amount * molecularWeight
            case .mol:
                convertedAmount = amount
            case .mM:
                convertedAmount = 1000.0 * amount
            }
        case .mM:
            switch newUnit {
            case .gram:
                convertedAmount = amount / 1000.0 * molecularWeight
            case .mg:
                convertedAmount = amount * molecularWeight
            case .mol:
                convertedAmount = amount / 1000.0
            case .mM:
                convertedAmount = amount
            }
        }
        return convertedAmount
    }
}
