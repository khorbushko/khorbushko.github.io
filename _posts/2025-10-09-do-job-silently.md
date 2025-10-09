---
layout: post
comments: true
title: "Do job silently"
categories: article
tags: [iOS, SwiftUI, background, BackgroundTasks]
excerpt_separator: <!--more-->
comments_id: 122

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

We depend more and more on data and on its computation. Think for a moment about how often we use computation and data processing. This aspect can't be not reflected in the modern apps, especially mobile ones. 
<!--more-->

The more we go forward, the more computing power we need. Sometimes it takes additional time. From a UX perspective, we want to deliver always fresh and juicy updates to users, based on their most relevant data. If computation takes too long, the user can wait for it, and waiting is the stuff we don't like more than other stuff.


## Concept

One of the ways to improve this process is to use background tasks and background processing. So we just schedule periodic updates or some computations or some other activities, that "preheat" data for us.

There are a lot of good articles about how to configure this kind of background work, like [this one](https://developer.apple.com/documentation/UIKit/using-background-tasks-to-update-your-app). 

Despite this fact, we often face issues and problems that impede our success. Implementing these activities is not the exception.

So, I decided to put some marks here, related to the main points that need to be completed in order to succeed, because in various articles and documentation, the information is placed partially, and we need (as always) to collect it from part to part.

## Checklist

Below is aka checklist of how to configure a background task.

> I won't cover previous versions of the backgrounding process for iOS; instead, I will focus on the current one (at the moment of writing, we have iOS 26 as a fresh release and iOS 18 as a predecessor and still a bit in use)

0) `import BackgroundTasks` ;]

1) Enable Background Modes capabilities in project config
	
- If you’re using [`BGAppRefreshTask`](https://developer.apple.com/documentation/BackgroundTasks/BGAppRefreshTask), select “Background fetch.”
- If you’re using [`BGProcessingTask`](https://developer.apple.com/documentation/BackgroundTasks/BGProcessingTask), select “Background processing.”

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/1.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/1.png" alt="old_software.jpeg" width="300"/>
</a>
</div>
<br>
<br>

For `BGTaskScheduler`, Apple also recommends enabling “Background processing” when using `BGProcessingTask`; for `BGAppRefresh`, “Background fetch” is the relevant one.

2) Register a list of your task identifiers - in `Info.plist` under key for array [`BGTaskSchedulerPermittedIdentifiers`](https://developer.apple.com/documentation/BundleResources/Information-Property-List/BGTaskSchedulerPermittedIdentifiers)

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/2.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/2.png" alt="old_software.jpeg" width="300"/>
</a>
</div>
<br>
<br>

If it’s missing or mismatched, registration will fail and tasks won’t run.

Next, u have a few options:

- using `BGTaskScheduler.shared.register`
- using `backgroundTask` modifier in SwiftUI


### with `BGTaskScheduler.shared.register` (Manual registration approach)

3) Register task: `BGTaskScheduler.shared.register`. You must call `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)` once, early in app launch (before tasks can be delivered).

*This is important!*

Without registration, `submit()` will succeed, but the system will never deliver the task.
This must be called once during launch, before scheduling or receiving deliveries. The `SwiftUI.backgroundTask` modifier **does not** replace registration.

In a `SwiftUI` App, you typically register in the `init()` of your `@main App` or in `UIApplicationDelegateAdaptor`’s `application(_:didFinishLaunchingWithOptions:)`. The `.backgroundTask` modifier is not a substitute for `register(...)`.

> Disclaimer from Apple doc:
> 
> In iOS 13 and later, adding a BGTaskSchedulerPermittedIdentifiers key to the Info.plist disables the application(_:performFetchWithCompletionHandler:) and setMinimumBackgroundFetchInterval(_:) methods. ([source](https://developer.apple.com/documentation/UIKit/using-background-tasks-to-update-your-app))

4) Correctly implement registration and task handling, and use `setTaskCompleted` method to inform the system about the current state of the task. Don't forget to reschedule the task. Or as an option, u can schedule a task on `ScenePhase` change:

{% highlight swift %}

...
@Environment(\.scenePhase) private var scenePhase
...
// in body somewhere
Scene {

}
.onChange(of: scenePhase, { _, newPhase in
    switch newPhase {
        case .background:
            scheduleAppRefreshTask() // <- here
        default:
            break
    }
})
...

{% endhighlight %}

### with `backgroundTask` modifier (Pure SwiftUI backgroundTask approach)

3) Schedule the Task: You still need to create a request and submit it to the `BGTaskScheduler`. This is typically done when a scene moves to the background, for example, using the `.onChange(of: scenePhase)` modifier.

> **Pitfall**: You must be careful to schedule the task only when the scene phase becomes `.background`. If you try to schedule it at another time, the system *may* ignore it.

Incorrect: 

{% highlight swift %}
.onAppear {
    // ❌ Don't schedule here. May not work
    scheduleAppRefresh()
}
{% endhighlight %}

or 

{% highlight swift %}
.task {
    // ❌ Don't schedule here. May not work
    scheduleAppRefresh()
}
{% endhighlight %}

4) Handle the Task with `.backgroundTask`: Instead of providing a launchHandler during registration, you attach the `.backgroundTask` modifier to a scene in your `SwiftUI` app. This modifier takes the task identifier and an asynchronous closure. When the system executes your scheduled task, this closure is run.

