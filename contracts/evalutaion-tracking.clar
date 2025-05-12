;; Evaluation Tracking Contract
;; Records and manages the selection process for bids

(define-data-var admin principal tx-sender)

;; Data structure for evaluation criteria
(define-map evaluation-criteria
  { tender-id: (string-ascii 64) }
  {
    technical-weight: uint,
    financial-weight: uint,
    experience-weight: uint,
    compliance-weight: uint,
    criteria-set-at: uint
  }
)

;; Data structure for bid evaluations
(define-map bid-evaluations
  { tender-id: (string-ascii 64), bidder: principal }
  {
    technical-score: uint,
    financial-score: uint,
    experience-score: uint,
    compliance-score: uint,
    total-score: uint,
    evaluator: principal,
    evaluation-time: uint,
    comments: (string-utf8 500)
  }
)

;; Data structure for winning bids
(define-map winning-bids
  { tender-id: (string-ascii 64) }
  {
    winner: principal,
    score: uint,
    selected-at: uint,
    reason: (string-utf8 500)
  }
)

;; Admin function to set evaluation criteria
(define-public (set-evaluation-criteria
    (tender-id (string-ascii 64))
    (technical-weight uint)
    (financial-weight uint)
    (experience-weight uint)
    (compliance-weight uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (+ (+ technical-weight financial-weight) (+ experience-weight compliance-weight)) u100) (err u1))
    (ok (map-set evaluation-criteria
      { tender-id: tender-id }
      {
        technical-weight: technical-weight,
        financial-weight: financial-weight,
        experience-weight: experience-weight,
        compliance-weight: compliance-weight,
        criteria-set-at: block-height
      }
    ))
  )
)

;; Admin function to evaluate a bid
(define-public (evaluate-bid
    (tender-id (string-ascii 64))
    (bidder principal)
    (technical-score uint)
    (financial-score uint)
    (experience-score uint)
    (compliance-score uint)
    (comments (string-utf8 500)))
  (let (
    (criteria (unwrap! (map-get? evaluation-criteria { tender-id: tender-id }) (err u404)))
    (technical-weighted (/ (* technical-score (get technical-weight criteria)) u100))
    (financial-weighted (/ (* financial-score (get financial-weight criteria)) u100))
    (experience-weighted (/ (* experience-score (get experience-weight criteria)) u100))
    (compliance-weighted (/ (* compliance-score (get compliance-weight criteria)) u100))
    (total (+ (+ technical-weighted financial-weighted) (+ experience-weighted compliance-weighted)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= technical-score u100) (err u2))
    (asserts! (<= financial-score u100) (err u2))
    (asserts! (<= experience-score u100) (err u2))
    (asserts! (<= compliance-score u100) (err u2))

    (ok (map-set bid-evaluations
      { tender-id: tender-id, bidder: bidder }
      {
        technical-score: technical-score,
        financial-score: financial-score,
        experience-score: experience-score,
        compliance-score: compliance-score,
        total-score: total,
        evaluator: tx-sender,
        evaluation-time: block-height,
        comments: comments
      }
    ))
  )
)

;; Admin function to select winning bid
(define-public (select-winning-bid
    (tender-id (string-ascii 64))
    (winner principal)
    (reason (string-utf8 500)))
  (let (
    (evaluation (unwrap! (map-get? bid-evaluations { tender-id: tender-id, bidder: winner }) (err u404)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set winning-bids
      { tender-id: tender-id }
      {
        winner: winner,
        score: (get total-score evaluation),
        selected-at: block-height,
        reason: reason
      }
    ))
  )
)

;; Public function to get evaluation criteria
(define-read-only (get-evaluation-criteria (tender-id (string-ascii 64)))
  (map-get? evaluation-criteria { tender-id: tender-id })
)

;; Public function to get bid evaluation
(define-read-only (get-bid-evaluation (tender-id (string-ascii 64)) (bidder principal))
  (map-get? bid-evaluations { tender-id: tender-id, bidder: bidder })
)

;; Public function to get winning bid
(define-read-only (get-winning-bid (tender-id (string-ascii 64)))
  (map-get? winning-bids { tender-id: tender-id })
)

;; Admin function to update admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
