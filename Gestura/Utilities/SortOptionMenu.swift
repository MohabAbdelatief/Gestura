//
//  SortOptionMenu.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 17/05/2026.
//

import SwiftUI

struct SortOptionMenu: ToolbarContent {
    @Binding var selection: SortOption
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Sort by") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            selection = option
                        } label: {
                            if option == selection {
                                Label(
                                    option.displayName,
                                    systemImage: "checkmark"
                                )
                            } else {
                                Text(option.displayName)
                            }
                        }
                    }
                }
            } label: {
                Label("Sort by", systemImage: "arrow.up.arrow.down")
            }
        }
    }
}
