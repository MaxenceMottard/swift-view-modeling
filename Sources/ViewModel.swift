//
//  ViewModel.swift
//  Utils
//
//  Created by Maxence Mottard on 13/10/2024.
//

import SwiftUI

@Observable
@dynamicMemberLookup
public class ViewModel<R: Reducer> {
    var reducer: R
    var state: R.State

    public init(reducer: () -> R, initialState state: R.State) {
        self.reducer = reducer()
        self.state = state
    }

    public func send(_ action: R.Action) {
        Task {
            await _send(action)
        }
    }

    func _send(_ action: R.Action) async {
        let effect = reducer.body(state: &state, action: action)
        await effect.run(send: _send)
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<R.State, Value>) -> Value {
        self.state[keyPath: keyPath]
    }

    public func binding<Value>(
        keyPath: WritableKeyPath<R.State, Value>,
        send actionToSend: @escaping (Value) -> R.Action
    ) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(actionToSend($0)) }
        )
    }
}
