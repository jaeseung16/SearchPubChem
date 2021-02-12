//
//  Elements.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/28/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import SwiftUI

enum Elements: Int {
    case hydrogen = 1, helium, lithium, berylium, boron, carbon, nitrogen, oxygen, fluorine, neon, sodium, magnesium, aluiminium, silicon, phosphorus, sulfur, chlorine, argon, potassium, calcium, scandium, titanium, vanadium, chromium, manganese, iron, cobalt, nickel, copper, zinc, gallium, germanium, arsenic, selenium, bromine, krypton, rubidium, strontium, yttrium, zirconium, niobium, molybdenum, technetium, ruthenium, rhodium, palladium, silver, cadmium, indium, tin, antimony, tellurium, iodine, xenon, caesium, barium, lanthanum, cerium, praseodymium, neodymium, promethium, samarium, europium, gadolinium, terbium, dysprosium, holmium, erbium, thulium, ytterbium, lutetium, hafnium, tantalum, tungsten, rhenium, osmium, iridium, platinum, gold, mercury, thallium, lead, bismuth, polonium, astatine, radon, francium, radium, actinium, thorium, protactinium, uranium, neptunium, plutonium, americium, curium, berkelium, californium, einsteinium, fermium, mendelevium, nobelium, lawrencium, rutherfordium, dubnium, seaborgium, bohrium, hassium, meitnerium, darmstadtium, roentgenium, copernicium, nihonium, flerovium, moscovium, livermorium, tennessine, oganesson
    
    public func getElement() -> Element {
        var elementToReturn = Element()
        elementToReturn.atomicNumber = self.rawValue
        elementToReturn.name = String(reflecting: self)
        elementToReturn.color = self.getColor()
        elementToReturn.radius = self.getVanDerWaalsRadius() > 0 ? self.getVanDerWaalsRadius() : self.getCovalentRadius()
        return elementToReturn;
    }
    
    public func getColor() -> Color {
        var color = NSColor()
        switch(self) {
        case .hydrogen:
            color = .white
        case .carbon:
            color = .black
        case .nitrogen:
            color = #colorLiteral(red: 0.1333333333, green: 0.2, blue: 1, alpha: 1) // #2233ff dark blue
        case .oxygen:
            color = .red
        case .fluorine, .chlorine:
            color = .green
        case .bromine:
            color = #colorLiteral(red: 0.6, green: 0.1333333333, blue: 0, alpha: 1) //#992200 dark red
        case .iodine:
            color = #colorLiteral(red: 0.4, green: 0, blue: 0.7333333333, alpha: 1) //#6600bb dark violet
        case .helium, .neon, .argon, .xenon, .krypton:
            color = .cyan
        case .phosphorus:
            color = .orange
        case .sulfur:
            color = .yellow
        case .boron:
            color = #colorLiteral(red: 1, green: 0.6666666667, blue: 0.4666666667, alpha: 1) // #ffaa77 peach/salmon
        case .lithium, .sodium, .potassium, .rubidium, .caesium, .francium:
            color = #colorLiteral(red: 0.4666666667, green: 0, blue: 1, alpha: 1) // #7700ff violet
        case .berylium, .magnesium, .calcium, .strontium, .barium, .radium:
            color = #colorLiteral(red: 0, green: 0.4666666667, blue: 0, alpha: 1) // #007700 dark green
        case .titanium:
            color = .gray
        case .iron:
            color = #colorLiteral(red: 0.8666666667, green: 0.4666666667, blue: 0, alpha: 1) // #dd7700 dark orange
        default:
            color = #colorLiteral(red: 0.8666666667, green: 0.4666666667, blue: 1, alpha: 1) // #dd77ff pink
        }
        return Color(color)
    }
    
