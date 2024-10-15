import Testing
import Foundation
@testable import ViewModeling

@Suite("ViewModel")
struct ViewModelTests {
    let reducer: SpyReducer
    let viewModel: ViewModel<SpyReducer>

    init() {
        let reducer = SpyReducer()

        self.reducer = reducer
        self.viewModel = ViewModel(
            reducer: { reducer },
            initialState: SpyReducer.State()
        )
    }

    @Test func send() {
        viewModel.send(.action1)
        let stateToSet = SpyReducer.State(isHidden: false)
        viewModel.send(.setState(stateToSet))
        viewModel.send(.action3)
        viewModel.send(.action2)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let expectedActions: [SpyReducer.Action] = [.action1, .setState(stateToSet), .action3, .action2]
            #expect(reducer.reduceBodyActionsReceived == expectedActions)
            #expect(reducer.reduceBodyCallsCount == 3)
        }
    }

    @Test func subscriptState() {
        let state = SpyReducer.State(count: 17, isHidden: true)
        viewModel.send(.setState(state))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            #expect(viewModel.count == 17)
            #expect(viewModel.isHidden == true)
        }
    }

    @Test func returnEffect() {
        reducer.reduceBodyReturnEffect = .concatenate(
            .send(.action1),
            .run { send in
                await send(.action1)
            },
            .send(.action3)
        )

        viewModel.send(.action2)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let expectedActions: [SpyReducer.Action] = [.action2, .action1, .action1, .action3]
            #expect(reducer.reduceBodyActionsReceived == expectedActions)
            #expect(reducer.reduceBodyCallsCount == 4)
        }
    }

}
