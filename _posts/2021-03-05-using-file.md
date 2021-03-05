---
layout: post
comments: true
title: "a File"
categories: article
tags: [iOS, FileHandle, FileManager, DispathIO, Files, Stream]
excerpt_separator: <!--more-->
comments_id: 32

author:
- kyryl horbushko
- Lviv
---

Managing data always was and will be the main concept behind any application for any platform and at any time. But how we can do this? How to manage data between different sessions of app usage? 

One of the simplest and still perfect ways to do this is by using files. 
<!--more-->

*"A computer file is a computer resource for recording data in a computer storage device."* - according to [wiki](https://en.wikipedia.org/wiki/Computer_file).

On the iOS platform luckily for us there is a bunch of ways how can perform various manipulations within the file (different `CRUD` operations):

* `Foundation`s framework way
* `FileManager`
* `FileHandle`
* Files
* `DispathIO`
* Stream
* C++ API

> CRUD - Create Read Update Delete

## `Foundation`s framework way

`Foundation` is a base framework that we use in every app. If we check API from it, we will find a lot of methods/functions that allow us to perform various manipulations within a file. The most known types are: `String`, `Dictionary`, `Data`, `Array`, etc.

In most cases concrete Type supports only basic functionality:

- read
- write

I will show examples only for `Data` type, all other has something similar or specific for concrete type.

### Data

The `Data` type - is a basic type that can represent information. It represents a byte buffer in memory.
For basic operations like save/read here are a few code snippets.

To **save** data into file we can:

{% highlight swift %}
do {
	try someData?.write(to: filePath)
} catch {
	// handle error
}
{% endhighlight %}

To **read** data from the file:

{% highlight swift %}
do {
    let data = try? Data(contentsOf: fileURL, options: [<options>])
    // use data
} catch {
    print(error)
}
{% endhighlight %}

## FileManager

[`FileManager`](https://developer.apple.com/documentation/foundation/filemanager) is one of the simplest ways to work within a file. Using `FileManager` we can do all most common operations:

* create
* read
* update
* move
* delete

> we can also use this class for work with directories, not just for files.

To demonstrate all possibilities related to files, we first should obtain an instance of FileManager. To do this, we can use either shared instance either create or own:

{% highlight swift %}
let fileManager = FileManager.default
// or
let fileManager = FileManager()
{% endhighlight %}

> This method always represents the same file manager object. If you plan to use a delegate with the file manager to receive notifications about the completion of file-based operations, you should create a new instance of FileManager (using the init method) rather than using the shared object. [[source](https://developer.apple.com/documentation/foundation/filemanager/1409234-default)].

### Create

To create file we can use simple snipet:

{% highlight swift %}
let someData = "hello world!".data(using: .utf8)
let isCreated = fileManager.createFile(atPath: filePath.path, contents: someData, attributes: nil)
{% endhighlight %}

### Read

Reading is also trivial operation - all u need, its just a path:

{% highlight swift %}
let data = fileManager.contents(atPath: filePath.path)
{% endhighlight %}

### Update

Update operation is a bit tricky - using any approach, its require at least 2 operations - find what to update and perform update. 

I will asume in my samples, that we would like simply append some information to the end of the file (in real-world scenarious, u probably needs to find concrete postion for replacement or appending content):

{% highlight swift %}
if let data = fileManager.contents(atPath: filePath.path) {
	if let stringInFile = String(data: data, encoding: .utf8) {
		let newContent = "content"
	 	let updatedContent = stringInFile + newContent // <-- update
	 	let isCreated = fileManager.createFile(atPath: filePath.path, contents: updatedContent.data(using: .utf8), attributes: nil) // <-- recreate with updated content as a workaround
	 	print(isCreated)
	} else {
 		print("Nothing in file")
	}
}
{% endhighlight %}

> Update is not supported by FileManager, that why we can use a workaround - recreate the file instead. 
> 
> From the [official documentation](https://developer.apple.com/documentation/foundation/filemanager) - "You use it to **locate**, **create**, **copy**, and **move** files and directories. You also use it to **get information about** a file or directory or change some of its attributes."

### Move

To change position of a file, we can simply calling only one method:

{% highlight swift %}
do {
  try fileManager.moveItem(atPath: filePath.path, toPath: newURL.path)
  print("Moved successfully")
} catch {
  print("Error: \(error.localizedDescription)")
}
{% endhighlight %}

### Delete

To remove unnecessary element fom file system:

{% highlight swift %}
do {
  try fileManager.removeItem(atPath: filePath.path)
} catch {
  print(error)
}
{% endhighlight %}

## FileHandle

[`FileHandle`](https://developer.apple.com/documentation/foundation/filehandle) is a less known, but yet powerful class for working with files. The list of operations is quite different from that one used in `FileManager`, but usage is much simpler. 

Also, this class provides additional possibilities - it allows us to work not only within files, but with sockets, pipes, and devices. 

As we are talking about a files, we can:

* read
* write
* seek
* update
* truncate

> It's good to know, that `FileHandle` can create asynchronous background I/O operations, so u can use it in systems, where u would like to save some resources for I/O operations.

To use the possibilities of `FileHandle`, we should create an instance of this class by using one of the existing initializers. The key-point here - we should use init based on our needs. I will show u different initializations of this object below in each examples.

### Read

Read is essential part of data management, and `FileHandle` has a perfect method for this:

{% highlight swift %}
let fileHandler = FileHandle(forReadingAtPath: filePath.path)
let buffer = fileHandler?.readDataToEndOfFile()
{% endhighlight %}

### Write

To write something in a file we can use next snipet:

{% highlight swift %}
if let fileHandler = FileHandle(forWritingAtPath: filePath.path),
  let someData = "hello world!".data(using: .utf8) {
	fileHandler?.write(someData)
}
{% endhighlight %}

> With `FileHandle` we can't write data to file if the file does not exist.

### Seek

{% highlight swift %}
let file: FileHandle? = FileHandle(forUpdatingAtPath: filePath.path)
if file != nil {
  let data = " and goodbuy".data(using: .utf8)

  // option 1 - set offset
  let offset = 100
  file?.seek(toFileOffset: UInt64(offset))
  // option 2 - seek the end of file
  file?.seekToEndOfFile()
  // do any other operations with content and file
}
{% endhighlight %}

### Update

{% highlight swift %}
let file: FileHandle? = FileHandle(forUpdatingAtPath: filePath.path)
if file != nil {
  let data = «content".data(using: .utf8)
  file?.seekToEndOfFile()
  file?.write(data!)
  file?.closeFile()
}
{% endhighlight %}

### Truncate

Remove is not available as an option for `FileHandle`. 
We can, instead, truncate the content:

{% highlight swift %}
let file: FileHandle? = FileHandle(forUpdatingAtPath: filePath.path)
if file == nil {
  print("File open failed")
} else {
  file?.truncateFile(atOffset: 0)
  file?.closeFile()
}
{% endhighlight %}

## Files

*"The Files app brings all of your files together in iOS 11 or later. You can easily browse, search, and organize all your files in one place. Not just the ones on the device you're using, but also those in apps, on your other iOS devices, in iCloud Drive, and across other cloud services."* [more](https://support.apple.com/en-us/HT206481).

We also can use `UIDocument` that also can represent data from files. Using this class we can create and read information from files in our apps. To do this, we should describe this feature in metadata of the app - using plist:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-03-05-using-file/files.png" alt="files" width="450"/>
</div>
<br>

Then, define `UIDocument` subclass that will represent the content of a file and provide some UI for manipulating with files on our file system.

The simplest code for doing this can be as next:

Document description:

{% highlight swift %}
import UIKit

final class MyDocument: UIDocument {

  private (set) var stringValue: String?

  override func contents(forType typeName: String) throws -> Any {
    return Data()
  }

  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    if let contentData = contents as? Data {
      stringValue = String(data: contentData, encoding: .utf8)
    }
  }
}
{% endhighlight %}

Document preview:

{% highlight swift %}
import UIKit

final class DocumentViewController: UIViewController {

  @IBOutlet private weak var documentNameLabel: UILabel!
  @IBOutlet private weak var textView: UITextView!

  var document: UIDocument?

  // MARK: - LifeCycle

  override func viewDidLoad() {
    super.viewDidLoad()

    document?.open(completionHandler: { (success) in
      if success {
        self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
        self.textView.text = (self.document as? MyDocument)?.stringValue
      }
    })
  }

  @IBAction private func dismissDocumentViewController() {
    dismiss(animated: true) {
      self.document?.close(completionHandler: nil)
    }
  }
}
{% endhighlight %}

Document picker:

{% highlight swift %}
import UIKit

final class DocumentPreviewViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    allowsDocumentCreation = true
    allowsPickingMultipleItems = false
  }

  // MARK: UIDocumentBrowserViewControllerDelegate

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
      importHandler(nil, .none)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
    guard let sourceURL = documentURLs.first else { return }
    presentDocument(at: sourceURL)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
    presentDocument(at: destinationURL)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
  }

  // MARK: Document Presentation

  func presentDocument(at documentURL: URL) {
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
    documentViewController.document = MyDocument(fileURL: documentURL)
    present(documentViewController, animated: true, completion: nil)
  }
}
{% endhighlight %}

> Off cause document representation and preview is non-real-world and used just for simplification of the approach presentation.

## DispathIO

`DispatchIO` - An object that manages operations on a file descriptor using either stream-based or random-access semantics. [source](https://developer.apple.com/documentation/dispatch/dispatchio).

`DispatchIO` can perform only a few operations within the file descriptor:

- read
- write

U should use this class when u have a large file and u need to efficiently work within it.

### Read

{% highlight swift %}
import Foundation

final class DispatchIOReader {

  typealias IsReadingCompleted = Bool

  enum Failure: Error {
    case cantFindFile
    case cantFindChannel
    case readingIssue(Int32)
  }

  var channel: DispatchIO?

  init(_ path: String) throws {
    let inputPath = [Int8](path.utf8.map { Int8($0) })
    channel = DispatchIO(
      type: .random,
      path: inputPath,
      oflag: 0,
      mode: 0,
      queue: .main,
      cleanupHandler: { (errCode) in

      })

    if channel == nil {
      throw Failure.cantFindFile
    }

    channel?.setLimit(lowWater: .max)
  }

  deinit {
    channel?.close()
    channel = nil
  }

  // MARK: - Public

  func read(
    byteRange: CountableRange<Int>,
    queue: DispatchQueue = .main,
    completion: @escaping (Result<(DispatchData?, IsReadingCompleted), Error>) -> Void
  ) throws {
    if let channel = channel {
      channel.read(
        offset: off_t(byteRange.startIndex),
        length: byteRange.count,
        queue: queue,
        ioHandler: { done, data, errorCode in
          if errorCode != 0 {
            completion(.failure(Failure.readingIssue(errorCode)))
          } else {
            completion(.success((data, done)))
          }
      })
    } else {
      throw Failure.cantFindChannel
    }
  }
}
{% endhighlight %}

usage:

{% highlight swift %}
let path = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
let file = path?.appendingPathComponent("CreatedFile.txt")

if let dispatchReader = try? DispatchIOReader(file!.path) {
  try? dispatchReader.read(byteRange: 0..<300) { (result) in
    switch result {
      case .failure(let error):
        print(error)
      case .success(let resultTuple):
        let data = resultTuple.0?.compactMap({ UInt8($0) }) ?? []
        let text = String(data: Data(data), encoding: .utf8)
        print("Read - ", text)
    }
  }
}
{% endhighlight %}

>  [`off_t`](https://www.gnu.org/software/libc/manual/html_node/File-Position-Primitive.html) - This is a data type defined in the sys/types.h header file (of fundamental type unsigned long) and is used to measure the file offset in bytes from the beginning of the file. It is defined as a signed, 32-bit integer, but if the programming environment enables large files off_t is defined to be a signed, 64-bit integer.

### Write

Write with `DispatchIO` is a similar operation - simply open channel and execute [`write(offset:data:queue:ioHandler:)`](https://developer.apple.com/documentation/dispatch/dispatchio/1388932-write).

> Dispatch framework is very powerful, but most of the developers didn't use its power - instead, only `Dispatch.main.async` was used. If u would like to find more - u can start by checking [Bruno Rocha's article about DispatchSouce](https://swiftrocks.com/dispatchsource-detecting-changes-in-files-and-folders-in-swift).

## Stream

[`Stream`](https://developer.apple.com/documentation/foundation/stream) - it's and abstractions, that allow us to manipulate the data over. In `Foundation` framework we have [`InputStream`](https://developer.apple.com/documentation/foundation/inputstream) and [`OutputStream`](https://developer.apple.com/documentation/foundation/outputstream)for reading and writing.

In the context of a file, using streams, we can:

- read
- write

### Read

{% highlight swift %}
let path = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
let file = path?.appendingPathComponent("CreatedFile.txt")

let inputStr = InputStream(url: file!)
inputStr?.open()
while inputStr?.hasBytesAvailable == true {
  let buff = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
  let readLen = inputStr?.read(buff, maxLength: 5)

  let bytesArray = UnsafeBufferPointer(start: buff, count: 8).map { $0 }
  print("read \(readLen) bytes ", String(data: Data(bytesArray), encoding: .utf8))
}
inputStr?.close()
{% endhighlight %}

output:

{% highlight swift %}
read Optional(5) bytes  Optional("Hello\0\0 ")
read Optional(5) bytes  Optional(" worl\0\0 ")
read Optional(1) bytes  Optional("d\0\0\0\0\0\0 ")
read Optional(0) bytes  Optional("\0\0\0\0\0\0\0 ")
{% endhighlight %}

### Write

{% highlight swift %}
let outputStream = OutputStream(url: file!, append: true)
outputStream?.open()

let data = "Aloha".data(using: .utf8)
var buffer = Array(data!)
let result = outputStream?.write(&buffer, maxLength: 5)
print("write \(result) bytes ", String(data: try! Data(contentsOf: file!), encoding: .utf8))
outputStream?.close()
{% endhighlight %}

output:

{% highlight swift %}
write Optional(5) bytes  Optional("Hello worldAloha")
{% endhighlight %}

> There is a lot of discussions about `Stream` usage, for example [this one](https://forums.swift.org/t/make-inputstream-and-outputstream-methods-safe-and-swifty/23726).

## C++ API

Another option for file manipulation use C++ API like [`fopen`](http://www.cplusplus.com/reference/cstdio/fopen/) and support functions.

We can perform all basic operations within files like:

- write/create
- read
- seek
- update
- delete

We can use different variants of accessMode and perform various operations, for example - "rb", "wb", "ab", "r+b", "w+b", "a+b", etc.

### Write/Create

{% highlight swift %}
import Foundation

final class FileWriter {

  enum Failure: Error {
    case cantCreateFile(String)
    case writeError
  }

  private var file: UnsafeMutablePointer<FILE>?

  init(_ path: String) throws {
    file = fopen(path, "w")
    if file == nil {
      throw Failure.cantCreateFile(path)
    }
  }

  deinit {
    fclose(file)
  }

  func write(_ text: String) throws {
    let buffer = [UInt8](text.utf8)
    let writtenCharCount = fwrite(buffer, MemoryLayout<UInt8>.size, buffer.count, file);

    // chronize a file's in-core state with storage device
    // map a stream pointer to a file descriptor
    fsync(fileno(file));

    if writtenCharCount != buffer.count {
      throw Failure.writeError
    }
  }
}
{% endhighlight %}

usage:

{% highlight swift %}
let path = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
let file = path?.appendingPathComponent("CreatedFile.txt")

if let writer = try? FileWriter(file!.path) {
  let text = "Hello world"
  try? writer.write(text)
}
{% endhighlight %}

### Read

{% highlight swift %}
final class FileReader {

  enum Failure: Error {
    case cantReadFile(String)
    case cantReadLine
  }

  private var file: UnsafeMutablePointer<FILE>?

  // MARK: - Lifecycle

  init(_ path: String) throws {
    file = fopen(path, "r")
    if file == nil {
      throw Failure.cantReadFile(path)
    }
  }

  deinit {
    fclose(file)
  }

  // MARK: - Public

  func readNextLine() throws -> String? {
    var line: String
    repeat {
      // create buffer
      var buffer = [CChar](repeating: 0, count: 1024)

      // Reads characters from stream and stores them as a C string into str until
      // (num-1) characters have been read or either a newline or the end-of-file
      // is reached, whichever happens first.
      if fgets(&buffer, Int32(buffer.count), file) == nil {

        // Checks if the error indicator associated with stream is set,
        // returning a value different from zero if it is.
        if ferror(file) != 0 {
          throw Failure.cantReadLine
        }

        return nil
      }
      // append line
      line = String(cString: buffer)
    } while line.lastIndex(of: "\n") == nil
    return line
  }
}
{% endhighlight %}

usage:

{% highlight swift %}
if let path = Bundle.main.path(forResource: "Text", ofType: "txt"),
   let file = try? FileReader(path){
  while let line = try? file.readNextLine() {
    // do some operations
  }
}
{% endhighlight %}

> discussion about read approach using fopen [here](https://forums.swift.org/t/read-text-file-line-by-line/28852/34).


### Seek 

Seek concrete position in file also can be performed using c++ api and [`fseek`](http://www.cplusplus.com/reference/cstdio/fseek/):

{% highlight swift %}
FILE* fp;
// if file is 50 bytes long:
fseek(fp, /* from the end */ 23, SEEK_END); // <- at 50 - 23 so 27
fseek(fp, /* from the start */ 23, SEEK_SET); // 23
fseek(fp, /* from the the current (see ftell) */ 10, SEEK_CUR); // 33
{% endhighlight %}

> U can combine [`fseek`](http://www.cplusplus.com/reference/cstdio/fseek/) usage within [`rewind`](http://www.cplusplus.com/reference/cstdio/rewind/?kw=rewind). More about file related api from c++ [here](https://talk.objc.io/episodes/S01E92-practicing-with-pointers)

### Update

Update operation can be done using specifc flag `a` while perform `fopen`:

{% highlight swift %}
f = fopen("filename", "a"); // or a+
{% endhighlight %}

> `a` for append.

write operation can be done as before.

### Delete

{% highlight swift %}
final class FileRemover {

  enum Failure: Error {
    case cantFindFile(String)
    case cantRemove
  }

  private var path: String?

  init(_ path: String) throws {
    let file = fopen(path, "w")
    if file == nil {
      throw Failure.cantFindFile(path)
    } else {
      fclose(file)
      self.path = path
    }
  }

  func remove() throws {
    let name = [Int8](path!.utf8.map { Int8($0) })
    let err = Darwin.remove(name)
    if err != 0 {
      throw Failure.cantRemove
    }
  }
}
{% endhighlight %}

usage:

{% highlight swift %}
let path = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
let file = path?.appendingPathComponent("CreatedFile.txt")

if let remover = try? FileRemover(file!.path) {
  try? remover.remove()
}
{% endhighlight %}

[download source code]({% link assets/posts/images/2021-03-05-using-file/source/demoFileRead.zip %})

## Resources

* [File](https://en.wikipedia.org/wiki/Computer_file)
* [`FileManager`](https://developer.apple.com/documentation/foundation/filemanager)
* [`FileHandle`](https://developer.apple.com/documentation/foundation/filehandle)
* [Files](https://developer.apple.com/documentation/uikit/documents_data_and_pasteboard)
* [`Stream`](https://developer.apple.com/documentation/foundation/stream)
* [`DispatchIO`](https://developer.apple.com/documentation/dispatch/dispatchio).
* [S01E92-practicing-with-pointers](https://talk.objc.io/episodes/S01E92-practicing-with-pointers)
* [`off_t`](https://www.gnu.org/software/libc/manual/html_node/File-Position-Primitive.html)
* [APFS](https://developer.apple.com/support/downloads/Apple-File-System-Reference.pdf)