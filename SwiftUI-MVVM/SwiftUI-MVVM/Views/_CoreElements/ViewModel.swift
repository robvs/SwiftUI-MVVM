//
//  ViewModel.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import SwiftUI

@MainActor
protocol ViewModel<State, Event>: ObservableObject {
    associatedtype State
    associatedtype Event

    /// Container for the dynamic/run time values that are presented in a view.
    var state: State { get }

    func send(event: Event)
}
//
//class ViewModel<State, Event>: ViewModeling {
//    @Published var state: State
//
//    init(state: State) {
//        self.state = state
//    }
//
//    func send(event: Event) {
//    }
//}
