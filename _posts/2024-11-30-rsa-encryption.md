---
layout: post
comments: true
title: "RSA Encryption"
categories: article
tags: [swift, rca, encryption]
excerpt_separator: <!--more-->
comments_id: 110

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Recently, I encountered RSA encryption while working on a project and realized its critical role in securing data. RSA (Rivest-Shamir-Adleman) encryption is a public-key cryptographic system widely used for secure data transmission. Let’s explore its purpose, history, and functionality.
<!--more-->

### A Brief History of RSA
 
RSA was introduced in 1977 by Ron Rivest, Adi Shamir, and Leonard Adleman at MIT. It was the first algorithm for public-key cryptography that could encrypt and digitally sign data. Its foundation lies in number theory, specifically the difficulty of factoring large composite numbers, making it a reliable choice for securing communications.


## How it Works

Below is a high-level overview of RSA's process:  

1. Key Generation
 - Select two large prime numbers \( p \) and \( q \).  
 - Compute \( n = p 	imes q \), where \( n \) is the modulus.  
 - Calculate \( \phi(n) = (p-1) 	imes (q-1) \).  
 - Choose a public exponent \( e \), and determine the private key \( d \), where \( d 	imes e \mod \phi(n) = 1 \).  

2. Encryption
 - Plaintext \( M \) is converted to ciphertext \( C \) using the public key \( (e, n) \):  
   \( C = M^e \mod n \).  

3. Decryption  
 - The recipient uses their private key \( d \) to decrypt \( C \):  
   \( M = C^d \mod n \).  

This ASCII diagram provides a simplified, yet complete visualization of how RSA encryption works:

<br>

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-11-30-rsa-encryption/rsa.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-11-30-rsa-encryption/rsa.png" width="600"/>
</a>
</div>
<br>
<br>


### Public vs. Private Key  

- **Public Key:** Shared openly; used to encrypt data or verify digital signatures.  

- **Private Key:** Kept secret; used to decrypt data or create digital signatures.  
This asymmetry ensures secure communication since only the holder of the private key can access encrypted messages or authenticate signatures.

<br>
<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-11-30-rsa-encryption/encrypt.webp">
<img src="{{site.baseurl}}/assets/posts/images/2024-11-30-rsa-encryption/encrypt.webp" width="600"/>
</a>
</div>
<br>
<br>

## Implementation

Here we have few moments - private key is something that we don't want to share, so we need to store this key somewhere in safe place.

Luckely for us, Apple already think about this, and using `Security` framework we can generate and store our key in keychain securely.

The process for rsa encryption will contains few steps:

- generate or obtain generated keys
- encrypt/decrypt value

Let's review each step.

### generate keys

As we want to manage both keys, we can simply wrap this idea into one model - `RSAKeyModel`:

{% highlight swift %}
public struct RSAKeyModel {

  private(set) var publicKey: SecKey
  private(set) var privateKey: SecKey
  ...
}
{% endhighlight %}

The most interesting part - it's generating keys itself. For this purpose, let's create a type, that will handle this - `RSAProvider`. 

To generate key, we must provide all preferences that we need. Keeping in mind, that we need a storage for keys for future reuse, we can do the following:

{% highlight swift %}
let publicKeyAttr: CFDictionary = [
  kSecAttrIsPermanent: true,
  kSecAttrApplicationTag: publicKeyTag,
  kSecClass: kSecClassKey,
  kSecReturnData: kCFBooleanTrue ?? true
] as CFDictionary
{% endhighlight %}

where:

* `kSecAttrIsPermanent`: `true`: Indicates that the key will be stored persistently in the Keychain, so we can retrieve this key later and reuse.
* `kSecAttrApplicationTag`: `publicKeyTag`: Tags the public key with an identifier (`publicKeyTag`) for future retrieval. This identifier can be anything, even the `bundleID` of u'r app.
* `kSecClass`: `kSecClassKey`: Specifies that the object is a cryptographic key.
* `kSecReturnData`: `kCFBooleanTrue`: Ensures the raw key data is returned after creation. This is needed so we can start using it exactly after creation.

For private key settings will be same, except `kSecAttrApplicationTag`.

Having this settings in place, we also must provide Key Pair Generation Parameters:

{% highlight swift %}
let parameters: CFDictionary = [
  kSecAttrKeyType: kSecAttrKeyTypeRSA,
  kSecAttrKeySizeInBits: size,
  kSecPublicKeyAttrs: publicKeyAttr,
  kSecPrivateKeyAttrs: privateKeyAttr
] as CFDictionary
{% endhighlight %}

where:

* `kSecAttrKeyType`: `kSecAttrKeyTypeRSA`: Specifies the key type as RSA. 
* `kSecAttrKeySizeInBits`: `size`: Sets the key size (e.g., 2048 or 4096 bits) from the keySize property.
* `kSecPublicKeyAttrs` and `kSecPrivateKeyAttrs`: Links the previously defined attributes for public and private keys.


