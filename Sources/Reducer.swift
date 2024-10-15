//
//  Reducer.swift
//  Utils
//
//  Created by Maxence Mottard on 13/10/2024.
//

import Foundation

public protocol Reducer {
    associatedtype State: Equatable
    associatedtype Action

    var body: Reduce<State, Action> { get }
}
