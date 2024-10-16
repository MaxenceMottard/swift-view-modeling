//
//  TestViewModel.swift
//  swift-view-modeling
//
//  Created by Maxence Mottard on 15/10/2024.
//

#if canImport(Testing)
import Testing
import XCTest

public class TestViewModel<TestedReducer: Reducer>: ViewModel<TesterReducer<TestedReducer>> {
    typealias ReceivedAction = (TestedReducer.Action, TestedReducer.State, TestedReducer.State)

    private var actions: [ReceivedAction] = []

    public init(reducer: () -> TestedReducer, initialState state: TestedReducer.State) {
        super.init(reducer: { TesterReducer(reducer: reducer()) }, initialState: state)

        self.reducer.appendAction = { [weak self] in
            self?.actions.append($0)
        }
    }

    public override func send(_ action: TestedReducer.Action) {
        Fail(
        """
        Don't call this method. For tests you should use
        '\(String(describing: self.send))' async to send any action.
        """
        )
    }

    public func send(_ action: TestedReducer.Action) async {
        if !actions.isEmpty {
            let actions = self.actions.map(\.0).map { String(describing: $0) }
            Fail(
              """
              \(actions.count) received action\
              \(actions.count == 1 ? " was" : "s were") skipped: \
              \(actions)
              """
            )
        }

        await _send(action)
    }

    public func received(_ action: TestedReducer.Action, mutation: (inout TestedReducer.State) -> Void) {
        var (_, mutatedState, expectedState) = actions.removeFirst()
        mutation(&mutatedState)

        let diffs = differencesBetween(lhs: expectedState, rhs: mutatedState)
        if !diffs.isEmpty {
            let expectedDiffs = diffs.reduce("") { partialResult, item in
                let (label, expectedValue, _) = item
                return partialResult + "\n \(label): \(expectedValue)"
            }
            let actualDiffs = diffs.reduce("") { partialResult, item in
                let (label, _, actualValue) = item
                return partialResult + "\n \(label): \(actualValue)"
            }
            Fail(
                """
                Action: \(action)
                Expected: \(expectedDiffs)
                
                Actual: \(actualDiffs)
                """
            )
        }
    }

    private func differencesBetween<T: Equatable>(lhs: T, rhs: T) -> [(String, Any, Any)] {
        let lhsMirror = Mirror(reflecting: lhs)
        let rhsMirror = Mirror(reflecting: rhs)

        var differences = [(String, Any, Any)]()

        for (lhsChild, rhsChild) in zip(lhsMirror.children, rhsMirror.children) {
            if let label = lhsChild.label,
               let lhsValue = lhsChild.value as? any Equatable,
               let rhsValue = rhsChild.value as? any Equatable,
               !lhsValue.isEqual(to: rhsValue) {
                differences.append((label, lhsValue, rhsValue))
            }
        }

        return differences
    }

    func Fail(_ message: String) {
#if canImport(Testing)
        Issue.record(.__line(message))
#endif
#if canImport(XCTest)
        XCTFail(message)
#endif

    }
}

extension Equatable {
    func isEqual(to other: any Equatable) -> Bool {
        return self == (other as? Self)
    }
}

public struct TesterReducer<R: Reducer>: Reducer {
    public typealias State = R.State
    public typealias Action = R.Action

    let testedReducer: R
    var appendAction: ((TestViewModel<R>.ReceivedAction) -> Void)!

    init(reducer: R) {
        self.testedReducer = reducer
    }

    public var body: Reduce<R.State, R.Action> {
        Reduce { state, action in
            let oldState = state
            let effect = testedReducer.body(state: &state, action: action)
            let newState = state
            appendAction((action, oldState, newState))

            return effect
        }
    }
}
#endif
