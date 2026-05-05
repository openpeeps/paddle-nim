<p align="center">
  Paddle API Client for 👑 Nim language
</p>

<p align="center">
  <code>nimble install paddle</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/paddle-nim">API reference</a><br>
  <img src="https://github.com/openpeeps/paddle-nim/workflows/test/badge.svg" alt="Github Actions">  <img src="https://github.com/openpeeps/paddle-nim/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- Asynchronous API calls using Nim's `async`/`await`
- Direct-to-object mapping of Paddle API responses to Nim types
- Idiomatic Nim API client for the [Paddle API](https://developer.paddle.com/)

## Examples
```nim
import paddle

let client = initPaddleClient("pdl_sdbx_apikey_")

# create your Paddle product
let product = await client.postProduct("My Product", some("A great product"))

# add a price to your product
let price = await client.postPrice(
      productId = product.id,
      name = "Standard Plan",
      description = "The standard plan for my product",
      billingCycle = paddle.initBillingCycle(PaddleBillingInterval.month, 1),
      unitPrice = initPrice("1000", EUR)
)
```

### TODO
- [ ] Use `pkg/money` for price fields instead of strings
- [ ] Add more API endpoints (subscriptions, coupons, etc.)
- [ ] Use `pkg/openparser` dump hooks, skip fields, etc. to reduce use of `JsonNode` nodes (once implemented lol)
- [ ] Add support for webhooks and events
- [ ] Add more examples and documentation
- [ ] Add unit tests

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/paddle-nim/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/paddle-nim/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
