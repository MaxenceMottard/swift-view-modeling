import Testing
@testable import ViewModeling

@Suite("Reduce")
struct ReduceTests {

    struct TestState {
        var count = 0
    }

    enum TestAction {
        case action1
        case action2
    }

    @Test func reduce() async throws {
        var receivedAction: TestAction!
        var runEffectClosureCallsCount = 0

        let reduce = Reduce<TestState, TestAction> { state, action in
            receivedAction = action
            state.count = 4

            return .run { _ in
                runEffectClosureCallsCount += 1
            }
        }

        var state = TestState()
        let effect = reduce(state: &state, action: .action2)
        await effect.run { _ in }

        #expect(state.count == 4)
        #expect(runEffectClosureCallsCount == 1)
        #expect(receivedAction == .action2)
    }

}
