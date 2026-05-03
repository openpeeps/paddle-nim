# A Nim client for the Paddle API
# https://developer.paddle.com/api-reference/
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/paddle-nim
import ./api

type
  PaddleProduct* = object of PaddleBaseObject
    ## Represents a product entity with included entities
    name*: string
      ## The name of the product
    description*: string
      ## Short description for this product
    image_url*: string
      ## URL of the product image. Must be an HTTPS URL that is publicly accessible.
    tax_category*: PaddleTaxCategory

proc getProducts*(client: PaddleClient): Future[PaddleApiResponse[seq[PaddleProduct]]] {.async.} = 
  ## Retrieves a list of products.
  let res: AsyncResponse = await client.httpGet("products")
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[seq[PaddleProduct]])
  else:
    raise newException(PaddleClientError, body)

proc getProduct*(client: PaddleClient, id: PaddleEntryId): Future[PaddleApiResponse[PaddleProduct]] {.async.} = 
  ## Retrieves a single product by its unique identifier.
  let res: AsyncResponse = await client.httpGet("products/" & id)
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[PaddleProduct])
  else:
    raise newException(PaddleClientError, body)

proc postProduct*(client: PaddleClient, name: string,
          taxCategory = PaddleTaxCategory.standard,
          description: Option[string] = none(string),
          imageUrl: Option[string] = none(string),
          customData: JsonNode = nil,
    ): Future[PaddleApiResponse[PaddleProduct]] {.async.} = 
  ## Creates a new product with the specified parameters.
  ## 
  ## Paddle does not upload product images to a CDN. For image_url, you should
  ## host images on an HTTPS server that's publicly accessible.
  ## 
  ## Tips: Use square images (1:1 ratio) for best results
  var payload = %*{
    "name": name,
    "tax_category": taxCategory,
    "description": description,
    "image_url": imageUrl,
    "custom_data": customData,
  }

  let res: AsyncResponse = await client.httpPost("products", payload)
  let body = await res.body
  case res.code:
  of Http201:
    result = fromJson(body, PaddleApiResponse[PaddleProduct])
  else:
    raise newException(PaddleClientError, body)
