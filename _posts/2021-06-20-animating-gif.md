---
layout: post
comments: true
title: "Animating gif"
categories: article
tags: [iOS, gif, animations, SwiftUI, Combine, ImageIO]
excerpt_separator: <!--more-->
comments_id: 49

author:
- kyryl horbushko
- Lviv
---

I like animation a lot. Sometimes we would like to animate some complex movement of objects, and writing animation from the scratch can be a time-consuming process. As result, we can use an animated image - gif.

There are a lot of engines (free and paid) like [Lottie](https://lottiefiles.com/) that can help a lot within playing such a format. But, sometimes we don't want to use a plane for crossing a road, and a small and elegant solution can help a lot.
<!--more-->

Luckily for us, iOS has a quite good engine (finally!) that can help a lot within gif - [ImageIO](https://developer.apple.com/documentation/imageio).

Withs `ImageIO` we have all the tools we need for such operations - we can do everything on our own, or use one of the available func for automated gif animation.

> automated animations come into play starting from iOS 13

## Manual animating

This option requires a bit more work from our side, but, at the same moment, we control every aspect of the process. This is great.

Of cause, we will work with `CoreGraphics` objects such as `CGImage`, `CFData`, `CGImageSource`, and others. Be ready to make your hands dirty - as usual, with great functionality, Apple gives poor documentation, so we will dive into the code and experiment a bit.

We can start by getting data that contains gif information. This data can be obtained in different ways - from a network or disk. Let's start by assuming that we have our gif on the hard drive. So all that needs to be done - read the data of the gif file as `Data` and convert it into `CFData` (simple case `as CFData`), then, we can create [`CGImageSource`](https://developer.apple.com/documentation/imageio/cgimagesource-r84) - object that abstract the data-reading task:

{% highlight swift %}
if let resourceURL = bundle.url(
	  forResource: named,
	  withExtension: Constants.Extension.gif
	) {
  let data = try Data(contentsOf: resourceURL)
  if let source = CGImageSourceCreateWithData(data as CFData, nil) {
    if let gif = GifPlayer.animatedImageWithSource(source) {
      return gif
    } else {
      throw GifFailure.invalidSetOfImages
    }
  } else {
    throw GifFailure.noSourceData
  }
} else {
  throw GifFailure.noSourceFile
}
{% endhighlight %}

Now, using [`CGImageSource`](https://developer.apple.com/documentation/imageio/cgimagesource-r84), we can get all required information - duration and frames. To do so, we should find the number of frames 

{% highlight swift %}
CGImageSourceGetCount(source)
{% endhighlight %}

then, for each frame we should get `CGImage` by calling `CGImageSourceCreateImageAtIndex` and duration for frame. To get duration, we should read properties from data and find the desired key with a value.

{% highlight swift %}
let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
let gifProperties: CFDictionary = unsafeBitCast(
  CFDictionaryGetValue(
    cfProperties,
    Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
  ),
  to: CFDictionary.self
)
    
var delayObject: AnyObject = unsafeBitCast(
  CFDictionaryGetValue(
    gifProperties,
    Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()
  ),
  to: AnyObject.self
)
    
if delayObject.doubleValue == 0 {
  delayObject = unsafeBitCast(
    CFDictionaryGetValue(
      gifProperties,
      Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()
    ),
    to: AnyObject.self
  )
}
{% endhighlight %}

With this information, we have all the components for proper animation. The question - is how to do this animation. One way - is to calculate the total gif duration and use `UIImage` type method [`animatedImage(with:duration:)`](https://developer.apple.com/documentation/uikit/uiimage/1624149-animatedimage).

The possible code for this may look like next:

{% highlight swift %}
let count = CGImageSourceGetCount(source)
    
let images = (0..<count)
  .compactMap({ CGImageSourceCreateImageAtIndex(source, $0, nil) })
let delaysInMiliseconds = (0..<count)
  .map({ GifPlayer.delayForImageAtIndex($0, source: source) })
  .map { Int($0 * 1000.0) }
    
let durationInSeconds = Double(delaysInMiliseconds.reduce(0, +)) / 1000.0
    
let delay = delaysInMiliseconds.compactMap({ $0 }).max() ?? 1
let frames: [[UIImage]] = (0...images.count-1).map({
  let image = UIImage(cgImage: images[$0])
  let framesPerImage = Int(delaysInMiliseconds[$0] / delay)
  
  return [UIImage].init(repeating: image, count: framesPerImage)
})
let animatedImages = frames.flatMap({ $0 })
    
let animation = UIImage.animatedImage(
  with: animatedImages,
  duration: durationInSeconds
)
{% endhighlight %}

### UIKit

The logic part is completed. But We still should somehow display this on UI. In `UIKit`, we can simply create `UIImageView` and set an image for it:

{% highlight swift %}
let image = try? GifPlayer.gif(named: name)
self.imageView.image = image
self.view.addSubview(imageView)
{% endhighlight %}

`UIKit` is great, but, now we have a deal with `SwiftUI`. The naive approach for using the code above can be a simple `View` that conforms to `UIViewRepresentable`:

{% highlight swift %}
struct GifView: UIViewRepresentable {
  let name: String
  
  func makeUIView(context: Context) -> UIView {
    UIView()
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    let image = try? GifPlayer.gif(named: name)
    let imageView: UIImageView = UIImageView(image: image)    
    uiView.addSubview(imageView)
  }
}
{% endhighlight %}

This approach works, but, we can't resize the gif, and we can't control animating speed. So such an approach is not very useful.

### SwiftUI

A good solution for us should provide an option to be used in `SwiftUI` and provide an option to control its speed.

First of all, we should wrap the logic, related to extracting info from gif data into a separate component `GifDataProvider` that can extract all required data as a simple model `GifData`:

{% highlight swift %}
struct GifData {
  let images: [Image]
  let duration: Double
}
{% endhighlight %}

The next step - is to create a `ViewModifier`, that can animate change of the image using data from a provider. To make something animatable, we can use [`Animatable`](https://developer.apple.com/documentation/swiftui/animatable) protocol.

> I wrote an article about `Animatable` [here]({% post_url 2020-12-23-swiftUI-animation %}).

If we use `ViewModifier` and `Animatable` we can simply use `AnimatableModifier`. To create the one, that can animate images from the gif, we need a few components: images, duration, and progress. Using these 3 components, we can animate change of images:

{% highlight swift %}
struct GifAnimatableModifier: AnimatableModifier {
  
  private let images: [Image]
  private let duration: TimeInterval
  
  var progress: Double
  
  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }
  
  init(
    images: [Image],
    duration: TimeInterval,
    progress: Double
  ) {
    self.progress = progress
    self.images = images
    self.duration = duration
  }
  
  func body(content: Content) -> some View {
    content
      .overlay(
        imageForProgress(progress)
          .resizable()
      )
  }
  
  private func imageForProgress(_ progress: Double) -> Image {
    let durationPerImage = duration / Double(images.count)
    let currentTime = progress * duration
    let currentImage = Int(currentTime / durationPerImage)
    let idx = max(min(images.count-1, currentImage), 0)
    let image = images[idx]
    return image
  }
}
{% endhighlight %}

> `.resizable()` is needed for correctly responds to frame change


And the last components - is a `View` that wraps for our usage of this `GifAnimatableModifier`:

{% highlight swift %}
public struct Gif: View {
  
  public enum Duration {
    case `default`
    case custom(Double)
  }
  
  private let duration: Duration
  private let images: [Image]
  private let originalDuration: TimeInterval
  
  internal init(
    name: String,
    bundle: Bundle,
    duration: Gif.Duration
  ) {
    self.duration = duration
    
    let gifDataProvider = GifDataProvider(name: name, bundle: bundle)
    if let gifData = try? gifDataProvider.read() {
      self.originalDuration = gifData.duration
      self.images = gifData.images
    } else {
      self.originalDuration = 0
      self.images = []
    }
  }

  @State private var flag: Bool = false
  
  private var animation: Animation {
    switch duration {
      case .custom(let duration):
        return Animation.linear(duration: duration)
          .repeatForever(autoreverses: false)
      case .default:
        return Animation.linear(duration: originalDuration)
          .repeatForever(autoreverses: false)
    }
  }
  
  public var body: some View {
    Rectangle()
      .modifier(
        GifAnimatableModifier(
          images: images,
          duration: originalDuration,
          progress: flag ? 1 : 0
        )
      )
      .onAppear(perform: {
        withAnimation(animation) {
          flag.toggle()
        }
      })
  }
}
{% endhighlight %}

Here u can see a small trick, that allows repeat animation forever (as gifs do). I also add additional `Duration` enum, that helps to customize the playing duration of the gif.

The final usage will be next:

{% highlight swift %}
// somewhere in the body for SwiftUI view
Gif(name: "giphy", bundle: .main, duration: .default)
  .frame(width: 250, height: 200)
{% endhighlight %}

And the result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-20-animating-gif/demo_gif_option1.gif" alt="demo_gif_option1" width="350"/>
</div>
<br>
<br>

We also has an option to control speed of the gif:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-20-animating-gif/demo_speed_option_1.gif" alt="demo_speed_option_1" width="750"/>
</div>
<br>
<br>

Looks good. We of cause can improve a bit the process of timing - for now, I assumed that the delay between each frame is the same. But, in the real world, this can be different. In this case, we should modify our `GifDataProvider` and provide pair of images and delay for each frame. Of cause, in this case, the logic of frame selection in `AnimatedModifier` will bring some additional complexity.

## Automated animations

The good news is that starting from iOS 13 `ImageIO` has additional tools, that allow doing part of the work above automatically.

The interesting part for use is placed in `ImageIO.CGImageAnimation` header. There u can find `CGAnimateImageData...` functions that are specifically created for animating gif and apng formats. They also allow pausing the animation.

The initial part of the work is still the same - we should obtain gif data and then, process it. The processing can be done as follow:

{% highlight swift %}
  func animateWithFrameHandle(_ handle: @escaping (Int, CGImage) -> ()) -> OSStatus {
    let status: OSStatus = CGAnimateImageDataWithBlock(data, dictinary(), { idx, image, value in
      value.pointee = self.stop
      handle(idx, image)
    })
    return status
  }
{% endhighlight %}

where `dictionary()` - is a set of settings needed for animation:

{% highlight swift %}
[
  kCGImageAnimationStartIndex: 0,
  kCGImageAnimationDelayTime: delay * speed,
  kCGImageAnimationLoopCount: kCFNumberPositiveInfinity as Any
] as CFDictionary
{% endhighlight %}

We can pass `nil` as options - if no options are provided - then, a default will be used.

The complete code for this gif animator is next:

{% highlight swift %}
import ImageIO.CGImageAnimation

final class GifImageAnimator {
  enum GifFailure: Error {
    case noSourceFile
  }
  
  enum Extension {
    static let gif = "gif"
  }
  
  private let name: String
  private let bundle: Bundle
  private let data: CFData
  private var stop: Bool = false
  private let speed: Double
  
  init(name: String, bundle: Bundle, speed: Double = 1) throws {
    self.bundle = bundle
    self.name = name
    self.speed = speed
    
    if let resourceURL = bundle.url(forResource: name, withExtension: Extension.gif) {
      let data = try Data(contentsOf: resourceURL)
      self.data = data as CFData
    } else {
      throw GifFailure.noSourceFile
    }
  }
  
  func stopPlaying() {
    self.stop = true
  }
  
  func animateWithFrameHandle(_ handle: @escaping (Int, CGImage) -> ()) -> OSStatus {
    let status: OSStatus = CGAnimateImageDataWithBlock(data, nil, { idx, image, value in
      value.pointee = self.stop
      handle(idx, image)
    })
    return status
  }
  
  private func dictinary() -> CFDictionary {
    var delay = 0.1
    if let source = CGImageSourceCreateWithData(data as CFData, nil) {
      let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
      let gifProperties: CFDictionary = unsafeBitCast(
        CFDictionaryGetValue(
          cfProperties,
          Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
        ),
        to: CFDictionary.self
      )
      
      var delayObject: AnyObject = unsafeBitCast(
        CFDictionaryGetValue(
          gifProperties,
          Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()
        ),
        to: AnyObject.self
      )
      
      if delayObject.doubleValue == 0 {
        delayObject = unsafeBitCast(
          CFDictionaryGetValue(
            gifProperties,
            Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()
          ),
          to: AnyObject.self
        )
      }
      
      delay = max(delayObject as? Double ?? 0, 0.1)
    }
    
    return [
      kCGImageAnimationStartIndex: 0,
      kCGImageAnimationDelayTime: delay * speed,
      kCGImageAnimationLoopCount: kCFNumberPositiveInfinity as Any
    ] as CFDictionary
  }
}
{% endhighlight %}

Now, we should somehow observe the changes produced by `CGAnimateImageDataWithBlock`. And here, `Combine` can be used:

{% highlight swift %}
import Combine
import UIKit

final class GifAnimator: ObservableObject {
  private let animator: GifImageAnimator
  @Published var image: Image?
  @Published var isFailure: Bool = false

  init(name: String, bundle: Bundle, speed: Double = 1) throws {
    animator = try .init(name: name, bundle: bundle, speed: speed)
  }
  
  func startAnimating() {
    let status = animator.animateWithFrameHandle { _, frame in
      self.image = Image(uiImage: .init(cgImage: frame))
    }
    
    if status != 0 {
      isFailure = true
    }
  }
  
  func stopAnimating() {
    animator.stopPlaying()
  }
}
{% endhighlight %}

And of cause, we can wrap it into reusable `SwiftUI` `View`:

{% highlight swift %}
import SwiftUI

public struct GifPlayerView: View {
  @ObservedObject private var imageAnimator: GifAnimator

  public init(name: String, bundle: Bundle, speed: Double = 1) throws {
    imageAnimator = try .init(name: name, bundle: bundle, speed: speed)
  }
    
  public var body: some View {
    VStack {
      imageAnimator.image?
        .resizable()
    }
    .onAppear {
      imageAnimator.startAnimating()
    }
    .onDisappear {
      imageAnimator.stopAnimating()
    }
  }
}
{% endhighlight %}

Then, we can use it as next:

{% highlight swift %}
// somewhere in the body
try? GifPlayerView(name: "giphy", bundle: .main, speed: 1)
  .frame(width: 250, height: 200)
{% endhighlight %}

> this produce an optional view for `body`

And the result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-20-animating-gif/demo_gif_option1.gif" alt="demo_gif_option1" width="350"/>
</div>
<br>
<br>

[download test sources]({% link assets/posts/images/2021-06-20-animating-gif/source/source.zip %})

## Resources

* [ImageIO](https://developer.apple.com/documentation/imageio)
* [Animating Images using ImageIO](https://www.swiftjectivec.com/animating-images-using-image-io/)
* [SSSwiftUIGif](https://github.com/SimformSolutionsPvtLtd/SSSwiftUIGIFView/blob/master/Source/GIFPlayerView.swift)