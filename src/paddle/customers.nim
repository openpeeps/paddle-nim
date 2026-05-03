# A Nim client for the Paddle API
# https://developer.paddle.com/api-reference/
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/paddle-nim
import ./api

type
  PaddleCustomer* = object of PaddleBaseObject
    email*: string
      ## The customer's email address
    name*: string
      ## The customer's full name
    locate*: string
      ## Valid IETF BCP 47 short form locale tag. If omitted, defaults to `en`
  
  PaddleCustomerToken* = object of PaddleBaseObject
    customer_auth_token: string
    expires_at: DateTime

proc getCustomers*(client: PaddleClient): Future[PaddleApiResponse[seq[PaddleCustomer]]] {.async.} = 
  ## Retrieves a list of customers.
  let res: AsyncResponse = await client.httpGet("customers")
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[seq[PaddleCustomer]])
  else:
    raise newException(PaddleClientError, body)

proc getCustomer*(client: PaddleClient, id: PaddleEntryId): Future[PaddleApiResponse[PaddleCustomer]] {.async.} = 
  ## Retrieves a single customer by its unique identifier.
  let res: AsyncResponse = await client.httpGet("customers/" & id)
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[PaddleCustomer])
  else:
    raise newException(PaddleClientError, body)

proc postCustomer*(client: PaddleClient, email: string, name: string,
                    locale: Option[string] = none(string)
    ): Future[PaddleApiResponse[PaddleCustomer]] {.async.} = 
  ## Creates a new customer with the specified parameters.
  var body = %*{
    "email": email,
    "name": name
  }

  if locale.isSome:
    body["locale"] = newJString(locale.get())

  let res: AsyncResponse = await client.httpPost("customers", body)
  let resBody = await res.body
  case res.code:
  of Http201:
    result = fromJson(resBody, PaddleApiResponse[PaddleCustomer])
  else:
    raise newException(PaddleClientError, resBody)

proc patchCustomer*(client: PaddleClient, id: PaddleEntryId,
          email: Option[string] = none(string),
          name: Option[string] = none(string),
          locale: Option[string] = none(string)
    ): Future[PaddleApiResponse[PaddleCustomer]] {.async.} = 
  ## Updates an existing customer with the specified parameters.
  var body = %*{}

  if email.isSome:
    body["email"] = newJString(email.get())
  if name.isSome:
    body["name"] = newJString(name.get())
  if locale.isSome:
    body["locale"] = newJString(locale.get())

  let res: AsyncResponse = await client.httpPatch("customers/" & id, body)
  let resBody = await res.body
  case res.code:
  of Http200:
    result = fromJson(resBody, PaddleApiResponse[PaddleCustomer])
  else:
    raise newException(PaddleClientError, resBody)

proc genAuthToken*(client: PaddleClient, customerId: PaddleEntryId): Future[ApiResponseData[PaddleCustomerToken]] {.async.} =
  ## Generates a customer authentication token.
  let res: AsyncResponse = await client.httpPost("customers/" & customerId & "/auth-token")
  let resBody = await res.body
  case res.code:
  of Http200:
    result = fromJson(resBody, ApiResponseData[PaddleCustomerToken])
  else:
    raise newException(PaddleClientError, resBody)