# SwiftUI-MVVM
Sample project that demonstrates a highly structured but flexible MVVM implementation for SwiftUI.

## Architecture
At a high level, this exemplifies a standard implementation of the MVVM design pattern. At a lower level, it demonstrates an approach that:

1. Helps enforce a consistent structure and interface for view models

2. Enables creation of view previews without the need to configure view model dependencies

3. Provides direction for reducing boilerplate in simple views

### View Model & View State
View Models handle interaction between the view and the system (i.e. web services, database access, etc.).

View States represent the current state of a view. Specifically, View States manage dynamic values displayed by the view along with how to transition from one state to the next.

#### What's the Difference?
As mentioned, View Models handle interactions with the system. This is performed by protocol-based objects injected into the View Model. The objects are protocol based to ensure testability.

If a View's state does not require interaction with the system, the formality of a View Model is not needed and only a View State needs to be defined.

#### Where Does Different Logic Go?
For complex views with both View Model and View State, it can be a challenge determining where to draw the line between what data processing logic goes in the View Model and what should go in the View State. The reality is that IT DOES NOT MATTER, at least in most situations. The only thing that matters is that system interactions are handled by the View Model and that both View Model and View State are testable.

#### Why is There a Need for Both Model & State?
This gets to the crux of this design pattern. It's a pain in the ass defining mocks just to create a set of view previews. This pattern enables view previews to be created with just the View State.

## Implementation
`HomeViewModel.State` illustrates a View State that includes well-defined events that can cause the state to change. These are called an `Effect`. All state changes are funneled through a `reduce()` method that manages state changes.

`CategoryViewModel.State` illustrates a less formal approach to state changes where separate functions are used to change the state.
