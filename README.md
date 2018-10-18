# XPresentation

APIs for making a custom presentation is annoying. Boilerplate code makes people's fingers hurt, at least mine.

What a presentation really needs? or what we really care about?

- presenting & presented view's layout
- present & dismiss animation
- some other extra info like dimming.

every item above has a default impl provided by system. That's why the delegate methods related to presentation can not be implemented or can return `nil`.
we have to provide `UIViewControllerTransitioningDelegate` for custom presentation process, `UIViewControllerAnimatedTransitioning` for present & dismiss animations, subclass of `UIPresentationController` for adding dimming or sth else.

XPresentation makes these easier with some free utils layout, animation and a basic `UIPresentationController`. these can satisfy many presentation needs. You can always write your own impl for any part of presentation.

once again, I just make the procss easier.

# quick look

before you present a `UIViewController`, call `configPresentation` to provide your custom behaviour:

```swift
viewController.configPresentation { config in
    config.presentAnimation = Presentation.BasicAnimation.spring(
        action: .present(Presentation.Layouts.center(width: .percent(0.75), height: .value(300))),
        animator: Presentation.Animations.fadeIn()
    )
        
    config.dismissAnimation = Presentation.BasicAnimation.normal(
        action: .dismiss,
        animator: Presentation.Animations.fadeOut()
    )
        
    config.controller = Presentation.basicPresentationController()
}
```
Notice, all things here are provided as utils, you can always provide your own.

Then, you can present the viewController just as usual:
```
present(viewController, animated: true, completion: nil)
```

# Present in Separate Window

some times we want to `present` a page, but the logic cannot be controlled very well. the API `presentXXX` & `dismissXXX` are easy to make problems.

one solution is to make another window where the page is presented in. That is:

- make a window with specified level.
- set a rootViewController with clear background color.
- make window visible.
- present your page using the rootViewController.

since this is another window, other windows such as app's main window is not affected. you can still perform present or push/pop in other windows.
for example, every time user click a notification to enter your app, you want to show a page related to the notification, you can use a new window to present the page.

```
let window = PresentationWindow(level: UIWindow.Level(1988), preferredStatusBarStyle: .lightContent)
window.present(yourPage)
```

when dismissed, app's main window will be set the `keyWindow`.

# Present Using Popover

popover is `AutoLayout` unfriendly. page size must be provided by `preferredContentSize`, it's also the same property to change page size. 

the util api provided is just a simple configuration wrapper.
