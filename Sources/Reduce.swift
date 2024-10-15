//
//  Reduce.swift
//  Utils
//
//  Created by Maxence Mottard on 13/10/2024.
//

import Foundation

public struct Reduce<State, Action> {
    private let reduce: (inout State, Action) -> Effect<Action>

    public init(reduce: @escaping (inout State, Action) -> Effect<Action>) {
        self.reduce = reduce
    }

    func callAsFunction(state: inout State, action: Action) -> Effect<Action> {
        reduce(&state, action)
    }
}
