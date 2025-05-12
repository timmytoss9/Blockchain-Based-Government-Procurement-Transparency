;; Vendor Verification Contract
;; This contract validates qualified suppliers for government procurement

(define-data-var admin principal tx-sender)

;; Data structure for vendor information
(define-map vendors
  { vendor-id: (string-ascii 64) }
  {
    principal: principal,
    name: (string-ascii 100),
    registration-number: (string-ascii 50),
    verified: bool,
    verification-date: uint,
    category: (string-ascii 50)
  }
)

;; Public function to register a new vendor
(define-public (register-vendor
    (vendor-id (string-ascii 64))
    (name (string-ascii 100))
    (registration-number (string-ascii 50))
    (category (string-ascii 50)))
  (begin
    (asserts! (not (default-to false (get verified (map-get? vendors { vendor-id: vendor-id })))) (err u1))
    (ok (map-set vendors
      { vendor-id: vendor-id }
      {
        principal: tx-sender,
        name: name,
        registration-number: registration-number,
        verified: false,
        verification-date: u0,
        category: category
      }
    ))
  )
)

;; Admin function to verify a vendor
(define-public (verify-vendor (vendor-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? vendors { vendor-id: vendor-id })) (err u404))
    (ok (map-set vendors
      { vendor-id: vendor-id }
      (merge (unwrap-panic (map-get? vendors { vendor-id: vendor-id }))
        {
          verified: true,
          verification-date: block-height
        }
      )
    ))
  )
)

;; Public function to check if a vendor is verified
(define-read-only (is-verified-vendor (vendor-id (string-ascii 64)))
  (default-to false (get verified (map-get? vendors { vendor-id: vendor-id })))
)

;; Public function to get vendor details
(define-read-only (get-vendor-details (vendor-id (string-ascii 64)))
  (map-get? vendors { vendor-id: vendor-id })
)

;; Admin function to update admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
