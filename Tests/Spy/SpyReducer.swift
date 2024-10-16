//
//  SpyReducer.swift
//  ViewModeling
//
//  Created by Maxence Mottard on 15/10/2024.
//

import ViewModeling

class SpyReducer: Reducer {
    struct State: Equatable {
        var count = 0
        var isHidden = false
    }

    enum Action: Equatable {
        case action1
        case action2
        case action3
        case setState(State)
        case setCount(Int)
    }

    init() {}

    var reduceBodyCallsCount = 0
    var reduceBodyActionsReceived: [Action] = []
    var reduceBodyReturnEffect: Effect<Action>?

    var body: Reduce<State, Action> {
        Reduce { [weak self] state, action in
            guard let self else { return .none }

            if case let .setState(newState) = action {
                state = newState
            }

            if case let .setCount(newCount) = action {
                state.count = newCount
            }

            reduceBodyCallsCount += 1
            reduceBodyActionsReceived.append(action)

            let effect = reduceBodyReturnEffect ?? .none
            reduceBodyReturnEffect = nil

            return effect
        }
    }
}
