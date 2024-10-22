//
//  TestViewModel.swift
//  swift-view-modeling
//
//  Created by Maxence Mottard on 15/10/2024.
//

import Foundation

public class TestViewModel<TestedReducer: Reducer>: ViewModel<TesterReducer<TestedReducer>> {
    private var actions = [ReceivedAction<TestedReducer>]()

    public init(reducer: () -> TestedReducer, initialState state: TestedReducer.State) {
        super.init(reducer: { TesterReducer(reducer: reducer()) }, initialState: state)

        self.reducer.appendAction = { [weak self] in
            self?.actions.append($0)
        }
    }

    public override func send(_ action: TestedReducer.Action) {
        fatalError(
        """
        Don't call this method. For tests you should use
        '\(String(describing: self.send))' async to send any action.
        """
        )
    }

    public func send(_ action: TestedReducer.Action) async {
        if !actions.isEmpty {
            let actions = self.actions.map(\.action).map { String(describing: $0) }
            fatalError(
              """
              \(actions.count) received action\
              \(actions.count == 1 ? " was" : "s were") skipped: \
              \(actions)
              """
            )
        }

        await _send(action)
    }

    public func popAction() -> ReceivedAction<TestedReducer> {
        actions.removeFirst()
    }

    public struct ReceivedAction<Reducer: ViewModeling.Reducer> {
        public let action: Reducer.Action
        public let state: Reducer.State
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<TestedReducer.State, Value>) -> Value {
        get { self.state[keyPath: keyPath] }
        set { self.state[keyPath: keyPath] = newValue }
    }
}

public struct TesterReducer<R: Reducer>: Reducer {
    public typealias State = R.State
    public typealias Action = R.Action

    let testedReducer: R
    var appendAction: ((TestViewModel<R>.ReceivedAction<R>) -> Void)!

    init(reducer: R) {
        self.testedReducer = reducer
    }

    public var body: Reduce<R.State, R.Action> {
        Reduce { state, action in
            let effect = testedReducer.body(state: &state, action: action)
            let newState = state

            let receivedAction = TestViewModel<R>.ReceivedAction<R>(
                action: action,
                state: newState
            )
            appendAction(receivedAction)

            return effect
        }
    }
}
