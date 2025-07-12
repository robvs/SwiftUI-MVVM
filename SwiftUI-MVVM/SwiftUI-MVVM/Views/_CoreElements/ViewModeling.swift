//
//  ViewModel.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import SwiftUI

@MainActor
protocol ViewModeling<State, Event>: ObservableObject {
    associatedtype State
    associatedtype Event

    /// Container for the dynamic/run time values that are presented in a view.
    var state: State { get }

    /// Handle the given event.
    ///
    /// This is typically called by the view when an event such as a button press happens
    /// and often results in a mutation of `state`.
    /// - Parameter event: The event that has occurred.
    func send(event: Event)
}
