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

    @Test func send() async {
        await viewModel._send(.action1)
        let stateToSet = SpyReducer.State(isHidden: false)
        await viewModel._send(.setState(stateToSet))
        await viewModel._send(.action3)
        await viewModel._send(.action2)

        let expectedActions: [SpyReducer.Action] = [.action1, .setState(stateToSet), .action3, .action2]
        #expect(reducer.reduceBodyActionsReceived == expectedActions)
        #expect(reducer.reduceBodyCallsCount == 4)
    }

    @Test func subscriptState() async {
        let state = SpyReducer.State(count: 17, isHidden: true)
        await viewModel._send(.setState(state))

        #expect(viewModel.count == 17)
        #expect(viewModel.isHidden == true)
    }

    @Test func returnEffect() async {
        reducer.reduceBodyReturnEffect = .concatenate(
            .send(.action1),
            .run { send in
                await send(.action1)
            },
            .send(.action3)
        )

        await viewModel._send(.action2)

        let expectedActions: [SpyReducer.Action] = [.action2, .action1, .action1, .action3]
        #expect(reducer.reduceBodyActionsReceived == expectedActions)
        #expect(reducer.reduceBodyCallsCount == 4)
    }

    @Test func bindingSetValue() async {
        let binding = viewModel.binding(keyPath: \.count, send: SpyReducer.Action.setCount)
        binding.wrappedValue = 7

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        #expect(viewModel.count == 7)
    }

    @Test func bindingGetValue() {
        let binding = viewModel.binding(keyPath: \.count, send: SpyReducer.Action.setCount)

        let state = SpyReducer.State(count: 8)
        viewModel.send(.setState(state))

        print(binding.wrappedValue)
        #expect(binding.wrappedValue == 8)
    }

}
