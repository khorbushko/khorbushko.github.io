---
layout: post
comments: true
title: "Present View overFullScreen in SwiftUI"
categories: article
tags: [iOS, SwiftUI, tutorial]
excerpt_separator: <!--more-->
comments_id: 3

author:
- kyryl horbushko
- Lviv
---

If u want to present some `View` in `SwiftUI` over whole content like `Alert` or `UIViewController` does (with `overCurrentContext` style) with transparent background - u will be surprized. 
<!--more-->

What u can - is actually create `View` and show it under current context but not under `TabBar` for example. That's not your responsibility. And it's true, except cases when u want to show alert with `Image` - this is definetly not a standart one, so you need to design it and present ... somehow.

One option is to always present it from appropriate context - but sometimes it's hard to achive and we would like to make it in same way as Apple does within `.alert`.

How to achive this? Well, we can use `UIKit`.

All that we need - is to create `UIViewController`, configure appropriate presentation style, add content and present on root window.

Let's start one-by-one.

To **find presenter** we can use well-known approach of selecting `topMostViewController` - our presenter:

{% highlight swift %}
extension UIWindow {
    
    static var topMostController: UIViewController? {
        let keyWindow = UIApplication.shared.windows
            .filter { $0.isKeyWindow }
            .first
        
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil
    }
}
{% endhighlight %}

To **create `UIViewController` and configure appropriate presentation style** - nothing special also:

{% highlight swift %}
let presentableContent = UIViewController()
presentableContent.modalPresentationStyle = .overCurrentContext
presentableContent.modalTransitionStyle = .crossDissolve
presentableContent.view.backgroundColor = .clear
{% endhighlight %}

Last step - add modifier to allow usage in `SwiftIU` flow. Here we also got one more task - is how to popuplate any content that we want in our `UIViewController`? Well - use `UIHostingController`. Combining all togeter:


{% highlight swift %}
import Foundation
import SwiftUI
import UIKit

extension View {
    
    func presentContentOverFullScreen<ContentView>(
        isPresented: Binding<Bool>,
        content: (Binding<Bool>) -> ContentView
    ) -> some View where ContentView: View {
        let presentingController = UIWindow.topMostController as? PresentedHostingController<ContentView>
        if isPresented.wrappedValue {
            let isViewControllerAlreadyPresented = presentingController != nil
            if isViewControllerAlreadyPresented {
                // this prevent from presenting one more instance of controller
                // when SwiftUI View redraw body during presentation of this controller
                return self
            }

            let presentableContent = PresentedHostingController<ContentView>(
                rootView: content(isPresented)
            )
            presentableContent.modalPresentationStyle = .overCurrentContext
            presentableContent.modalTransitionStyle = .crossDissolve
            presentableContent.view.backgroundColor = .clear
            
            UIWindow.topMostController?.present(presentableContent, animated: true)
        } else {
            if let controller = presentingController {
                controller.dismiss(animated: true)
            }
        }
        
        return self
    }
}

fileprivate final class PresentedHostingController<Content>:
    UIHostingController<Content> where Content: View
{
    /*dummy*/
}
{% endhighlight %}

Here you can find tricky thing - I passed `isPresented: Binding<Bool>` in both - modifier and `PresentedHostingController` - why? Actually we have few reasons:

1. to allow dismiss process of `PresentedHostingController` based on changes related in `isPresented`
2. to allow our `Content` to deside when to dismiss itself - like it was done by `.alert`.

Few notes about dismiss logic - it's not ideal but this approach is way better than for example capture variable within controller and refer to it. 

This moment also can be improved - by checking `presentingController` existance (to make sure that we don't present few controllers on one presenter) and by adding some `identifier` to container (to make sure that we dismiss required presented controller).
