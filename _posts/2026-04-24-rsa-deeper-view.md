---
layout: post
comments: true
title: "RSA - closer look"
categories: article
tags: [RSA, encryption, c++]
excerpt_separator: <!--more-->
comments_id: 124

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Protection data is one of the most important task. We already have a lot of algorithms to cover this purpose, but the most popular one - is still [RSA](https://en.wikipedia.org/wiki/RSA_(cryptosystem)) (Rivest-Shamir-Adleman).
<!--more-->

I already wrote some time ago about RSA implementation on swift, but it was a bit covered behind keychain [here]({% post_url 2024-11-30-rsa-encryption %}). In this article, let's dive in a bit more details, to be able to understand the RSA generation process in more details.

## History remark

RSA named thanks to authors of this algorithm - Rivest-Shamir-Adleman, but this is official version. Actually the very first implementation was done by [Clifford Cocks](https://en.wikipedia.org/wiki/Clifford_Cocks), but his work was classified, it did not become widely known until 1997 when the work was declassified.


## Implementation

RSA relies on advanced mathematical principles, but the procedures for generating public and private keys, encrypting data with the public key, and decrypting it with the private key are relatively simple. Let's go step by step and see the process in more details.

> I will use simplified version of algorithm, thus this is not production ready, it's good to understand how it works.

### Base elements

All starts from selection of 2 prime numbers - based on them, we will do all other calculation needed for RSA algorithm start works.

> If u want to implement production version of this algorithm, u may need some kind of library that can handle [enormous numbers](https://en.wikipedia.org/wiki/RSA_numbers) for u, like [boost](https://www.boost.org/doc/libs/latest/libs/multiprecision/doc/html/index.html) or so.

To do so, we can simply generate random number and check if it's prime or no, is so - we can use it.

{% highlight c++ %}

std::random_device rd;
std::mt19937 gen(rd()); // Mersenne Twister
std::uniform_int_distribution<> distr(1, 100);

do
{
    m_primeP = distr(gen);
} while (!isPrime(m_primeP));

bool isPrime(int num)
{
    if (num <= 1)
        return false;
    if (num == 2)
        return true;
    if (num % 2 == 0)
        return false;

    for (int i = 3; i <= std::sqrt(num); i += 2)
    {
        if (num % i == 0)
            return false;
    }
    return true;
}

{% endhighlight %}

> The code I posted here is not designed for best performance or so - it's purpose to show the process in easy to understand manner.

### Modulus calculation

Modular arithmetic, or "modulus" math, is a cornerstone of modern cryptography, operating like a clock (15 hours is 3 p.m. in mod 12). It works with remainders, restricting numbers within a finite range to create one-way functions, crucial for securing data. It is essential in algorithms like the one we are trying to code - RSA for public-key encryption and Diffie-Hellman key exchange.

The modulus is a large integer n (typically the product of two primes) that defines the arithmetic space for encryption and decryption operations. All computations are performed `modulo n`.

We already generate random numbers, so now we have all needed for calculation modulo.

To calculate the modulus n, we simply do the product of selected prime numbers:

{% highlight c++ %}

m_modulusN = m_primeP * m_primeQ;

{% endhighlight %}

### Euler’s totient function

Next step is Euler’s totient function calculation. 

Euler’s totient function `φ(n)` counts the number of integers in the range `1..n` that are [**coprime**](https://en.wikipedia.org/wiki/Coprime_integers) with `n` (i.e. `gcd(k, n) = 1`).

#### Example

`n = 12 = 2^2 * 3`

For `n = p * q` (where `p`, `q` are primes):

```
var phi(n) = (p - 1)(q - 1)
```

Used to compute the private key via modular inverse.

{% highlight c++ %}

m_eulerTotient = (m_primeP - 1) * (m_primeQ - 1);

{% endhighlight %}

### Public-Key Exponent (e)

The next 2 steps - are related - one is public key exponent and another private key exponent calculation.

To choose an exponent, `e`, for encryption, we must follow next rules:

- `1 < e < φ(n)`
- `e` must be coprime with `φ(n)`.

Public key will be as `P(e, n)` where `e` is exponent and `n` - modulus.

> Few notes: 
> 
>  - Academic materials often introduce e first → write `(e, n)`
>  - Standards (PKCS, X.509, OpenSSL) define structure as `(n, e)`
> 

In RSA, the public exponent `e` is typically small and fixed, while the modulus `n` is large.

> For our trial purpose we will get small values, but in production env - it's huge.
> 
>  - p,q are ~1024-bit primes
>  - n becomes ~2048 bits → huge
>  - φ(n) also huge
> 

From code perspective we should

1. Find [prime factorisation](https://simple.wikipedia.org/wiki/Prime_factorization) for totient function
2. Select random prime number from p1, thus so `1 < e < φ(n)`
3. Combine with modulus

The most interesting part here - is finding prime numbers for given number:

{% highlight c++ %}

std::vector<long long> getPrimeFactors(long long n)
{
    std::vector<long long> factors;
    while (n % 2 == 0)
    {
        factors.push_back(2);
        n /= 2;
    }
    for (long long i = 3; i * i <= n; i += 2)
    {
        while (n % i == 0)
        {
            factors.push_back(i);
            n /= i;
        }
    }
    if (n > 1)
        factors.push_back(n);
    return factors;
}
{% endhighlight %}

### Private-Key Exponent (e)

To determine the private key’s exponent, `d`, for decryption we should use next equation:

`(d * e) mod φ(n) = 1`

This relation defines how the private exponent `d` is derived from the public exponent `e`.

Formally, it means:

- `d` is the modular inverse of e modulo `φ(n)`
- i.e. multiplying e by d wraps around the modulus `φ(n)` and yields 1

{% highlight c++ %}
long long modInverse(long long e, long long phi)
{
    long long m0 = phi, t, q;
    long long x0 = 0, x1 = 1;

    if (phi == 1)
        return 0;

    while (e > 1)
    {
        // q is quotient
        q = e / phi;
        t = phi;

        // phi is remainder now, process same as Euclid's algo
        phi = e % phi;
        e = t;
        t = x0;

        x0 = x1 - q * x0;
        x1 = t;
    }

    // Make x1 positive if it is negative
    if (x1 < 0)
        x1 += m0;

    return x1;
}
{% endhighlight %}

### Encrypt/Decrypt

The last steps is to perform encryption and decryption.

Once the public key is available, RSA encryption is straightforward. For a plaintext integer `M` and a public key `(e,n)`, the ciphertext `C` is computed as:

`C = M^e mod n`

> During implementation we can hit a pitfall - after RSA encryption, one block is a number c = m^e mod N, and it is always in 0 .. N−1 inclusive. The helper question is: "How many bytes do we need, in a fixed width, to store any such c?" It does not use N directly; it uses N − 1, because the largest possible ciphertext in one block is N − 1. So we need to know how many bytes needed per ciphertext block. Without this - result can be corrupted, so incorrect.
> 

{% highlight c++ %}

std::string encrypt(const std::string &plaintext)
{
    const int blockBytes = ciphertextBlockBytes();
    std::string result;
    result.reserve(plaintext.size() * static_cast<size_t>(blockBytes));

    for (size_t i{0}; i < plaintext.size(); ++i)
    {
        const std::uint64_t m = static_cast<unsigned char>(plaintext[i]);
        const long long decValue = powerMod(m, m_encryptionExponent, m_modulusN);
        const std::uint64_t c = static_cast<std::uint64_t>(decValue);
        for (int b{0}; b < blockBytes; ++b)
        {
            const auto byte = static_cast<unsigned char>((c >> (8 * b)) & 0xFFu);
            result.push_back(static_cast<char>(byte));
        }
    }

    return result;
}
{% endhighlight %}


Decryption process is similar - 

`M = C^d mod n`.

{% highlight c++ %}
std::string decrypt(const std::string &cipher)
{
    const int blockBytes = ciphertextBlockBytes();
    if (blockBytes < 1 || (cipher.size() % static_cast<size_t>(blockBytes)) != 0)
    {
        throw std::invalid_argument("decrypt: cipher length is not a multiple of block size");
    }

    std::string result;
    result.reserve(cipher.size() / static_cast<size_t>(blockBytes));

    for (size_t i{0}; i < cipher.size(); i += static_cast<size_t>(blockBytes))
    {
        std::uint64_t c{0};
        for (int b{0}; b < blockBytes; ++b)
        {
            c |= static_cast<std::uint64_t>(
                     static_cast<unsigned char>(cipher[i + static_cast<size_t>(b)]))
                 << (8 * b);
        }
        const std::uint64_t m =
            static_cast<std::uint64_t>(powerMod(c, m_decryptionExponent, m_modulusN));
        if (m > 255u)
        {
            throw std::runtime_error("decrypt: recovered byte out of char range (message too long for n)");
        }
        result.push_back(static_cast<char>(static_cast<unsigned char>(m)));
    }

    return result;
}

{% endhighlight %}

## Test run

Now, the most interesting moment - let's run and test implementation:

{% highlight c++ %}

RSA rsa{};
std::string message = "Hello from khorbushko.github.io!";
std::cout << std::format("Message to encrypt: \n{}\n", message);

std::string cipherRSA = rsa.encrypt(message);
std::cout << std::format("Encrypted: \n{}\n", cipherRSA);
    
std::string decryptedMsg = rsa.decrypt(cipherRSA);
std::cout << std::format("Decrypted: \n{}\n", decryptedMsg);
    
{% endhighlight %}

The output is next:

{% highlight console %}

P - 2, Q - 83
Modulus 166
Euler’s totient function 82
Prime factorisation of 82 is
2 41 

Primes between 41 and 82: 
43 47 53 59 61 67 71 73 79 

Selected encr exponent is 67

Public key:
67 166 

Selected decr exponent is 71

Private key:
71 166 
Message to encrypt: 
Hello from khorbushko.github.io!
Encrypted: 
�!��!�/(!-(/!�u#F(�#!�
Decrypted: 
Hello from khorbushko.github.io!

{% endhighlight %}

A bit more initial values can give slightly different options, but same result:


{% highlight console %}

P - 13, Q - 47
Modulus 611
Euler’s totient function 552
Prime factorisation of 552 is
2 2 2 3 23 

Possible values for exponent are:
29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293 307 311 313 317 331 337 347 349 353 359 367 373 379 383 389 397 401 409 419 421 431 433 439 443 449 457 461 463 467 479 487 491 499 503 509 521 523 541 547 

Selected encr exponent is 307

Public key:
307 611 

Selected decr exponent is 187

Private key:
187 611 
Message to encrypt: 
Hello from khorbushko.github.io!
Encrypted: 
��

  �)`�)���`�w�����WM���W�\
Decrypted: 
Hello from khorbushko.github.io!

{% endhighlight %}

## Conclusions

Every complex task can be divided into simple tasks. This is good for understanding the process and for improving it.

[download full source]({% link assets/posts/images/2026-04-24-rsa-deeper-view/rsa.h.zip %})

## Resources

* [RSA Algorithm on Wikipedia](https://en.wikipedia.org/wiki/RSA_(cryptosystem)): A comprehensive explanation of RSA encryption.  
* [Khan Academy: Cryptography](https://www.khanacademy.org/computing/computer-science/cryptography): Interactive lessons on cryptographic principles.  
* [Clifford Cocks](https://en.wikipedia.org/wiki/Clifford_Cocks)
* [boost](https://www.boost.org/doc/libs/latest/libs/multiprecision/doc/html/index.html)
* [Modular arithmetic](https://en.wikipedia.org/wiki/Modular_arithmetic)
* [Prime factorisation](https://simple.wikipedia.org/wiki/Prime_factorization)