With this settings in place, we can generate the key-pair:

{% highlight swift %}
var error: UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
guard let privateKey = SecKeyCreateRandomKey(parameters, error),
  let publicKey = SecKeyCopyPublicKey(privateKey) else {
  throw RSAProviderFailure.keyGenerationFailed(error as! Error)
}
{% endhighlight %}

* `SecKeyCreateRandomKey`: Generates a new private key based on the parameters. If successful, it stores the private key in the Keychain.
* `SecKeyCopyPublicKey`: Extracts the corresponding public key from the private key.
* If either function fails, an exception is thrown using the `RSAProviderFailure.keyGenerationFailed` error (this is custom one, u may create u'r own).

And the last, but not least - create our keyPait object for future use:

{% highlight swift %}
RSAKeyModel(publicKey: publicKey, privateKey: privateKey)
{% endhighlight %}

There are could be some enchansment as:

* `Key Permissions`: Add attributes to restrict key usage (e.g., encryption only).
* `Error Handling Improvements`: Safely unwrap and describe error for better debugging.
* `Performance Testing`: Evaluate how key sizes affect performance and usability.

But for basic usage approach described above will be fully ok.

One more thing - retrieving key from keychain.

To do so, we must create a query for it, qury require some additional info:

{% highlight swift %}
let query: CFDictionary = [
  kSecClass: kSecClassKey,
  kSecAttrApplicationTag: keyTagFor(keyType: keyType),
  kSecAttrKeyType: kSecAttrKeyTypeRSA,
  kSecReturnRef: kCFBooleanTrue ?? true
] as CFDictionary

var item: CFTypeRef?
let status = SecItemCopyMatching(query, &item)
{% endhighlight %}

where:

* `kSecClass`: `kSecClassKey`: Specifies the type of object being queried, which is a cryptographic key (`kSecClassKey`).
* `kSecAttrApplicationTag`: A unique identifier (keyType can be .public or .private). This tag is used to distinguish the key being fetched.
* `kSecAttrKeyType`: `kSecAttrKeyTypeRSA`: Indicates that the key is an RSA key.
* `kSecReturnRef`: `kCFBooleanTrue`: Ensures the query returns a reference to the key (`SecKey`) if found.
* `SecItemCopyMatching`: Queries the Keychain for the key matching the specified attributes.
* Return Value: The `status` variable contains the result of the query

### encrypt/decrypt

Now, having our keys in place, we can start working on protection for our data - encrypting and decryption. Let's wrap everything in type named `RSACryptor`.

To create a method that can encrypts a plaintext string into ciphertext using an RSA public key and a specified encryption algorithm we will utilize Apple's [`Security`](https://developer.apple.com/documentation/Security) framework.

The basic idea - select algorithm, keys and encrypt data:

{% highlight swift %}
let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256
// check if everything is ok
SecKeyIsAlgorithmSupported(keys.publicKey, .encrypt, algorithm) 
// encrypt
SecKeyCreateEncryptedData(
  keys.publicKey,
  algorithm,
  data as CFData,
  &error
  )
{% endhighlight %}

The decrypt process is similar:

{% highlight swift %}
let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256
// check if everything is ok
SecKeyIsAlgorithmSupported(keys.privateKey, .decrypt, algorithm)
//decrypt
SecKeyCreateDecryptedData(
  keys.privateKey,
  algorithm,
  encryptedData as CFData,
  &error
  )
{% endhighlight %}

For more easy usage we may also need convinience functions to convert `String`, `Data` and `SecKey` between each other. Because u retrieve keys from Keychain as a `Data` and use `SecKey` in the process. U also may need to send `publickey` via network. 

To do so, we can add some extensions:

{% highlight swift %}
extension Data {

  // MARK: Data+Convert

  func toPublicSecKey() throws -> SecKey {
  let options: [CFString: Any] = [
  kSecAttrKeyType: kSecAttrKeyTypeRSA,
  kSecAttrKeyClass: kSecAttrKeyClassPublic // <- for private key use kSecAttrKeyClassPrivate
  ]
  var error: Unmanaged<CFError>?
  guard let key = SecKeyCreateWithData(
  self as CFData,
  options as CFDictionary,
  &error
  ) else {
  throw error!.takeRetainedValue() as Error
  }

  return key
  }
}
{% endhighlight %}

To convert [`SecKey`](https://developer.apple.com/documentation/security/storing-keys-as-data) into data:

{% highlight swift %}
extension SecKey {

  // MARK: SecKey+Convert

  func toData() throws -> Data {
  var error: Unmanaged<CFError>?
  guard let data = SecKeyCopyExternalRepresentation(self, &error) as? Data else {
  throw error!.takeRetainedValue() as Error
  }
  return data
  }

  func toBase64EncodedString() throws -> String {
  let data = try self.toData()
  return data.base64EncodedString()
  }
}
{% endhighlight %}

U done! ;]

### example

{% highlight swift %}

 do {
 let rsaProvider = try RSAProvider(identifier: "test3", keySize: .size4096)
 let pair = try rsaProvider.obtainKeysPair()

 let message = "hello 1.2.3"
 let cryptor = RSACryptor(keys: pair)
 let msgEncryptedData = try cryptor.encrypt(plainTextInput: message)
 let decryptedMsg = try cryptor.decrypt(encryptedData: msgEncryptedData)

 print("public key - \(try pair.publicKeyString())")
 print("private key - \(try pair.privateKeyString())")
 print("message to encrypt - \(message)")
 print("msgEncryptedData - \(msgEncryptedData.base64EncodedString())")
 print("decrypted info - \(decryptedMsg)")
 } catch {
 print("failure - \(error)")
 }
{% endhighlight %}

output:

```
public key - MIICCgK...ySPAk0CAwEAAQ==
private key - MIIJJwIBAA...7hROKkymQEMg==
message to encrypt - hello 1.2.3
msgEncryptedData - ROPAHEzf...ccpbaU6TVLmLyID4YrDXNZkg=
decrypted info - hello 1.2.3
```

### Source code

The source code available [here]({{site.baseurl}}/assets/posts/images/2024-11-30-rsa-encryption/RSACrypto.zip)

## Best Practices

1. Always validate input sizes when encrypting or decrypting data with RSA to avoid errors.
2. Use modern padding schemes like OAEP for enhanced security.
3. Store private keys securely using Keychain with appropriate access controls.
4. Regularly update encryption algorithms and key sizes as cryptographic standards evolve.
5. Avoid hardcoding keys in your codebase; instead, use secure storage mechanisms.


## Resources

* [RSA Algorithm on Wikipedia](https://en.wikipedia.org/wiki/RSA_(cryptosystem)): A comprehensive explanation of RSA encryption.  
* [Khan Academy: Cryptography](https://www.khanacademy.org/computing/computer-science/cryptography): Interactive lessons on cryptographic principles.  
* [Practical Cryptography](https://practicalcryptography.com/): Insights into real-world cryptographic systems.  
* [`Security`](https://developer.apple.com/documentation/Security)
* [`SecKey`](https://developer.apple.com/documentation/security/storing-keys-as-data)
* [Security Framework Reference](https://developer.apple.com/documentation/security) A detailed overview of the Security framework, covering topics like cryptographic operations, certificate handling, and Keychain management.
* [Cryptographic Services Guide](https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys) Explains concepts such as public-key encryption, symmetric cryptography, and secure storage using Apple's Security framework.
* [Encrypting and Decrypting Data Using Public and Private Keys](https://developer.apple.com/documentation/security/keys) Learn how to perform encryption, decryption, and signing using `SecKey`.
* [iOS Security Guide](https://www.apple.com/business/docs/site/iOS_Security_Guide.pdf) Understand Apple's recommendations for secure app development.
* [Introduction to RSA Cryptography](https://en.wikipedia.org/wiki/RSA_(cryptosystem)) Overview of RSA's principles, including key generation, encryption, and decryption.
* [RSA Demonstration Tool](https://www.cs.utah.edu/~jeffp/crypto/) Experiment with RSA encryption and decryption online.
* [Secure RSA Implementation in Swift](https://github.com/iosdev-samples/RSASwift) A working example of how to implement RSA encryption and decryption in iOS.
* [Using RSA Encryption in Swift](https://www.hackingwithswift.com/example-code/security/how-to-encrypt-and-decrypt-text-with-cryptokit) Learn how to securely encrypt and decrypt messages in your app 
* [Cryptography Engineering](https://www.schneier.com/books/cryptography_engineering/) By Bruce Schneier et al. A practical guide to implementing secure cryptographic systems.
* [Handbook of Applied Cryptography](https://cacr.uwaterloo.ca/hac/) A comprehensive resource for understanding cryptographic algorithms, including RSA.
* [OpenSSL Project](https://www.openssl.org/) Command-line tools for generating RSA keys and testing encryption. 
* [SecKey Utilities on GitHub](https://github.com/cryptokit-framework/Security-Swift) Helpful tools for working with `SecKey` objects and RSA operations.
* [Cryptographic Playground](https://www.cryptool.org/) Experiment with different cryptographic algorithms, including RSA. 
* [A Beginner's Guide to RSA in iOS](https://medium.com/swift-programming/understanding-rsa-in-ios-75d59a7f77c9) A straightforward introduction to how RSA works and how to implement it in Swift.
* [The State of RSA in Modern Cryptography](https://blog.cloudflare.com/rsa-2048-enough-today/) A discussion of the current state of RSA security and key size recommendations.