### finally

5) To debug and test, u can use a few techniques (more details below).

## Debuging and Pitfalls

For any capabilities, I highly recommend using a real device - this will reduce the number of problems u can get.

> Offtop
>
> Interesting story - approx 10 or so years ago, I was just starting working with iOS, and one of the tasks was related to a video player. I prepared the base part of the video player using [`AVFoundation`](https://developer.apple.com/documentation/avfoundation). When I launch it on the simulator, I was able to hear some sound but not the video... So I dived into the code and spent a day or two debugging and investigating the issue. After a while, my friend came to me, asking what was wrong, and, after listening to my problem, he started laughing at me. After a while, he said to me, "This is a simulator issue". Indeed, when we tested my code on a real device, everything was working as expected.
> 
> The good moment here is that I read a lot about `AVFoundation`. But u may not be as lucky as I and just spend some time inefficiently.
> 

### simulation

To test the background task, u need to execute a special command as [mentioned here](https://developer.apple.com/documentation/backgroundtasks/starting-and-terminating-tasks-during-development):

{% highlight lldb %}
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"TASK_IDENTIFIER"]
{% endhighlight %}

> again, knowing Obj-C can help a lot here - from syntax to commands, params:
> 
> `e` - expression
> 
> `-l objc` - language to use when interpreting the expression
> 
> `--` - separate LLDB expression from command itself
> 
> `(void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"TASK_IDENTIFIER"]` - private api call with `TASK_IDENTIFIER` syntax in `Objective-C`
> 

To simulate a task with `.backgroundTask`, u need extra work:

{% highlight lldb %}
e -l swift -- BGTaskScheduler.shared.submit(BGAppRefreshTaskRequest(identifier: "TASK_IDENTIFIER"))
{% endhighlight %}

> This will schedule a task, because when you launch the app from Xcode with the debugger attached, background tasks often behave differently or may not run at all. This command simulates part of the process.
> 
> just an alternative way for lldb commands, here `-l swift` means that we use Swift syntax

And then:

{% highlight lldb %}
e -l swift -- _simulateLaunchForTaskWithIdentifier("TASK_IDENTIFIER")
{% endhighlight %}

> yep, same command as the one in Obj-C above

### better testing with visual feedback

You can also add a local push notification for a moment when the task is triggered.

To add a local notification when the background task fires, we need to:

* Use `UNUserNotificationCenter` to request authorization once and schedule a local notification when handleAppRefresh() runs (i.e., when the task fires).
* Ensure we don’t prompt repeatedly; request once at launch.
* Post the notification from the background task path.


{% highlight swift %}
@AppStorage("lastFetchDate") 
private var lastFetchDate: Date?
@AppStorage("notificationsAuthorized") 
private var notificationsAuthorized: Bool = false

// call this early in init, for example
private func requestNotificationAuthorization() {
    guard notificationsAuthorized == false else { return }

    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        DispatchQueue.main.async {
            self.notificationsAuthorized = granted
        }
    }
}

