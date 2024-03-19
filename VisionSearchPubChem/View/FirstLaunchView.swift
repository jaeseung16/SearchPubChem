//
//  FirstLaunchView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/17/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FirstLaunchView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    private let hasLaunchedBeforeKey = "HasLaunchedBefore"
    private let hasDBMigratedKey = "HasDBMigrated"
    private let welcomeToSearchPubChem = "Welcome to SearchPubChem!"
    private let wantToAddSomeExamples = "Would you like to add some example compounds?"
    private let iPadIntro = "iPad_Intro"
    private let scale = SIMD3<Float>(0.5, 0.5, 0.5)
    
    @State private var waterEntity: Entity?
    @State private var ammoniaEntity: Entity?
    @State private var methaneEntity: Entity?
    
    private let waterPosition = SIMD3<Float>(0.0, 0.1, 0.0)
    private let ammoniaPosition = SIMD3<Float>(0.12, -0.12, 0.0)
    private let methanePosition = SIMD3<Float>(-0.12, -0.12, 0.0)
    
    private let waterRotationAxis = SIMD3<Float>(1.0, 1.0, 0.0)
    private let ammoniaRotationAxis = SIMD3<Float>(1.0, 0.0, 0.0)
    private let methaneRotationAxis = SIMD3<Float>(0.0, 1.0, 0.0)
    
    private let waterDuration = 2.0
    private let ammoniaDuration = 2.5
    private let methaneDuration = 3.0
    
    var body: some View {
        GeometryReader3D { geometry in
            ZStack {
                RealityView { content in
                    guard let water = await RealityKitContent.entity(named: "Water") else {
                        return
                    }
                    
                    water.setScale(scale, relativeTo: nil)
                    water.setPosition(waterPosition, relativeTo: nil)
                    
                    if let resource = createAnimationResource(position: waterPosition, axis: waterRotationAxis, duration: waterDuration) {
                        water.playAnimation(resource.repeat())
                    }
                    
                    content.add(water)
                    
                    waterEntity = water
                    
                    guard let ammonia = await RealityKitContent.entity(named: "Ammonia") else {
                        return
                    }
                    
                    ammonia.setScale(scale, relativeTo: nil)
                    ammonia.setPosition(ammoniaPosition, relativeTo: nil)
                    
                    if let resource = createAnimationResource(position: ammoniaPosition, axis: ammoniaRotationAxis, duration: ammoniaDuration) {
                        ammonia.playAnimation(resource.repeat())
                    }
                    
                    content.add(ammonia)
                    
                    ammoniaEntity = ammonia
                    
                    guard let methane = await RealityKitContent.entity(named: "Methane") else {
                        return
                    }
                    
                    methane.setScale(scale, relativeTo: nil)
                    methane.setPosition(methanePosition, relativeTo: nil)
                    
                    if let resource = createAnimationResource(position: methanePosition, axis: methaneRotationAxis, duration: methaneDuration) {
                        methane.playAnimation(resource.repeat())
                    }
                    
                    content.add(methane)
                    
                    methaneEntity = methane
                    
                }
                
                VStack {
                    Text(welcomeToSearchPubChem)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(wantToAddSomeExamples)
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text(Action.No.rawValue)
                        }
                        
                        Spacer()
                        
                        Button {
                            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
                            viewModel.preloadData()
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text(Action.Yes.rawValue)
                        }
                        
                        Spacer()
                    }
                }
                
            }
            .padding()
        }
    }
    
    private func createAnimationResource(position: SIMD3<Float>, axis: SIMD3<Float>, duration: TimeInterval) -> AnimationResource? {
        let transform1 = Transform(scale: scale,
                                   rotation: .init(angle: 2.0 * .pi, axis: axis),
                                   translation: position)
        let transform2 = Transform(scale: scale,
                                   rotation: .init(angle: .pi, axis: axis),
                                   translation: position)
        
        let animation1 = FromToByAnimation(to: transform2,
                                           duration: duration,
                                           timing: .linear,
                                           bindTarget: .transform)
        let animation2 = FromToByAnimation(from: transform2,
                                           to: transform1,
                                           duration: duration,
                                           timing: .linear,
                                           bindTarget: .transform)
        
        if let animationResource1 = try? AnimationResource.generate(with: animation1),
           let animationResource2 = try? AnimationResource.generate(with: animation2),
           let resource = try? AnimationResource.sequence(with: [animationResource1, animationResource2]) {
            return resource
        } else {
            return nil
        }
    }

}