    // https://en.wikipedia.org/wiki/Covalent_radius
    // TODO: Different values for multiple bonds?
    public func getCovalentRadius() -> Int {
        var radius = Int()
        switch(self) {
        case .hydrogen:
            radius = 32
        case .helium:
            radius = 2
        case .lithium:
            radius = 133
        case .berylium:
            radius = 102
        case .boron:
            radius = 85
        case .carbon:
            radius = 75
        case .nitrogen:
            radius = 71
        case .oxygen:
            radius = 63
        case .fluorine:
            radius = 64
        case .neon:
            radius = 67
        case .sodium:
            radius = 155
        case .magnesium:
            radius = 139
        case .aluiminium:
            radius = 126
        case .silicon:
            radius = 116
        case .phosphorus:
            radius = 111
        case .sulfur:
            radius = 103
        case .chlorine:
            radius = 99
        case .argon:
            radius = 96
        case .potassium:
            radius = 196
        case .calcium:
            radius = 171
        case .scandium:
            radius = 148
        case .titanium:
            radius = 136
        case .vanadium:
            radius = 134
        case .chromium:
            radius = 122
        case .manganese:
            radius = 119
        case .iron:
            radius = 116
        case .cobalt:
            radius = 111
        case .nickel:
            radius = 110
        case .copper:
            radius = 112
        case .zinc:
            radius = 118
        case .gallium:
            radius = 124
        case .germanium:
            radius = 121
        case .arsenic:
            radius = 121
        case .selenium:
            radius = 116
        case .bromine:
            radius = 114
        case .krypton:
            radius = 117
        case .rubidium:
            radius = 210
        case .strontium:
            radius = 185
        case .yttrium:
            radius = 163
        case .zirconium:
            radius = 154
        case .niobium:
            radius = 147
        case .molybdenum:
            radius = 138
        case .technetium:
            radius = 128
        case .ruthenium:
            radius = 125
        case .rhodium:
            radius = 125
        case .palladium:
            radius = 120
        case .silver:
            radius = 128
        case .cadmium:
            radius = 136
        case .indium:
            radius = 142
        case .tin:
            radius = 140
        case .antimony:
            radius = 140
        case .tellurium:
            radius = 136
        case .iodine:
            radius = 133
        case .xenon:
            radius = 131
        case .caesium:
            radius = 232
        case .barium:
            radius = 196
        case .lanthanum:
            radius = 180
        case .cerium:
            radius = 163
        case .praseodymium:
            radius = 176
        case .neodymium:
            radius = 174
        case .promethium:
            radius = 173
        case .samarium:
            radius = 172
        case .europium:
            radius = 168
        case .gadolinium:
            radius = 169
        case .terbium:
            radius = 168
        case .dysprosium:
            radius = 167
        case .holmium:
            radius = 166
        case .erbium:
            radius = 165
        case .thulium:
            radius = 164
        case .ytterbium:
            radius = 170
        case .lutetium:
            radius = 162
        case .hafnium:
            radius = 152
        case .tantalum:
            radius = 146
        case .tungsten:
            radius = 137
        case .rhenium:
            radius = 131
        case .osmium:
            radius = 129
        case .iridium:
            radius = 122
        case .platinum:
            radius = 123
        case .gold:
            radius = 124
        case .mercury:
            radius = 133
        case .thallium:
            radius = 144
        case .lead:
            radius = 144
        case .bismuth:
            radius = 151
        case .polonium:
            radius = 145
        case .astatine:
            radius = 147
        case .radon:
            radius = 142
        case .francium:
            radius = 223
        case .radium:
            radius = 201
        case .actinium:
            radius = 186
        case .thorium:
            radius = 175
        case .protactinium:
            radius = 169
        case .uranium:
            radius = 170
        case .neptunium:
            radius = 171
        case .plutonium:
            radius = 172
        case .americium:
            radius = 166
        case .curium:
            radius = 166
        case .berkelium:
            radius = 168
        case .californium:
            radius = 168
        case .einsteinium:
            radius = 165
        case .fermium:
            radius = 167
        case .mendelevium:
            radius = 173
        case .nobelium:
            radius = 176
        case .lawrencium:
            radius = 161
        case .rutherfordium:
            radius = 157
        case .dubnium:
            radius = 149
        case .seaborgium:
            radius = 143
        case .bohrium:
            radius = 141
        case .hassium:
            radius = 134
        case .meitnerium:
            radius = 129
        case .darmstadtium:
            radius = 128
        case .roentgenium:
            radius = 121
        case .copernicium:
            radius = 122
        case .nihonium:
            radius = 136
        case .flerovium:
            radius = 143
        case .moscovium:
            radius = 162
        case .livermorium:
            radius = 175
        case .tennessine:
            radius = 165
        case .oganesson:
            radius = 157
        }
        return radius
    }
    