private func postTaskFiredNotification() {
    guard notificationsAuthorized else { return }

    let content = UNMutableNotificationContent()
    content.title = "Background refresh"
    let formatted = lastFetchDate?.formatted(date: .abbreviated, time: .shortened) ?? "just now"
    content.body = "Health data sync triggered at \(formatted)"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/test.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-10-09-do-job-silently/test.png" alt="old_software.jpeg" width="300"/>
</a>
</div>
<br>
<br>


### typos

Double-check for any typos, extra spaces, or case-sensitivity issues in task identifiers - this may be a root cause of a lot of issues.

### timing

Another moment -  configure `earliestBeginDate` for 10-15 min for a fast real test. Because simulation is not enough for a proper process. 

Be ready, that this event can fire even after an hour, despite the value u set to `earliestBeginDate`. You are telling the system "do not run this task before this time." but not when to run this task:

`earliestBeginDate .. some additional time ... your task`

### mix

Do not mismatch approaches - mixing both types for the same identifier can cause confusion and duplicate executions.

Also, you should avoid Double-scheduling. Not a critical moment, but it can reduce “Already scheduled” errors in logs.

## Code

Below is the code for both approaches:

### Manual registration approach

{% highlight swift %}
import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct YourApp: App {
    @Environment(\.scenePhase) 
    private var scenePhase
    @AppStorage("lastFetchDate") 
    private var lastFetchDate: Date?
    @AppStorage("notificationsAuthorized") 
    private var notificationsAuthorized: Bool = false

    init() {
        registerTask()
        requestNotificationAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            container
        }
        .onChange(of: scenePhase, { _, newPhase in
            switch newPhase {
                case .background:
                    lastFetchDate = nil
                    scheduleAppRefreshTask()
                default:
                    break
            }
        })
    }

    // MARK: - BackgroundTask

    private func registerTask() {
        let identifier = String.BackgroundTasks.Identifiers.refresh

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            scheduleAppRefreshTask()

            let work = Task {
                await handleAppRefresh()
                refreshTask.setTaskCompleted(success: true)
            }

            refreshTask.expirationHandler = {
                work.cancel()
                refreshTask.setTaskCompleted(success: false)
            }
        }
    }

    private func handleAppRefresh() async {
        lastFetchDate = Date()
        postTaskFiredNotification()

        do {
            // do some work here
        } catch {
            // do nothing
        }
    }

    private func scheduleAppRefreshTask() {
        let request = BGAppRefreshTaskRequest(
            identifier: .BackgroundTasks.Identifiers.refresh
        )
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // do nothing
            print(error)
        }
    }

   private func requestNotificationAuthorization() {
        // ...
    }

    private func postTaskFiredNotification() {
        // ...
    }
}
{% endhighlight %}

> This option with visual feedback - local push notifications

### Pure SwiftUI backgroundTask approach

{% highlight swift %}
import SwiftUI
import BackgroundTasks

@main
struct YourApp: App {
    @Environment(\.scenePhase) 
    private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                scheduleAppRefresh()
            }
        }
        .backgroundTask(.appRefresh(.BackgroundTasks.Identifiers.refresh)) {
            await performBackgroundTask()
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: .BackgroundTasks.Identifiers.refresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // do nothing
        }
    }
    
    func performBackgroundTask() async {
        // some work here
    }
}
{% endhighlight %}

## Conclusion

While we can still use `BGTaskScheduler` to schedule background tasks, the `.backgroundTask` modifier provides a more modern, integrated, and Swift-native way to handle the execution of those tasks within a `SwiftUI` application. It's the preferred approach for new `SwiftUI` projects. 

At the same moment, it gives u a bit less control of the process. So, up to you to decide which way to choose.


## Resources

* [`BackgroundTask`](https://developer.apple.com/documentation/backgroundtasks)
* [Using background tasks to update your app
](https://developer.apple.com/documentation/UIKit/using-background-tasks-to-update-your-app)
* [`BGProcessingTask`](https://developer.apple.com/documentation/BackgroundTasks/BGProcessingTask)
* [`BGAppRefreshTask`](https://developer.apple.com/documentation/BackgroundTasks/BGAppRefreshTask)
* [`BGTaskSchedulerPermittedIdentifiers`](https://developer.apple.com/documentation/BundleResources/Information-Property-List/BGTaskSchedulerPermittedIdentifiers)
* [AVFoundation](https://developer.apple.com/documentation/avfoundation)
* [Starting and Terminating Tasks During Development
](https://developer.apple.com/documentation/backgroundtasks/starting-and-terminating-tasks-during-development)