import Testing
@testable import ViewModeling

@Suite("Effect")
struct EffectTests {

    enum TestAction {
        case action1
        case action2
        case action3
    }

    @Test func customEffect() async {
        let expectedAction = TestAction.action2

        var receivedAction: TestAction!
        var effectWorkClosureCallsCount = 0
        var runEffectSendClosureCallsCount = 0

        let effect = Effect<TestAction> { send in
            effectWorkClosureCallsCount += 1
            await send(expectedAction)
        }

        await effect.run { action in
            runEffectSendClosureCallsCount += 1
            receivedAction = action
        }

        #expect(effectWorkClosureCallsCount == 1)
        #expect(runEffectSendClosureCallsCount == 1)
        #expect(receivedAction == expectedAction)
    }

    @Test func runEffect() async {
        let expectedAction = TestAction.action3

        var receivedAction: TestAction!
        var effectWorkClosureCallsCount = 0
        var runEffectSendClosureCallsCount = 0

        let effect = Effect<TestAction>.run { send in
            effectWorkClosureCallsCount += 1
            await send(expectedAction)
        }

        await effect.run { action in
            runEffectSendClosureCallsCount += 1
            receivedAction = action
        }

        #expect(effectWorkClosureCallsCount == 1)
        #expect(runEffectSendClosureCallsCount == 1)
        #expect(receivedAction == expectedAction)
    }

    @Test func noneEffect() async {
        var receivedAction: TestAction?
        var runEffectSendClosureCallsCount = 0

        let effect = Effect<TestAction>.none

        await effect.run { action in
            runEffectSendClosureCallsCount += 1
            receivedAction = action
        }

        #expect(runEffectSendClosureCallsCount == 0)
        #expect(receivedAction == nil)
    }

    @Test func concatenateEffect() async {
        var receivedActions: [TestAction] = []
        var runEffectSendClosureCallsCount = 0

        let effect = Effect<TestAction>.concatenate(
            .send(.action3),
            .send(.action3),
            .run { send in
                await send(.action2)
            },
            .send(.action1),
            .send(.action2),
            .send(.action2)
        )

        await effect.run { action in
            runEffectSendClosureCallsCount += 1
            receivedActions.append(action)
        }

        #expect(runEffectSendClosureCallsCount == 6)
        #expect(receivedActions == [.action3, .action3, .action2, .action1, .action2, .action2])
    }

    @Test func mergeEffect() async {
        var receivedActions: [TestAction] = []
        var runEffectSendClosureCallsCount = 0

        let effect = Effect<TestAction>.merge(
            .send(.action3),
            .send(.action3),
            .run { send in
                await send(.action2)
            },
            .send(.action1),
            .send(.action2),
            .send(.action2)
        )

        await effect.run { action in
            runEffectSendClosureCallsCount += 1
            receivedActions.append(action)
        }

        #expect(runEffectSendClosureCallsCount == 6)
        #expect(receivedActions.filter({ $0 == .action1 }).count == 1)
        #expect(receivedActions.filter({ $0 == .action2 }).count == 3)
        #expect(receivedActions.filter({ $0 == .action3 }).count == 2)
    }

}
