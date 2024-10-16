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
                    return .none

                case .didAppear:
                    state.isLoading = false
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

        viewModel.received(.didAppear) {
            $0.isLoading = false
        }
        viewModel.received(.incrementCount) {
            $0.count = 1
            $0.isLoading = false
        }
    }


    @Test func sendAndReceiveInWrongOrder() async {
        await viewModel.send(.didAppear)

        withKnownIssue {
            viewModel.received(.incrementCount) {
                $0.count = 1
                $0.isLoading = false
            }
            viewModel.received(.didAppear) {
                $0.isLoading = false
            }
        }
    }


    @Test func sendAndReceiveWithWrongStatePropertiesValues() async {
        await viewModel.send(.didAppear)

        withKnownIssue {
            viewModel.received(.didAppear) {
                $0.isLoading = false
            }
            viewModel.received(.incrementCount) {
                $0.count = 2
                $0.isLoading = true
            }
        }
    }

}
