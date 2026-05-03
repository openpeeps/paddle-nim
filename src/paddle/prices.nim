# A Nim client for the Paddle API
# https://developer.paddle.com/api-reference/
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/paddle-nim
import ./api, ./products

type
  
  PaddleBillingInterval* = enum
    ## Unit of time for the billing cycle. Required if `frequency` is set.
    day = "day"
    week = "week"
    month = "month"
    year = "year"

  PaddleBillingCycle* = object
    interval*: PaddleBillingInterval
      ## Unit of time for the billing cycle. Required if `frequency` is set.
    frequency*: int
      ## Amount of time in the given unit based on the `interval` value. For example,
      ## if `interval` is `month` and `frequency` is `3`,
      ## the billing cycle is every 3 months. Required if `interval` is set.
  
  PriceTaxMode* = enum
    taxModeAccountSetting = "account_setting"
      ## Prices use the setting from your account.
    taxModeExternal = "external"
      ## Prices are exclusive of tax.
    taxModeInternal = "internal"
      ## Prices are inclusive of tax.
    taxModeLocation = "location"
      ## Prices are inclusive or exclusive of tax,
      ## depending on the country of the transaction

  CurrencyCode* = enum
    USD, EUR, GBP, JPY, AUD, CAD, CHF, HKD, SGD, SEK, ARS, BRL, CNY, COP,
    CZK, DKK, HUF, ILS, INR, KRW, MXN, NOK, NZD, PLN, RUB, THB, TRY, TWD, UAH, VND, ZAR

  PriceUnit* = object
    amount*: string
      ## Amount in the lowest denomination for the currency, e.g. 10 USD = 1000 (cents).
      ## Although represented as a string, this value must be a valid integer.
    currency_code*: CurrencyCode
      ## Supported three-letter ISO 4217 currency code.
  
  PriceUnitOverride* = object
    country_codes*: string # TODO enun
      ## Two-letter ISO 3166-1 alpha-2 country code.
    unit_price*: PriceUnit
      ## Price for this country, in the lowest denomination for the currency.

  PaddlePrice* = object of PaddleBaseObject
    product_id*: PaddleEntryId
      ## Paddle ID for the product that this price is for, prefixed with `pro_`.
    description*: string
      ## Internal description for this price, not shown to
      ## customers. Typically notes for your team.
    name*: string
      ## Name of this price, shown to customers at checkout and on invoices.
      ## Typically describes how often the related product bills.
    billing_cycle*: PaddleBillingCycle
      ## How often this price should be charged. `nil` if price is
      ## non-recurring (one-time).
    trial_period*: PaddleBillingCycle
      ## Trial period for the product related to this price.
      ## The billing cycle begins once the trial period is over. `nil` for no
      ## trial period. Requires `billing_cycle`.
    tax_mode*: PriceTaxMode
      ## How tax is calculated for this price
    unit_price*: PriceUnit
      ## Base price. This price applies to all customers, except for
      ## customers located in countries where you have `unit_price_overrides`.
    unit_price_overrides*: seq[PriceUnitOverride]
      ## List of unit price overrides. Use to override the base price
      ## with a custom price and currency for a country or group of countries.
    quantity*: tuple[minimum: int, maximum: int]
      ## Limits on how many times the related product
      ## can be purchased at this price. Useful for discount campaigns.
      ## 
      ## `minimum` - Required if `maximum` set.
      ## 
      ## `maximum` - Required if `minimum` set. Must be greater
      ## than or equal to the `minimum` value.

proc getPrices*(client: PaddleClient): Future[PaddleApiResponse[seq[PaddlePrice]]] {.async.} =
  ## Retrieves a list of prices.
  let res: AsyncResponse = await client.httpGet("prices")
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[seq[PaddlePrice]])
  else:
    raise newException(PaddleClientError, body)

proc postPrice*(client: PaddleClient, productId: PaddleEntryId,
          name: string,
          description: string,
          billingCycle: PaddleBillingCycle,
          unitPrice: PriceUnit,
          taxMode: PriceTaxMode = PriceTaxMode.taxModeAccountSetting,
          trialPeriod: Option[PaddleBillingCycle] = none(PaddleBillingCycle)
    ): Future[PaddleApiResponse[PaddlePrice]] {.async.} = 
  ## Creates a new price with the specified parameters.
  var body = %*{
    "product_id": productId,
    "name": name,
    "description": description,
    "billing_cycle": billingCycle,
    "tax_mode": taxMode,
    "unit_price": unitPrice
  }

  if trialPeriod.isSome:
    body["trial_period"] = %*trialPeriod.get()

  let res: AsyncResponse = await client.httpPost("prices", body)
  let resBody = await res.body
  case res.code:
  of Http201:
    echo resBody
    result = fromJson(resBody, PaddleApiResponse[PaddlePrice])
  else:
    raise newException(PaddleClientError, resBody)

proc postPrice*(client: PaddleClient, productId: PaddleEntryId, name: string,
          price: PriceUnit): Future[PaddleApiResponse[PaddlePrice]] {.async.} = 
  ## Creates a new one-time price with the specified parameters.
  let body = %*{
    "product_id": productId,
    "name": name,
    "unit_price": price
  }
  let res: AsyncResponse = await client.httpPost("prices", body)
  let resBody = await res.body
  case res.code:
  of Http201:
    result = fromJson(resBody, PaddleApiResponse[PaddlePrice])
  else:
    raise newException(PaddleClientError, resBody)

proc initBillingCycle*(interval: PaddleBillingInterval, frequency: int): PaddleBillingCycle =
  ## Helper function to create a `PaddleBillingCycle` object with the specified parameters.
  PaddleBillingCycle(interval: interval, frequency: frequency)

proc initPrice*(
  unitPrice: PriceUnit,
  billingCycle: Option[PaddleBillingCycle] = none(PaddleBillingCycle),
  trialPeriod: Option[PaddleBillingCycle] = none(PaddleBillingCycle),
  taxMode: PriceTaxMode = PriceTaxMode.taxModeAccountSetting,
): PaddlePrice =
  ## Helper function to create a `PaddlePrice` object with the specified parameters.
  result = PaddlePrice(unit_price: unitPrice, tax_mode: taxMode)
  if billingCycle.isSome:
    result.billing_cycle = billingCycle.get()
  
  if trialPeriod.isSome:
    result.trial_period = trialPeriod.get()

proc initPrice*(amount: string, currency: CurrencyCode): PriceUnit =
  ## Helper function to create a `PriceUnit` object with the specified parameters.
  PriceUnit(amount: amount, currency_code: currency)