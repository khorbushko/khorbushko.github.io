---
layout: post
comments: true
title: "My attemp to networking"
categories: article
tags: [Network, Combine, URLSession, refresh-token, longRead]
excerpt_separator: <!--more-->
comments_id: 45

author:
- kyryl horbushko
- Lviv
---

Networking - is an essential part of modern application. The good question here - what solution can we use to meet our needs. 

Often, I heard from my colleagues, that they use some library that has a lot of functions and so abilities. But in real life, they use only a few functions...
<!--more-->

If we think about this and review some advice and principles of a good coding (such as [S.O.L.I.D]({% post_url 2021-04-11-s.o.l.i.d %}))
) or so), we easily can identify the problem - *we use an airplane to cross the road*.

This is a story about my attempt at creating my network layer that fits with my requirements and provides a minimal and yet powerful network layer. 

> Under the hood `Combine` and `URLSession` are used.

## The Problem

Everything started a few years ago when I received a task to write an application that uses the customized OpenID auth process. 

The existing solutions such as `Alamofire` or some other (check out some curated list of such libraries, like [this one](https://github.com/vsouza/awesome-ios#networking)) does not provide (or provide just partially) the full aspects of the options, that I would like to use:

- strongly-typed components for requests
- authentification
- multi-thread refresh-token
- secure storage for sensitive info (tokens)
- repeating
- cancelation
- auto-mapping for response and server error

This means, that I will have a lot of additional functionality under the lib. At the same moment, a lot of unused functions still will be present in the app.  Such a situation makes me feel bad.

As a solution, I decided to write (or at least try to write my networking layer).

Of cause, I would like to have all the functions in the one lib. Looking ahead, I would say it was a bad idea :]. No, the library (it has a name - `NetLib`) was working, but it was a *super soldier*, that (I sadly admit this) can normally work only with that one project. 

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-04-my-attempt-to-networking/netlib.png" alt="first attempt to networking" width="250"/>
</div>
<br>
<br>

Was it bad? Yes, and no. Some part of it was done right:

- separate layer for each request
- ability to auto-map and parse responses
- ability to validate components of the request before it can be executed
- the ability to work with refresh token (this should be separate functionality, to be honest)
- performance

But, as I am sad, it was a super-soldier of only one project... So I can't reuse it.

At the current moment, I need something reusable, extensible, and lite, something that uses `Combine` and can be easily integrated into any environment.

My goal - to create such lib.

## The name

I was looking for a good name for a day or so. I just could not select one, but then, my son watched cartoons with moose and I decided to use `Moose` as the name of the library. 

The end of the story ;].

## Components

Before doing any work, it's good to have all building blocks in place and ready to use. 

To this building blocks we can belong the next items:

- elements defined by standart:
	- `HTTPAuthScheme`
	- `HTTPEncoding`
	- `HTTPHeaderKey`
	- `HTTPMethod`
	- `HTTPMimeType`
	- `HTTPScheme`
	- `HTTPStatusCode`
- additional elements used when building request:
	- `HTTPEndPoint`
	- `HTTPHost`

The first group (defined by the standard), I described simply by using enum. For example - here is one part from `HTTPAuthScheme`:

{% highlight swift %}
public enum HTTPAuthScheme: String {

  ///  OAuth enables clients to access protected resources by obtaining an
  ///  access token, which is defined in "The OAuth 2.0 Authorization
  ///  Framework" [RFC6749] as "a string representing an access
  ///  authorization issued to the client", rather than using the resource
  ///  owner's credentials directly.
  ///
  ///### Terminology:
  ///
  ///  A security token with the property that any party in possession of
  ///  the token (a "bearer") can use the token in any way that any other
  ///  party in possession of it can.  Using a bearer token does not
  ///  require a bearer to prove possession of cryptographic key material
  ///  (proof-of-possession).
  ///
  ///### Abstract Protocol Flow
  ///
  ///
  ///         +--------+                               +---------------+
  ///         |        |--(A)- Authorization Request ->|   Resource    |
  ///         |        |                               |     Owner     |
  ///         |        |<-(B)-- Authorization Grant ---|               |
  ///         |        |                               +---------------+
  ///         |        |
  ///         |        |                               +---------------+
  ///         |        |--(C)-- Authorization Grant -->| Authorization |
  ///         | Client |                               |     Server    |
  ///         |        |<-(D)----- Access Token -------|               |
  ///         |        |                               +---------------+
  ///         |        |
  ///         |        |                               +---------------+
  ///         |        |--(E)----- Access Token ------>|    Resource   |
  ///         |        |                               |     Server    |
  ///         |        |<-(F)--- Protected Resource ---|               |
  ///         +--------+                               +---------------+
  ///
  /// See [RFC 6750](https://tools.ietf.org/html/rfc6750),
  /// bearer tokens to access OAuth 2.0-protected resources
  case bearer = "Bearer "
  
