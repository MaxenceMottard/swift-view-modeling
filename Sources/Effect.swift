//
//  Effect.swift
//  Utils
//
//  Created by Maxence Mottard on 14/10/2024.
//

import Foundation

public struct Effect<Action> {
    public typealias Send = (Action) async -> Void

    private let work: (@escaping Send) async -> Void

    public init(work: @escaping (@escaping Send) async -> Void) {
        self.work = work
    }

    func run(send: @escaping Send) async -> Void {
        await work(send)
    }
}

extension Effect {
    public static func run(_ work: @escaping (@escaping Send) async -> Void) -> Effect {
        return Effect { send in
            await work(send)
        }
    }

    public static var none: Effect {
        .init(work: { _ in })
    }

    public static func send(_ action: Action) -> Effect {
        return Effect { send in
            await send(action)
        }
    }

    /// Concatenates a variadic list of effects together into a single effect, which runs the effects
    /// one after the other.
    public static func concatenate(_ effects: Effect...) -> Effect {
        return Effect { send in
            for effect in effects {
                await effect.run(send: send)
            }
        }
    }

    /// Merges a variadic list of effects together into a single effect, which runs the effects at the
    /// same time.
    public static func merge(_ effects: Effect...) -> Effect {
        return Effect { send in
            await withTaskGroup(of: Void.self) { group in
                for effect in effects {
                    group.addTask {
                        await effect.run(send: send)
                    }
                }
            }
        }
    }
}
