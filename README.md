# SwiftUI-MVVM
This is a sample project that demonstrates a light weight, highly structured, and flexible MVVM implementation for SwiftUI.

## Architecture
At a high level, this exemplifies a standard implementation of the MVVM design pattern. At a lower level, it demonstrates an approach that:

1. Enables creation of view previews without the need to configure/mock view model dependencies

2. Helps enforce a consistent structure and interface for view models

3. Provides an approach for reducing boilerplate in simpler views (i.e. defining a View State type, skipping the View Model)

This approach makes strides towards Uncle Bob Martin's [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) while keeping the more familiar concepts of Model, View and View Model. In essense, the View State (described below) is the presenter in Clean Architecture and the View Model is the interactor (though wouldn't qualify as a Use Case).

### View Model & View State
**View Models** handle interaction between the view and the system (i.e. web services, database access, etc.).

**View States** represent the current state of a view along with how to transition from one state to another. Its public properties are used to populate the view.

#### What's the Difference Between the Two?
As mentioned, View Models handle interactions with the system. System interaction is performed by objects that are injected into the View Model. The objects are protocol based to enable testability. View States provide the values that populate the view long with the logic for transitioning from one state to another.

If a view's state changes do not require interaction with the system, the formality of a View Model is not needed and only a View State is defined.

#### Where Does the Data Handling Logic Go?
For views with both View Model and View State, it can be a challenge determining where to draw the line between what data processing logic goes in the View Model and what should go in the View State. The reality is that IT DOES NOT MATTER, at least in most situations. What matters is that:

1. system interactions are handled by the View Model
2. the View State has no system dependencies
3. both View Model and View State are testable

#### Why is There a Need for Both Model & State?
This gets to the crux of this design pattern. It's a pain in the ass defining mocks just to create a set of view previews. This pattern enables view previews to be created with just the View State. No mocking is needed.

Another benefit is that, for more complex views, it helps break out the code into smaller, more focused pieces.

## Implementation
### `ViewModeling` Protocol
`ViewModeling` defines the public interface for View Models, which simply defines a `state` property and `send(event:)` function.

View Models conform to `ViewModeling` and define `State` and `Event` types. For example:

```swift
// MARK: - View Model

final class SomeViewModel: ViewModeling {
    @Published var state: SomeViewState

	// Define dependencies and other private properties here...
	...

    // MARK: Events

    enum Event {
        case event1
    }

    func send(event: Event) {
        switch event {
        case .event1:
			let newValue = // process the event
			state.handleEvent1Result(newValue)
        }
    }
}

// MARK: - View State

 /// Encapsulation of values that drive the dynamic elements of the associated view.
/// The default values indicate the intended initial state.
struct SomeViewState {
    private(set) var value1: String?
    private(set) var value2: Int = 0

	// MARK: Functions that manage state updates
	
    mutating func handleEvent1Result(_ newValue: String?) {
    	value1 = newValue
		value2 = 42
    }
}
```

### Defining Views
The issue with typical MVVM implementations is that the View depends upon a concrete View Model, which often depends upon injected objects that need to be mocked in view previews.

The approach described in this document limits View dependencies to only the View State type and View Model Event type. For example, `SomeView` is defined as follows:

```swift
struct SomeView<ViewModelType: ViewModeling>: View where
ViewModelType.State == SomeViewModel.State,
ViewModelType.Event == SomeViewModel.Event {
	@StateObject var viewModel: ViewModelType
	...
}
```

### Sample Code
`HomeViewState` illustrates a View State that includes well-defined events that can cause the state to change. These are called an `Effect`. All state changes are funneled through a `reduce()` method that manages state changes.

`CategoryViewState` illustrates a less formal approach to state changes where separate functions are used to change the state.