    public func getVanDerWaalsRadius() -> Int {
        let UNKNOWN = -1
        var radius = Int()
        switch(self) {
        case .hydrogen:
            radius = 120
        case .helium:
            radius = 140
        case .lithium:
            radius = 182
        case .berylium:
            radius = 153
        case .boron:
            radius = 192
        case .carbon:
            radius = 170
        case .nitrogen:
            radius = 155
        case .oxygen:
            radius = 152
        case .fluorine:
            radius = 147
        case .neon:
            radius = 154
        case .sodium:
            radius = 227
        case .magnesium:
            radius = 173
        case .aluiminium:
            radius = 184
        case .silicon:
            radius = 210
        case .phosphorus:
            radius = 180
        case .sulfur:
            radius = 180
        case .chlorine:
            radius = 175
        case .argon:
            radius = 188
        case .potassium:
            radius = 275
        case .calcium:
            radius = 231
        case .scandium:
            radius = 211
        case .titanium:
            radius = UNKNOWN
        case .vanadium:
            radius = UNKNOWN
        case .chromium:
            radius = UNKNOWN
        case .manganese:
            radius = UNKNOWN
        case .iron:
            radius = UNKNOWN
        case .cobalt:
            radius = UNKNOWN
        case .nickel:
            radius = 163
        case .copper:
            radius = 140
        case .zinc:
            radius = 139
        case .gallium:
            radius = 187
        case .germanium:
            radius = 211
        case .arsenic:
            radius = 185
        case .selenium:
            radius = 190
        case .bromine:
            radius = 185
        case .krypton:
            radius = 202
        case .rubidium:
            radius = 303
        case .strontium:
            radius = 249
        case .yttrium:
            radius = UNKNOWN
        case .zirconium:
            radius = UNKNOWN
        case .niobium:
            radius = UNKNOWN
        case .molybdenum:
            radius = UNKNOWN
        case .technetium:
            radius = UNKNOWN
        case .ruthenium:
            radius = UNKNOWN
        case .rhodium:
            radius = UNKNOWN
        case .palladium:
            radius = 163
        case .silver:
            radius = 172
        case .cadmium:
            radius = 158
        case .indium:
            radius = 193
        case .tin:
            radius = 217
        case .antimony:
            radius = 206
        case .tellurium:
            radius = 206
        case .iodine:
            radius = 198
        case .xenon:
            radius = 216
        case .caesium:
            radius = 343
        case .barium:
            radius = 268
        case .lanthanum:
            radius = UNKNOWN
        case .cerium:
            radius = UNKNOWN
        case .praseodymium:
            radius = UNKNOWN
        case .neodymium:
            radius = UNKNOWN
        case .promethium:
            radius = UNKNOWN
        case .samarium:
            radius = UNKNOWN
        case .europium:
            radius = UNKNOWN
        case .gadolinium:
            radius = UNKNOWN
        case .terbium:
            radius = UNKNOWN
        case .dysprosium:
            radius = UNKNOWN
        case .holmium:
            radius = UNKNOWN
        case .erbium:
            radius = UNKNOWN
        case .thulium:
            radius = UNKNOWN
        case .ytterbium:
            radius = UNKNOWN
        case .lutetium:
            radius = UNKNOWN
        case .hafnium:
            radius = UNKNOWN
        case .tantalum:
            radius = UNKNOWN
        case .tungsten:
            radius = UNKNOWN
        case .rhenium:
            radius = UNKNOWN
        case .osmium:
            radius = UNKNOWN
        case .iridium:
            radius = UNKNOWN
        case .platinum:
            radius = 175
        case .gold:
            radius = 166
        case .mercury:
            radius = 155
        case .thallium:
            radius = 196
        case .lead:
            radius = 202
        case .bismuth:
            radius = 207
        case .polonium:
            radius = 197
        case .astatine:
            radius = 202
        case .radon:
            radius = 220
        case .francium:
            radius = 348
        case .radium:
            radius = 283
        case .actinium:
            radius = UNKNOWN
        case .thorium:
            radius = UNKNOWN
        case .protactinium:
            radius = UNKNOWN
        case .uranium:
            radius = 186
        case .neptunium:
            radius = UNKNOWN
        case .plutonium:
            radius = UNKNOWN
        case .americium:
            radius = UNKNOWN
        case .curium:
            radius = UNKNOWN
        case .berkelium:
            radius = UNKNOWN
        case .californium:
            radius = UNKNOWN
        case .einsteinium:
            radius = UNKNOWN
        case .fermium:
            radius = UNKNOWN
        case .mendelevium:
            radius = UNKNOWN
        case .nobelium:
            radius = UNKNOWN
        case .lawrencium:
            radius = UNKNOWN
        case .rutherfordium:
            radius = UNKNOWN
        case .dubnium:
            radius = UNKNOWN
        case .seaborgium:
            radius = UNKNOWN
        case .bohrium:
            radius = UNKNOWN
        case .hassium:
            radius = UNKNOWN
        case .meitnerium:
            radius = UNKNOWN
        case .darmstadtium:
            radius = UNKNOWN
        case .roentgenium:
            radius = UNKNOWN
        case .copernicium:
            radius = UNKNOWN
        case .nihonium:
            radius = UNKNOWN
        case .flerovium:
            radius = UNKNOWN
        case .moscovium:
            radius = UNKNOWN
        case .livermorium:
            radius = UNKNOWN
        case .tennessine:
            radius = UNKNOWN
        case .oganesson:
            radius = UNKNOWN
        }
        return radius
    }
}
