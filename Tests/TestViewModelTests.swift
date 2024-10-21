//
//  TestViewModelTests.swift
//  swift-view-modeling
//
//  Created by Maxence Mottard on 15/10/2024.
//

import Testing
@testable import ViewModeling

@Suite("TestViewModel")
struct TestViewModelTests {
    let viewModel: TestViewModel<TReducer>

    struct TReducer: Reducer {
        struct State: Equatable {
            var count = 0
            var isLoading = true
        }

        enum Action {
            case incrementCount
            case didAppear
        }

        var body: Reduce<State, Action> {
            Reduce { state, action in
                switch action {
                case .incrementCount:
                    state.count += 1
                    state.isLoading = false
                    return .none

                case .didAppear:
                    state.isLoading = true
                    return .send(.incrementCount)
                }
            }
        }
    }

    init() {
        self.viewModel = TestViewModel(
            reducer: { TReducer() },
            initialState: TReducer.State()
        )
    }


    @Test func sendAndReceive() async {
        await viewModel.send(.didAppear)

        let didAppearAction = viewModel.popAction()
        #expect(didAppearAction.action == .didAppear)
        #expect(didAppearAction.state.isLoading == true)

        let incrementCount = viewModel.popAction()
        #expect(incrementCount.action == .incrementCount)
        #expect(incrementCount.state.count == 1)
        #expect(incrementCount.state.isLoading == false)
    }

    @Test func sendAndReceiveInWrongOrder() async {
        await viewModel.send(.didAppear)

        let incrementCount = viewModel.popAction()
        #expect(incrementCount.action != .incrementCount)
        #expect(incrementCount.state.count != 1)
        #expect(incrementCount.state.isLoading != false)

        let didAppearAction = viewModel.popAction()
        #expect(didAppearAction.action != .didAppear)
        #expect(didAppearAction.state.isLoading != true)
    }

    @Test func sendAndReceiveInWrongOrderAndGoodStateChanges() async {
        await viewModel.send(.didAppear)

        let incrementCount = viewModel.popAction()
        #expect(incrementCount.action != .incrementCount)
        #expect(incrementCount.state.isLoading == true)

        let didAppearAction = viewModel.popAction()
        #expect(didAppearAction.action != .didAppear)
        #expect(didAppearAction.state.count == 1)
        #expect(didAppearAction.state.isLoading == false)
    }

}
