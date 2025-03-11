;; invoice-token.clar
;; This contract handles the tokenization of invoices

(define-data-var last-token-id uint u0)

(define-map invoices
  { token-id: uint }
  {
    issuer: principal,
    buyer: principal,
    amount: uint,
    due-date: uint,
    status: (string-ascii 20)
  }
)

(define-map token-ownership
  { token-id: uint }
  { owner: principal }
)

(define-read-only (get-last-token-id)
  (var-get last-token-id)
)

(define-read-only (get-invoice (token-id uint))
  (map-get? invoices { token-id: token-id })
)

(define-read-only (get-token-owner (token-id uint))
  (map-get? token-ownership { token-id: token-id })
)

(define-public (create-invoice (buyer principal) (amount uint) (due-date uint))
  (let
    (
      (new-id (+ (var-get last-token-id) u1))
    )
    (var-set last-token-id new-id)
    (map-set invoices
      { token-id: new-id }
      {
        issuer: tx-sender,
        buyer: buyer,
        amount: amount,
        due-date: due-date,
        status: "pending"
      }
    )
    (map-set token-ownership
      { token-id: new-id }
      { owner: tx-sender }
    )
    (ok new-id)
  )
)

(define-public (transfer-token (token-id uint) (recipient principal))
  (let
    (
      (token-owner (unwrap! (get-token-owner token-id) (err u1)))
    )
    (asserts! (is-eq tx-sender (get owner token-owner)) (err u2))
    (map-set token-ownership
      { token-id: token-id }
      { owner: recipient }
    )
    (ok true)
  )
)

(define-public (update-invoice-status (token-id uint) (new-status (string-ascii 20)))
  (let
    (
      (invoice (unwrap! (get-invoice token-id) (err u3)))
    )
    (asserts! (or (is-eq tx-sender (get issuer invoice)) (is-eq tx-sender (get buyer invoice))) (err u4))
    (map-set invoices
      { token-id: token-id }
      (merge invoice { status: new-status })
    )
    (ok true)
  )
)
