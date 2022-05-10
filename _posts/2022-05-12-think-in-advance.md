---
layout: post
comments: true
title: "Think in advance"
categories: article
tags: [think, code design]
excerpt_separator: <!--more-->
comments_id: 78

author:
- kyryl horbushko
- Lviv
---

Making stuff correctly always requires more effort and more actions. Result - always returns to u with nice additions.
<!--more-->

Moving this idea into programming opens us to limitless abilities. In this article, I want to describe such an option using one task as an example that I faced recently on the project.

## problem

The designer adds an element to the screen which displays some text. Part of this text is interactable - we may tap on it and some actions should be triggered - a kind of hyperlink. 

Below is how it's look:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-05-12-think-in-advance/task.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-05-12-think-in-advance/task.png" alt="task.png" width="300"/>
</a>
</div>
<br>
<br>

Think about it. What implementation is on u'r mind? 

## how to think

Be careful when u decide which way to go. Did u think about localization, different screen sizes, what if the clickable text will be placed in the middle, and if this text changes its color? There are can be much more questions. But at least these few must be answered.

> If u think first about label and button - yes, it can work, at least for now. But, in the future, when u receive a change request, u can get a problem. Why not think about this?
> 
> Going with label+button for this task is the same for me as using view+label+imageView+gesture instead of a button. Will it works? Yes. Is it a good solution - probable not the worst?

Did u change u'r mind regarding implementation?

To make things a bit more cleaner - below are a few more examples of possible use for this component:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-05-12-think-in-advance/example.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-05-12-think-in-advance/example.png" alt="example.png" width="300"/>
</a>
</div>
<br>
<br>

Now, I guess u can see possible variants of the component usage and so possible change requests.

Now what? 

I highlighted here an idea - idea of how we should think while we make a decision. 

This is not only for this particular case - implementing part of UI, but in general - did u think about every factor, every use case (is it possible? ) during taking a decision?.

I have a conversation related to this topic in my work. 

*- There is a good principle - [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it). We can create something with so much flexibility, but we don't need it right now. Why just not use label+button. It's a completely exact as a drawn version of the design.*

Do we? It might be hard to answer at first. But do we add functionality that is not needed or do we add flexibility to the design? Do we provide some code that is going to be unused or we can create an extendable component without unused functionalities? 

<details><summary> The complete code of the solution </summary>
<p>

{% highlight swift %}

public enum TappableLabelValue {

  case userDefined(String)
  case interactive(String)

  var value: String {
    switch self {
      case .userDefined(let val):
        return val
      case .interactive(let val):
        return val
    }
  }
}

public typealias UserDefinedValue = TappableLabelValue
public typealias Interactive = TappableLabelValue

final public class TappableLabel: UILabel {

  private enum Const {

    static let detectableAttributeName = "DetectableAttributeName"
  }

  public var detectableText: [TappableLabelValue] = [] {
    didSet {
      performPreparation()
    }
  }

  public var displayableContentText: String? {
    didSet {
      performPreparation()
    }
  }

  public var mainTextAttributes: [NSAttributedString.Key: Any] = [: ] {
    didSet {
      performPreparation()
    }
  }

  public var tappableTextAttributes: [NSAttributedString.Key: Any] = [: ] {
    didSet {
      performPreparation()
    }
  }

  public var didDetectTapOnText: ((UserDefinedValue, Interactive, NSRange) -> ())?

  private var tapGesture: UITapGestureRecognizer?

  // MARK: - Public

  public func clear() {
    displayableContentText = nil
    mainTextAttributes = [: ]
    tappableTextAttributes = [: ]
    didDetectTapOnText = nil
  }

  // MARK: - Private

  private func performPreparation() {
    if self.detectableText.isEmpty == false,
       self.displayableContentText?.isEmpty == false,
       self.mainTextAttributes.isEmpty == false,
       self.tappableTextAttributes.isEmpty == false {
      self.prepareDetection()
    }
  }

  private func prepareDetection() {
    guard let searchableString = self.displayableContentText else {
      return
    }

    let attributtedString = NSMutableAttributedString(
      string: searchableString,
      attributes: mainTextAttributes
    )

    detectableText.forEach { (interactiveText) in

      var attributesForDetection: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(rawValue: Const.detectableAttributeName): interactiveText as Any
      ]

      tappableTextAttributes.enumerated().forEach { (object) in
        attributesForDetection.updateValue(object.element.value, forKey: object.element.key)
      }

      for range in searchableString.rangesOfPattern(patternString: interactiveText.value) {
        if let tappableRange = searchableString.nsRange(from: range) {
          attributtedString.addAttributes(attributesForDetection, range: tappableRange)
        }
      }
    }