  ...
{% endhighlight %}

Doing in the same manner for all other things, allow us to use strongly typed values instead of just a `String`. As result, the amount of typo should be minimum:


instead of this:

{% highlight swift %}
[ "Authorization": "Bearer \(accessToken)" ]
{% endhighlight %}

we now can do this:

{% highlight swift %}
[ HTTPHeaderKey.authorization.rawValue: "\(HTTPAuthScheme.bearer.rawValue)\(accessToken)" ]
{% endhighlight %}

### `HTTPEndPoint`

Each application you want to integrate with is represented by an HTTP endpoint. An endpoint provides a simple way to define the base URL and authentication credentials to use when making HTTP requests.

{% highlight swift %}
let endPoint = HTTPEndPoint(
                    scheme: .https,
                    host: .specific("api.domain.com"),
                    path: "/resourceid1/feature/function"
                  )
let url = endPoint.buildURLFor(
                       queryItems: ["item1": "value1"],
                       resourceIdItems: ["resourceid1": "12345"]
                      )
// url -> https://api.domain.com/12345/feature/function?item1=value1
{% endhighlight %}

In addition, `HTTPEndpoint` provides a possibility to build a URL from input components:

{% highlight swift %}
func buildURLFor(
	queryItems: [String: String] = [: ],
	resourceIdItems: [String: String] = [: ]
 ) -> URL? {
	let transformPath: (String) -> String = { inputPath in
	  var currentPath: String = inputPath
	  resourceIdItems.forEach {
	    currentPath = currentPath
	      .replacingOccurrences(of: $0.key, with: $0.value)
	  }
	  return currentPath
	}
	
	var urlComponents = URLComponents()
	urlComponents.scheme = scheme.rawValue
	urlComponents.host = host.name
	urlComponents.queryItems = queryItems
	  .map { URLQueryItem(name: $0.key, value: $0.value) }
	urlComponents.path = transformPath(path)
	let url = urlComponents.url
	return url
}
{% endhighlight %}

Under the hood, as u can see, I used [`URLComponents`](https://developer.apple.com/documentation/foundation/urlcomponents). 

In total, making a typo or other error related to the endpoint now is a hard task.

### `HTTPHost`

The `HTTPHost` specifies the host and (optionally) the port number of the server to which the request is being sent.

Previously, I used a string for this purpose. But, string among with simplicity brings additional errors. 

To represent the host, the next structure was created:

{% highlight swift %}
public enum HTTPHost {

    case none
    case specific(String)
    ....
{% endhighlight %}

Later on, u can just extend this type like:

{% highlight swift %}
extension HTTPHost {
  public static var adb2cMsal: HTTPHost {
    HTTPHost.specific("graph.microsoft.com")
  }
}
{% endhighlight %}

## The Request

An HTTP client sends an HTTP request to a server in the form of a request message. So, the next part of the library - is the request. 

This part created to represent few types of request (can be extended if needed):

- plain
- multipart

I think about the request - as the layer, that can hold all required information for making [`URLRequest`](https://developer.apple.com/documentation/foundation/urlrequest). I decided, that such entity should contain the next values:

- `queryParams` - a part of a uniform resource locator (URL) that assigns values to specified parameters
- `resourceParams` - this is something, that standard `URLRequest` hasn't and `URLComponents` can't handle this. URL may contains `resourceID` for example: `mydomain.com/customer/profile/2401` where `2401` - `resourceID`. Using these values, we can dynamically change such values
- `endPoint` - Name of the resource (aka `https://graph.microsoft.com/v1.0/me`)
- `method` - the HTTP request method
- `bodyParameters` - additional parameters to message body.
- `headers` - a dictionary containing all of the HTTP header fields for a request. Each request can have some unique headers
- `usePrivateHeaders` - a simple flag, that indicate, that headers supplied by the session should be ignored
- `body` - the data sent as the message body of a request
- `timeout` - configure specific (instead of session-configurated) timeout for request

Wow, that's a lot, especially when we think about configuration separate requests... To simplify this, most parameters have a default implementation, and only critical one hasn't.

This implemented as a protocol with extension for default implementation:

{% highlight swift %}
public protocol HTTPRequest {
  var type: HTTPRequestKind { get }
  var queryParams: [String: String]? { get }
  ...
}

/// Default implementation
extension HTTPRequest {
  public var timeout: TimeInterval? {
    nil
  }
  
  public var body: Data? {
    if let bodyParameters = bodyParameters {
      let data = Data.jsonDataFromObj(bodyParameters as AnyObject)
      return data
    }
    return nil
  }
  
  ...
}
{% endhighlight %}

This means, that the minimal request can be created as:

{% highlight swift %}
struct UserGETRequest: HTTPRequest {
  var endPoint: HTTPEndPoint {
    .userInfo
  }

  var method: HTTPMethod {
    .GET
  }
}
{% endhighlight %}

This is good for the simple request (aka plain), but, if u have a deal with multipart-request, where HTTP body is a representation of one or more different sets of data, we need a special format. To solve this, I added `HTTPMultipartData` type, that encapsulate all information:

{% highlight swift %}
public struct HTTPMultipartData {

  public let mimeType: HTTPMimeType
  public let rawData: Data
  public let dataName: String
  public let dataKey: String
  public let bodyParameters: [String: AnyObject]
  
  var encoding: String.Encoding {
    .utf8
  }
  
  var header: [String: String] {
    [
      "\(HTTPEncoding.multipart); boundary=\(boundary)": HTTPHeaderKey.contentType.rawValue
    ]
  }
  
  var body: Data {
    var body = Data()

    if let boundaryStartData = "--\(boundary)\(endLine)".data(using: encoding),
       let fileNameData = "\(HTTPHeaderKey.contentDisposition.rawValue):form-data; name=\"\(dataKey)\"; filename=\"\(dataName)\"\(endLine)".data(using: encoding),
       let contentTypeData = "\(HTTPHeaderKey.contentType.rawValue): \(mimeType.rawValue)\(endLine)\(endLine)".data(using: encoding),
       let endLineData = "\(endLine)".data(using: encoding),
       let boundaryEndData = "--\(boundary)--\(endLine)".data(using: encoding) {

      bodyParameters.forEach { (pair) in
        if let key = "\(HTTPHeaderKey.contentDisposition.rawValue): form-data; name=\"\(pair.key)\"\(endLine)\(endLine)".data(using: encoding),
           let value = "\(pair.value)\(endLine)".data(using: encoding) {

          body.append(boundaryStartData)
          body.append(key)
          body.append(value)
        }
      }

      body.append(boundaryStartData)
      body.append(fileNameData)
      body.append(contentTypeData)
      body.append(rawData)
      body.append(endLineData)
      body.append(boundaryEndData)
    }

    return body
  }
  
  // MARK: - Lifecycle
  
  public init(
    mimeType: HTTPMimeType,
    rawData: Data,
    dataName: String,
    dataKey: String,
    bodyParameters: [String: AnyObject]
  ) {
    self.mimeType = mimeType
    self.rawData = rawData
    self.dataKey = dataKey
    self.dataName = dataName
    self.bodyParameters = bodyParameters
  }

  // MARK: - Private

  private var endLine: String {
    "\r\n"
  }

  private var boundary: String {
    "Boundary-\(UUID().uuidString)"
  }
}
{% endhighlight %}

and extend `HTTPRequest` to `HTTPMultipartRequest`:

{% highlight swift %}
public protocol HTTPMultipartRequest: HTTPRequest {
  
  /// Representation of one or more different sets of data
  var multipartData: HTTPMultipartData { get }
}

extension HTTPMultipartRequest {
  public var type: HTTPRequestKind {
    .multipart
  }
  
  public var body: Data? {
    multipartData.body
  }
}
{% endhighlight %}

## The Response

After receiving and interpreting a request message, a server responds with an HTTP response.

But the most interesting part - is handling response. Ideally for us, if we can receive not just data, but the concrete object. And here is the job for `Mapper` - a special type, that can parse received data, inspect for error, and, using `JSONDecoder`, decode it into expected types.

My mapper is very simple, but yet powerful:

{% highlight swift %}
open class ObjectMapper<T, E> where T: Decodable, E: ServerErrorType {
  enum Failure: Error {
    case notImplemented
  }
  
  public init() {
    // expose to public
  }
  
  open func errorDataMapper(_ data: Data) throws -> E? {
    throw Failure.notImplemented
  }
  
  open func objectDataMapper(_ data: Data) throws -> T? {
    throw Failure.notImplemented
  }
}
{% endhighlight %}

And concrete realization may be as follow:

{% highlight swift %}
public class ServerErrorObjectMapper<T>: ObjectMapper<T, ServerError> where T: Decodable {
  
  public override func errorDataMapper(_ data: Data) throws -> ServerError? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(formatter)
    
    let object = try decoder.decode(ServerError.self, from: data)
    return object
  }
  
  public override func objectDataMapper(_ data: Data) throws -> T? {
    let decoder = JSONDecoder()
    let object = try decoder.decode(T.self, from: data)
    return object
  }
}
{% endhighlight %}

And then, using already presented `UserGETRquest`:

{% highlight swift %}
final class UserMapper: ServerErrorObjectMapper<User> { }
{% endhighlight %}

> I placed mapper inside request as an inner class - this simplifies support of every request. 

That's it - 1 line of code ;].

`HTTPResponse` also should include a few more additional information - same as `URLDataTask` can return to us:

{% highlight swift %}
public protocol HTTPResponse {

  var request: HTTPRequest { get }
  
  var response: URLResponse { get }
  
  var data: Data { get }
    
  
  // MARK: - Autogenerated
  
  var status: HTTPStatusCode? { get }
  
  var message: String? { get }
  
  var headers: [AnyHashable: Any] { get }
}
{% endhighlight %}

## Client

This is the most interesting part, thus all components are combined here.

It includes:

- `NetworkAuthentificator` - responsible for auth user and refresh-token dance. `TokenRepresentable` is a helper type, that wraps usage of token.
- `NetworkManager` - create network client and execute requests
- `NetworkSession` - the driver for `NetworkManager`
- `NetworkSessionConfiguration` - parameters which can change behavior of the networking, used by `NetworkSession` 
- Few other supportive types.

> Default *driver for `NetworkManager`* is `URLSession`.

Let's briefly check out each component.

### `NetworkAuthentificator`

Judging on name, I guess u already know the purpose of this component - yes, to allow authenticate the user, to perform refresh-token dance, to make other auth-related stuff.

Initially, I was thinking, that these components should handle auth, especially refresh-token dance.

U know, often, we have a lot of requests that can be executed in parallel. And the situation, when all of them fail due to expired `access_token` is not a rare one. In the first version (`NetLib`), I tried to handle it inside the library, but, after developing and using such an approach, I definitely saw the big disadvantages of such an approach - reuse and support of code is terrible. So, I decided to make an abstraction for this.

{% highlight swift %}
public protocol Authorizable {
  
  func authorize() -> AnyPublisher<TokenRepresentable, Error>
  func editProfile() -> AnyPublisher<TokenRepresentable, Error>
  func refreshToken(force: Bool) -> AnyPublisher<TokenRepresentable, Error>
  func logout() -> AnyPublisher<Void, Error>
}
{% endhighlight %}

Anyway, I also would like to tell what approaches can be used to efficiently handle such a scenarious.

### Handling parallel refresh requests for accessToken

I faced this problem on every project, that has network and auth. 

As for me, there are a few possible solutions:

#### OperationQueue

By using `OperationQueue` we can abstract each request into `Operation` and, when we detect refresh-token request, using `GCD` we can provide a shared request for every requestor. Thus, each request is `Operation`, we can also use operation dependencies, to make sure, that nothing is executed before refresh-token `Operation`.

Such approach mix `CGD` and `OperationQueue`, also, custom [`AsyncOperation`](https://www.avanderlee.com/swift/asynchronous-operations/) is required.

The downside of this approach - is a lot of code, a mix of technologies, complexity.

> Exactly this approach was used in `NetLib`.

#### `CGD`: `DispatchWorkItem` and `DispatchQueue` 

This approach requires storing the token, and before executing, every request - check the token validity, check if any token refresh is in progress, and put a request in a special queue ( as a `DispatchWorkItem`). When token refreshed - execute the requests in a queue.

If u calculate/determine the validity of the token incorrectly, or if u have a bad connection, u may be faced with a problem, that while the request is executed, the access token becomes invalid. In this case, additional repeating of the request may require after the refresh-token request.

This, as for me, a bit easier solution than above, but, it can become a bit tricky, especially with request repeating.

Possible solution can be found [here](https://stackoverflow.com/a/56912806).

#### Set limit to 1 request in parallel

This is a **workaround**. I don't think that some explanation is required here, but It worth mentioning.

#### Use `Combine` 

Using `Combine` framework, we can, truly speaking, reuse the same approach - store all requests in queue and on refresh, pause everyone request, using `share()` publisher execute the refresh-token request and repeat request.

A great description of this process is described [here](https://www.donnywals.com/building-a-concurrency-proof-token-refresh-flow-in-combine/).

> More about `share` and other similar publishere u can find [here]({% post_url 2021-02-20-save-resources %}).


As u can see, we can use different technologies, but **approach** is pretty the same:

- create an abstraction on `Request`, to allow repeat, reuse
- create a queue for a `Request`s
- create a retrier for `Request`s
- store token and token-request for sharing to every `Request`
- set dependency on every request to token-request (if it in progress) and token
- in case of the expired token, start token-request and set it as a dependency to all request
- in case if un-auth error received - start token-request and set it as a dependency to all request, and repeat failed request on success

### `NetworkSessionConfiguration`

The next part - is `NetworkSessionConfiguration`. As u can see from the name, this item contains some shared settings such as timeout, headers, contentType, etc.

In general, it wraps [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration) and contains some default settings:

{% highlight swift %}
contentType: HTTPMimeType = .json,
timeOut: TimeInterval = 20,
resourceTimeout: TimeInterval = 40,
maxConnectionCount: Int = 10
{% endhighlight %}

### `NetworkSession`

This is a place, where the magic happens - the place where all the above components are connected:

{% highlight swift %}
public protocol NetworkSession: AnyObject {
  
  static func build(configuration: NetworkSessionConfiguration) -> NetworkSession
  
  func publisher<T: Decodable, E: ServerErrorType>(
    for request: HTTPRequest,
    mapper: ObjectMapper<T, E>,
    token: TokenRepresentable?
  ) -> AnyPublisher<(T, HTTPResponse), Error>
}
{% endhighlight %}

Yes, this is just a protocol. And we can use concrete realization of it, for example with [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession). The most interesting part - is `public func publisher(for: mapper: token:)`

{% highlight swift %}
  public func publisher<T, E>(
    for request: HTTPRequest,
    mapper: ObjectMapper<T, E>,
    token: TokenRepresentable?
  ) -> AnyPublisher<(T, HTTPResponse), Error> where T : Decodable, E: ServerErrorType {
    
    if let urlRequest = buildURLRequestFrom(
      request: request,
      token: token
    ) {
      
      return dataTaskPublisher(for: urlRequest)
        .tryMap { (data: Data, response: URLResponse) in

          if let httpResponse = response as? HTTPURLResponse,
             let statusCode = HTTPStatusCode(HTTPResponse: httpResponse),
             statusCode != HTTPStatusCode.ok {
            
            let error = try mapper.errorDataMapper(data)
            if let serverError = error {
              throw serverError
            } else {
              throw NetworkSessionFailure.requestProcessing(.unknownResponseData(data))
            }
            
          } else {
            
            let decodedObject = try mapper.objectDataMapper(data)
            if let decodedObject = decodedObject {
              
              let httpProcessedResponse = ConcreteResponse(
                request: request,
                response: response,
                data: data
              )
              
              return (decodedObject, httpProcessedResponse)
            } else {
              let hint = """
                Looks like type of object is not the one that is expected
                in request \(T.self).
                
                Actual data =\n\(String(describing: String(data: data, encoding: .utf8)))
                """
              throw NetworkSessionFailure.requestProcessing(.unexpectedObjectTypes(hint))
            }
          }
        }
        .eraseToAnyPublisher()
      
    } else {
      return Fail(error: NetworkSessionFailure.requestPreparation(.invalidURL))
        .eraseToAnyPublisher()
    }
  }
{% endhighlight %}

and `buildURLRequestFrom` - uses `HTTPRequest` and `TokenRepresentable` as input:

{% highlight swift %}
  private func buildURLRequestFrom(
    request: HTTPRequest,
    token: TokenRepresentable?
  ) -> URLRequest? {
    if let url = request.url {
      var buildingRequest = URLRequest(url: url)
      buildingRequest.httpMethod = buildingRequest.httpMethod
      buildingRequest.timeoutInterval = request.timeout ?? configuration.timeoutIntervalForRequest
      
      var allheaders: [String: String] = [: ]
      if let headers = request.headers {
        allheaders = headers
      }
      
      if !request.usePrivateHeaders {
        let accessHeaders = token?.accessHeader ?? [: ]
        allheaders = allheaders.merging(accessHeaders) { $1 }
      }
      buildingRequest.allHTTPHeaderFields = allheaders
      buildingRequest.httpBody = request.body
      
      return buildingRequest
    } else {
      return nil
    }
  }
{% endhighlight %}

## Usage example

The good question - is how can we use it. 
I used this in my current project with [`MSAL`](https://github.com/AzureAD/microsoft-authentication-library-for-objc) auth library. 

> Because this library is written on Obj-C, I also create a wrapper for it for better usage with `Combine`, but this is a bit another story. 

### Step 1 - Create authentificator

This step is slightly domain-specific and in my case related to `MSAL` library.

To good point to mention - is that `NetworkAuthentificator` handle the case with refresh-token dance described above:

{% highlight swift %}
  public func refreshToken(force: Bool) -> AnyPublisher<TokenRepresentable, Error> {
  
  	// check if refresh token request is in progress
  	// if so - return it
    if let publisher = refreshTokenPub {
      return publisher
    }
    
    // check if access-token is valid
    if let token = accessToken,
       !token.isExpired,
       !force {
      return Just(token)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    // create request for refresh token
    let publisherToReturn: AnyPublisher<TokenRepresentable, Error> =
      msalProvider
      .refreshToken() // library specific implementation
      .share() // <- important, share to handle multi-requests
      .tryMap { result in
        do {
          let rawToken = result.accessToken
          let token = try MSALToken(raw: rawToken, type: .access)
          
          self.accessToken = token
          
          return token
        } catch {
          throw error
        }
      }
      .handleEvents(receiveCompletion: { [weak self] _ in
        self?.refreshQueue.sync {
          self?.refreshTokenPub = nil
        }
      })
      .eraseToAnyPublisher()
    
    self.refreshTokenPub = publisherToReturn
    
    return publisherToReturn
  }
{% endhighlight %}

### Step 2 - Create manager

The purpose of the manager (or name it as u wish), is to hold all components together `NetworkManager` and `NetworkAuthentificator`:

{% highlight swift %}
final public class MSALNetworkManager {
  internal let networkManager: NetworkManager
  internal let authentificator: NetworkAuthentificator
  
  // MARK: - Lifecycle
  
  public init(
    contentType: HTTPMimeType = .json,
    timeOut: TimeInterval = 20,
    resourceTimeout: TimeInterval = 40,
    maxConnectionCount: Int = 10,
    additionalHeaders: [AnyHashable : Any] = [: ],
    host: HTTPHost,
    configFileName: String,
    configFileBundle: Bundle
  ) throws {
    
    let msalProvider = try MSALProvider(
      configFileName: configFileName,
      configFileBundle: configFileBundle
    )
    
    let msalAuth = MSALAuthentificator(msalProvider: msalProvider)
    self.authentificator = msalAuth
    
    networkManager = .init(
      contentType: contentType,
      timeOut: timeOut,
      resourceTimeout: resourceTimeout,
      maxConnectionCount: maxConnectionCount,
      additionalHeaders: additionalHeaders,
      host: host,
      authentificator: msalAuth
    )
  }
}
{% endhighlight %}

The best way to check if everything is work as expected - is to test the code: with unit tests and in real life scenario. To do the second part I used [Charles](https://www.charlesproxy.com):

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-04-my-attempt-to-networking/refresh_shared.png" alt="shared refresh" width="750"/>
</div>
<br>
<br>

> here u can see multiply requests, and the same instance returned to all of them. In Charles - only one token request. That's what we want.

### Step 3 - Create request

To create the `Request` simply define the endpoint, create `HTTPRequest` with `Mapper` and extend `Manager`.

First 2 steps I already introduced earlier, the 3rd one:

{% highlight swift %}
extension MSALNetworkManager {

  // MARK: - MSALNetworkManager+User

  public func fetchUserInfo() -> AnyPublisher<User, Error> {
    let request = UserGETRequest()
    let mapper = UserGETRequest.UserMapper()
    return networkManager.executeRequest(request, mapper: mapper)
          .tryMap { result -> User in
              let user = result.0
              return user
            }
          .eraseToAnyPublisher()
  }
}
{% endhighlight %}

### Step 4 - Execute request

This is the final one. (of cause tests are welcome ;]). 

The execution becomes as simple as just call 1 function:

{% highlight swift %}
func getUser() {
  msalAPi?.fetchUserInfo()
    .sink(receiveCompletion: { completion in
      print(completion)
    }, receiveValue: { result in
      print(result)
    })
  .store(in: &cancellable)
}
{% endhighlight %}

## Conclusion

This was a long read... 

In total, using `Combine` for this library makes it an *elegant* one. 

I do believe, that some improvements still need to be added, but, the core functionality already here.

## Resources

* [RFC 7617](https://tools.ietf.org/html/rfc7617)
* [RFC 6750](https://tools.ietf.org/html/rfc6750)
* [Encoding](https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4)
* [RFC3864](https://www.iana.org/go/rfc3864)
* [message-headers](http://www.iana.org/assignments/message-headers/message-headers.xhtml)
* [MIME types](http://www.iana.org/assignments/media-types/media-types.xhtml)
* [Common schemes used for the HTTP protocol](https://tools.ietf.org/html/rfc7230)
* [IANA HTTP status code registry](http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)
* [`URLComponents`](https://developer.apple.com/documentation/foundation/urlcomponents)
* [`URLRequest`](https://developer.apple.com/documentation/foundation/urlrequest)
* [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration)
* [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession)
* [Decode JWT (JSON web token)](https://github.com/auth0/JWTDecode.swift/blob/master/JWTDecode/JWTDecode.swift)
* [swift-combine-retry.md](https://gist.github.com/rdv0011/200f0edf9a2e244daa72e514fc314c56)
* [Retrying a network request with a delay in Combine](https://www.donnywals.com/retrying-a-network-request-with-a-delay-in-combine/)
* [Building a concurrency-proof token refresh flow in Combine](https://www.donnywals.com/building-a-concurrency-proof-token-refresh-flow-in-combine/)
* [Refactoring a networking layer to use Combine](https://www.donnywals.com/refactoring-a-networking-layer-to-use-combine/)
* [RxSwift and Handling Invalid Tokens](https://danielt1263.medium.com/retrying-a-network-request-despite-having-an-invalid-token-b8b89340d29)
* [SO: Parallel refresh requests of OAuth2 access token with Swift p2/OAuth2](https://stackoverflow.com/questions/34724300/parallel-refresh-requests-of-oauth2-access-token-with-swift-p2-oauth2)
* [SO: Handle multiple unauthorized requests after access token expires](https://stackoverflow.com/questions/43026866/handle-multiple-unauthorised-requests-after-access-token-expires)
* [SO: access token with MSAL](https://stackoverflow.com/questions/51332122/access-token-refresh-token-with-msal)
* [Alamofire](https://github.com/Alamofire/Alamofire)
* [Networking](https://www.swiftbysundell.com/basics/networking/)
* [Creating generic networking APIs in Swift](https://www.swiftbysundell.com/articles/creating-generic-networking-apis-in-swift/)