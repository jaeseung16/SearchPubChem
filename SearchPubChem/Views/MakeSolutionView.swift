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
                        .roundedBackgroundRectangle()
                } else {
                    TextField("", text: $solutionLabel)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.center)
                        .roundedBackgroundRectangle()
                }
            }
            .frame(height: 35)
            
            Button {
                presentSelectCompoundsView = true
            } label: {
                Text("Add compounds")
            }
            
            if !ingradients.isEmpty {
                ingradientList()
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
    
    private func ingradientList() -> some View {
        List {
            ForEach(0..<ingradients.count, id:\.self) { index in
                HStack {
                    Text(ingradients[index].compound.name ?? "")

                    Spacer()
                    
                    TextField("0.0", value: $ingradients[index].amount, formatter: numberFormatter)
                        .multilineTextAlignment(.trailing)
                        .roundedBackgroundRectangle()
                        .frame(maxWidth: 100.0)
                        .keyboardType(.decimalPad)
                    
                    Picker("", selection: $ingradients[index].unit) {
                        ForEach(Unit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 80.0)
                }
            }
        }
    }
}
