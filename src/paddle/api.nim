# A Nim client for the Paddle API
# https://developer.paddle.com/api-reference/
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/paddle-nim

import std/[asyncdispatch, httpclient, times,
        options, tables, strutils, sequtils]

import pkg/openparser/json
export asyncdispatch, httpclient,
      json, options, times

type
  PaddleTaxCategory* = enum
    digitalGoods = "digital-goods"
      ## Return entities with the tax category of digital-goods. Non-customizable digital files or media
      ## (not software) acquired with an up front payment that can be accessed without any
      ## physical product being delivered.
    ebooks = "ebooks"
      ## Return entities with the tax category of ebooks. Digital books and educational
      ## material which is sold with permanent rights for use by the customer.
    implementationServices = "implementation-services"
      ## Return entities with the tax category of implementation-services. Remote
      ## configuration, set-up, and integrating software on behalf of a customer.
    professionalServices = "professional-services"
      ## Return entities with the tax category of professional-services. Services
      ## that involve the application of your expertise and specialized knowledge
      ## of a software product.
    saas = "saas"
      ## Return entities with the tax category of saas. Products that allow users to
      ## connect to and use online or cloud-based applications over the Internet.
    softwareProgrammingServices = "software-programming-services"
      ## Return entities with the tax category of software-programming-services.
      ## Services that can be used to customize and white label software products.
    standard = "standard"
      ## Return entities with the tax category of standard. Software products that
      ## are pre-written and can be downloaded and installed onto a local device.
    trainingServices = "training-services"
      ## Return entities with the tax category of training-services.
      ## Training and education services related to software products.
    websiteHosting = "website-hosting"
      ## Return entities with the tax category of website-hosting. Cloud storage
      ## service for personal or corporate information, assets, or intellectual property.
  
  PaddleItemType* = enum 
    standard = "standard"
    custom = "custom"

  PaddleItemStatus* = enum
    active = "active"
    archived = "archived"

  PaddleEntryID* = string
    ## The unique identifier for an entity, prefixed with a three-letter code
    ## indicating the type of entity, e.g. `pro_` for products, `pri_` for prices, etc.

  PaddleBaseObject* = object of RootObj
    ## Base object for all entities returned by the Paddle API
    id*: PaddleEntryID
    `type`*: PaddleItemType
    status*: PaddleItemStatus
      ## The status of this entity
    custom_data*: JsonNode
      ## Your own structured key-value data
    import_meta*: JsonNode
      ## Import information for this entity. null if this entity is not imported.
    created_at: DateTime
      ## The date and time when the entity was created
    updated_at: DateTime
      ## The date and time when the entity was last updated

  PaddleApiResponseMetaPagination* = object
    ## Keys used for working with paginated results
    per_page*: uint8
      ## Number of entities per page for this response. May differ from the
      ## number requested if the requested number is greater than the maximum
    next*: string
      ## URL containing the query parameters of the original request, along with the
      ## after parameter that marks the starting point of the next page. Always returned,
      ## even if has_more is false.
    has_more*: bool
      ## Whether this response has another page of results after this one.
    estimated_total*: uint8
      ## An estimate of the total number of entities matching the query.
      ## May differ from the actual total.
    
  PaddleApiResponseMeta* = object
    request_id*: string
    pagination*: PaddleApiResponseMetaPagination

  PaddleApiResponse*[T] = object of RootObj
    data*: T
    meta*: PaddleApiResponseMeta

  PaddleClient* = object
    ## Represents a client for making API requests to the Paddle service
    baseUri: string
      # The base URI for the Paddle API
    api_key: string
      # The API key used for authentication with the Paddle service
    client: AsyncHttpClient
      # The underlying HTTP client used for making requests to the
      # Paddle service
  
  PaddleClientError* = object of CatchableError

  QueryTable* = OrderedTable[string, string]
    ## A table for storing query parameters to be included in API requests.
    ## The keys and values are both strings.

proc initPaddleClient*(apiKey: string): PaddleClient =
  ## Creates a new `PaddleClient` with the provided API key. The API key is included in the Authorization header as
  ## a Bearer token for authentication with the Paddle service.
  result.client = newAsyncHttpClient()
  result.baseUri =
    if apiKey.startsWith("pdl_sdbx_apikey_"):
      "https://sandbox-api.paddle.com/"
    else:
      "https://api.paddle.com/" # production
  result.client.headers = newHttpHeaders({
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": "Bearer " & apiKey,
  })

proc parseHook*(parser: var json.JsonParser, v: var DateTime) =
  let s = parser.curr.value
  parser.advance()

  # 2026-05-03T17:30:47Z
  # 2026-05-03T17:30:47.71Z
  # 2026-05-03T17:30:47.091234Z
  if not s.endsWith("Z"):
    raise newException(TimeParseError, "Unsupported datetime format: " & s)

  var core = s[0 .. ^2] # strip trailing 'Z'
  let dot = core.rfind('.')

  if dot < 0:
    core &= ".000000"
  else:
    let head = core[0 ..< dot]
    var frac = core[(dot + 1) .. ^1]
    if frac.len > 6:
      frac = frac[0 ..< 6]
    elif frac.len < 6:
      frac &= repeat('0', 6 - frac.len)
    core = head & "." & frac

  let normalized = core & "Z"
  v = times.parse(normalized, "yyyy-MM-dd'T'HH:mm:ss'.'ffffffz", utc())

proc dumpHook*(s: var string, v: DateTime) =
  add s, '"'
  add s, v.format("yyyy-MM-dd'T'hh:mm:ss'.'ffffffz", DefaultLocale)
  add s, '"'

proc `$`*(query: QueryTable): string =
  ## Convert `query` QueryTable to string
  if query.len > 0:
    add result, "?"
    add result, join(query.keys.toSeq.mapIt(it & "=" & query[it]), "&")

proc httpGet*(client: PaddleClient, endpoint: string,
          query: QueryTable): Future[AsyncResponse] {.async.} =
  ## Makes a `GET` request to the specified endpoint of the Paddle API
  ## using the provided `PaddleClient`
  let url = client.baseUri & endpoint & $query
  await client.client.get(url)

proc httpGet*(client: PaddleClient, endpoint: string): Future[AsyncResponse] {.async.} =
  ## Makes a `GET` request to the specified endpoint of the Paddle API
  ## using the provided `PaddleClient`
  let url = client.baseUri & endpoint
  await client.client.get(url)

proc httpPost*[T](client: PaddleClient, endpoint: string, body: T): Future[AsyncResponse] {.async.} =
  ## Makes a `POST` request to the specified endpoint of the Paddle API
  ## using the provided `PaddleClient` and JSON body
  let url = client.baseUri & endpoint
  echo json.toJson(body)
  await client.client.post(url, json.toJson(body))

proc len*[T](response: PaddleApiResponse[seq[T]]): int =
  ## Returns the number of products in the response
  response.data.len

proc isEmpty*[T](response: PaddleApiResponse[seq[T]]): bool =
  ## Returns true if the response contains no products,
  ## false otherwise
  response.data.len == 0