    if self.tapGesture == nil {
      setupTouch()
    }

    text = nil
    attributedText = attributtedString
  }

  private func setupTouch() {
    let tapGesture = UITapGestureRecognizer(
      target: self,
      action: #selector(TappableLabel.detectTouch(_:))
    )
    addGestureRecognizer(tapGesture)
    isUserInteractionEnabled = true
    self.tapGesture = tapGesture
  }

  @objc private func detectTouch(_ gesture: UITapGestureRecognizer) {
    guard let attributedText = attributedText, gesture.state == .ended else {
      return
    }

    let textContainer = NSTextContainer(size: bounds.size)
    textContainer.lineFragmentPadding = 0.0
    textContainer.lineBreakMode = lineBreakMode
    textContainer.maximumNumberOfLines = numberOfLines

    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)

    let textStorage = NSTextStorage(attributedString: attributedText)
    textStorage.addAttribute(
      NSAttributedString.Key.font,
      value: font as Any,
      range: NSMakeRange(0, attributedText.length)
    )
    textStorage.addLayoutManager(layoutManager)

    let locationOfTouchInLabel = gesture.location(in: gesture.view)

    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    var alignmentOffset: CGFloat = 0
    switch textAlignment {
      case .left, .natural, .justified:
        alignmentOffset = 0.0
      case .center:
        alignmentOffset = 0.5
      case .right:
        alignmentOffset = 1.0
      default:
        break
    }

    let xOffset = ((bounds.size.width - textBoundingBox.size.width) * alignmentOffset) - textBoundingBox.origin.x
    let yOffset = ((bounds.size.height - textBoundingBox.size.height) * alignmentOffset) - textBoundingBox.origin.y
    let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - xOffset, y: locationOfTouchInLabel.y - yOffset)

    let characterIndex = layoutManager.characterIndex(
      for: locationOfTouchInTextContainer,
      in: textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )

    if characterIndex < textStorage.length {
      let tapRange = NSRange(location: characterIndex, length: 1)
      let substring = (self.attributedText?.string as NSString?)?.substring(with: tapRange)

      let attributeName = Const.detectableAttributeName
      let attributeValue = self.attributedText?
        .attribute(
          NSAttributedString.Key(rawValue: attributeName),
          at: characterIndex,
          effectiveRange: nil
        ) as? TappableLabelValue

      if let attributeValue = attributeValue,
         let substring = substring {
        DispatchQueue.main.async {
          self.didDetectTapOnText?(
            attributeValue,
            TappableLabelValue.interactive(substring),
            tapRange
          )
        }
      }
    }
  }
}

fileprivate extension String {

  // MARK: - String+RangeDetection

  func rangesOfPattern(patternString: String) -> [Range<Index>] {
    var ranges: [Range<Index>] = []

    let patternCharactersCount = patternString.count
    let strCharactersCount = self.count
    if strCharactersCount >= patternCharactersCount {

      for i in 0...(strCharactersCount - patternCharactersCount) {
        let from: Index = self.index(self.startIndex, offsetBy: i)
        if let toVal: Index = self.index(
          from,
          offsetBy: patternCharactersCount,
          limitedBy: self.endIndex
        ) {
          if patternString == self[from..<toVal] {
            ranges.append(from..<toVal)
          }
        }
      }
    }

    return ranges
  }

  func nsRange(from range: Range<String.Index>) -> NSRange? {
    let utf16view = self.utf16
    if let from = range.lowerBound.samePosition(in: utf16view),
       let toVal = range.upperBound.samePosition(in: utf16view) {
      return NSMakeRange(
        utf16view.distance(from: utf16view.startIndex, to: from),
        utf16view.distance(from: from, to: toVal)
      )
    }
    return nil
  }
}

{% endhighlight %}

Note: this solution was prepared few years ago, some ideas not mine - grab from web. just adapted for modern swift 5 (was swift 3 :] )

</p>
</details>

## conclusion

My rules are simple:

- think about worst cases in which u can use something, which u can meet
- handle all of them. If it's too much - maybe u want to combine a few things at one - divide and conquer.

That's it - nothing more.

Remember - u, as a programmer, must cover 5% of success cases and 95% of failures. So we are working with errors in most cases. Success - just a small chance, and if everything is done right - everybody uses this 5% ;].

## resources

* [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it)