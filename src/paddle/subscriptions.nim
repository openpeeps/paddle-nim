# A Nim client for the Paddle API
# https://developer.paddle.com/api-reference/subscriptions/overview
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/paddle-nim

import ./api, ./prices

type
  PaddleSubscriptionStatus* = enum
    active = "active"
    paused = "paused"
    canceled = "canceled"
    past_due = "past_due"
    trialing = "trialing"

  PaddleDiscountType* = enum
    recurring = "recurring"
      ## Discount applies to multiple billing periods
    oneOff = "one-off"
      ## Discount applies to a single billing period only. Returned when a subscription
      ## is created in trial with a discount. The discount is removed from the subscription on renewal.
    
  PaddlePeriod* = object
    starts_at: DateTime
    ends_at: DateTime

  PaddleDiscount* = object
    id: PaddleEntryId
      ## Unique identifier for the discount, prefixed with `dsc_`.
    starts_at: Option[DateTime]
    ends_at: Option[DateTime]
    `type`*: PaddleDiscountType

  PaddleCollectionMethod* = enum
    automatic = "automatic"
      ## Payment is collected automatically using a checkout initially,
      ## then using a payment method on file.
    manual = "manual"
      ## Payment is collected manually. Customers are sent an invoice
      ## with payment terms and can make a payment offline or using a checkout. Requires billing_details.
  
  PaddlePaymentTerms* = object
    interval: PaddleBillingInterval
      ## The billing interval for the payment terms, e.g. day, week, month, year.
    frequency: int
      ## The billing frequency for the payment terms. For example, if `interval` is `

  PaddleBillingDetails* = object
    additional_information*: string
      ## Notes or other information to include on this invoice. Appears on invoice documents.
    enable_checkout*: bool
      ## Whether the related transaction may be paid using Paddle Checkout.
      ## If omitted when creating a transaction, defaults to false.
    payment_terms*: PaddlePaymentTerms
      ## The payment terms for invoices created for this subscription
      ## Required if collection_mode is manual.
    purchase_order_number*: string
      ## The purchase order number to include on this invoice. Appears on invoice documents.

  PaddleScheduledChangeAction* = enum 
    cancel = "cancel"
      ## Cancel the subscription at the end of the current billing period.
    pause = "pause"
      ## Pause the subscription at the end of the current billing period.
      ## The subscription will remain paused until a resume subscription operation is performed.
    resume = "resume"
      ## Resume a paused subscription at the end of the current billing period.
      ## If the subscription is not paused, this action has no effect.

  PaddleScheduledChange* = object
    ## Change that's scheduled to be applied to a subscription
    action*: PaddleScheduledChangeAction
    effective_at*: DateTime
      ## RFC 3339 datetime string of when this scheduled change takes effect
    resume_at*: Option[DateTime]
      ## RFC 3339 datetime string of when a paused subscription should resume.
      ## Only used for pause scheduled changes.
  
  PaddleManagementUrls* = object
    update_payment_method*: Option[string]
      ## Link to the page for this subscription in the customer portal with
      ## the payment method update form pre-opened
    cancel*: string
      ## Link to the page for this subscription in the customer portal with
      ## the subscription cancellation form pre-opened

  PaddleSubscriptionItemStatus* = enum
    active = "active"
    inactive = "inactive"
    trialing = "trialing"

  PaddleSubscriptionItem* = object
    status*: PaddleSubscriptionItemStatus
      ## The status of this subscription item
    quantity*: uint8
      ## The quantity of this subscription item. Must be a positive integer.
    recurring*: bool
      ## Whether this is a recurring item. false if one-time
    created_at*: DateTime
      ## The date and time when the subscription item was created
    updated_at*: DateTime
      ## The date and time when the subscription item was last updated
    previously_billed_at*: Option[DateTime]
      ## The date and time when this subscription item was last billed
    next_billed_at*: Option[DateTime]
      ## The date and time when this subscription item will be billed next
    trial_dates*: Option[PaddlePeriod]
      ## The trial period for this subscription item, if any
    price*: PaddlePrice
      ## Related price entity for this item. This reflects the price entity
      ## at the time it was added to the subscription

  PaddleConsentRequirementType* = enum
    trialEnding = "trial_ending"
    introductoryDiscountEnding = "introductory_discount_ending"
  
  PaddleConsentRequirementStatus* = enum
    pending = "pending"
    granted = "granted"
    voided = "voided"

  PaddleConsentRequirement* = object
    id: PaddleEntryId
      ## Unique identifier for the consent requirement, prefixed with `subconreq_`.
    requirement*: PaddleConsentRequirementType
    status*: PaddleConsentRequirementStatus
    created_at*: DateTime
    consent_period*: Option[PaddlePeriod]
    granted_at*: Option[DateTime]
    voided_at*: Option[DateTime]

  PaddleSubscription* = object
    ## Represents a subscription entity with included entities
    id*: PaddleEntryId
      ## Unique identifier for the subscription, prefixed with `sub_`.
    customer_id*: PaddleEntryId
      ## Paddle ID for the customer that this subscription belongs to, prefixed with `ctm_`.
    address_id*: string
      ## The unique identifier for the subscription's billing address, prefixed with `add_`.
    business_id*: string
      ## Paddle ID of the business that this subscription is for, prefixed with biz_.
    currency_code*: CurrencyCode
      ## The three-letter ISO currency code for the subscription, e.g. `USD`, `EUR`, etc.
    creatd_at*: DateTime
      ## The date and time when the subscription was created, in ISO 8601 format.
    updated_at*: DateTime
      ## The date and time when the subscription was last updated, in ISO 8601 format.
    started_at*: DateTime
      ## The date and time when the subscription started, in ISO 8601 format.
    first_billed_at*: DateTime
      ## The date and time when the subscription was first billed, in ISO 8601 format.
    next_billed_at*: DateTime
      ## The date and time when the subscription will be billed next, in ISO 8601 format.
    paused_at*: Option[DateTime]
      ## The date and time when the subscription was paused, in ISO 8601 format.
    canceled_at*: Option[DateTime]
      ## The date and time when the subscription was canceled, in ISO 8601 format.
    discount*: PaddleDiscount
      ## The discount applied to this subscription, if any.
    case collection_mode*: PaddleCollectionMethod ## How payment is collected for transactions created for this subscription. automatic for checkout, manual for invoices.
    of manual:
      billing_details*: PaddleBillingDetails
        ## Details for invoicing
    else: discard
    current_billing_period*: PaddlePeriod
      ## Current billing period for this subscription. Set automatically
      ## by Paddle based on the billing cycle. null for paused and canceled subscriptions.
    billing_cycle*: PaddlePaymentTerms
      ## How often this subscription renews. Set automatically by
      ## Paddle based on the prices on this subscription.
    scheduled_change*: Option[PaddleScheduledChange]
      ## Change that's scheduled to be applied to a subscription.
      ## Use the pause subscription, cancel subscription, and resume
      ## subscription operations to create scheduled changes
    management_urls*: PaddleManagementUrls
      ## Customer portal deep links for this subscription.
    items*: seq[PaddleSubscriptionItem]
      ## The subscription items included in this subscription.
      ## A subscription must have at least one subscription item.
    custom_data*: JsonNode
      ## Your own structured key-value data for this subscription item
    import_meta*: JsonNode
      ## Import information for this subscription item. null
      ## if this subscription item is not imported.
    consent_requirements*: seq[PaddleConsentRequirement]
      ## List of active consent requirements for the subscription's current billing period.

proc getSubscriptions*(client: PaddleClient): Future[PaddleApiResponse[seq[PaddleSubscription]]] {.async.} = 
  ## Retrieves a list of subscriptions.
  let res: AsyncResponse = await client.httpGet("subscriptions")
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[seq[PaddleSubscription]])
  else:
    raise newException(PaddleClientError, body)

proc getSubscription*(client: PaddleClient, id: PaddleEntryId): Future[PaddleApiResponse[PaddleSubscription]] {.async.} = 
  ## Retrieves a single subscription by its unique identifier.
  let res: AsyncResponse = await client.httpGet("subscriptions/" & id)
  let body = await res.body
  case res.code:
  of Http200:
    result = fromJson(body, PaddleApiResponse[PaddleSubscription])
  else:
    raise newException(PaddleClientError, body)
