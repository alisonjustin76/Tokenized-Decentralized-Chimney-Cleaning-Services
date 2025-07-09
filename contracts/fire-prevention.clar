;; Fire Prevention Contract
;; Ensures proper ventilation and safety compliance

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INVALID_ASSESSMENT (err u301))
(define-constant ERR_PROPERTY_NOT_FOUND (err u302))
(define-constant ERR_ASSESSMENT_NOT_FOUND (err u303))
(define-constant ERR_INVALID_STATUS (err u304))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var next-assessment-id uint u1)
(define-data-var assessment-fee uint u500000) ;; 0.5 STX

;; Data Maps
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    address: (string-ascii 200),
    chimney-type: (string-ascii 50),
    last-assessment: uint,
    compliance-status: (string-ascii 20),
    risk-level: (string-ascii 10)
  }
)

(define-map assessments
  { assessment-id: uint }
  {
    property-id: uint,
    assessor: principal,
    assessment-date: uint,
    ventilation-score: uint,
    safety-score: uint,
    compliance-score: uint,
    overall-rating: (string-ascii 10),
    recommendations: (string-ascii 500),
    next-assessment-due: uint,
    status: (string-ascii 20)
  }
)

(define-map safety-standards
  { standard-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    minimum-score: uint,
    active: bool
  }
)

(define-map property-assessments
  { property-id: uint }
  { assessment-ids: (list 50 uint) }
)

(define-map certified-assessors
  { assessor: principal }
  {
    certified: bool,
    specializations: (list 10 (string-ascii 50)),
    total-assessments: uint,
    rating: uint,
    active: bool
  }
)

(define-data-var next-property-id uint u1)
(define-data-var next-standard-id uint u1)

;; Public Functions

;; Register property for fire prevention monitoring
(define-public (register-property (address (string-ascii 200)) (chimney-type (string-ascii 50)))
  (let
    (
      (property-id (var-get next-property-id))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)

    ;; Create property record
    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        address: address,
        chimney-type: chimney-type,
        last-assessment: u0,
        compliance-status: "pending",
        risk-level: "unknown"
      }
    )

    ;; Initialize assessment list
    (map-set property-assessments
      { property-id: property-id }
      { assessment-ids: (list) }
    )

    ;; Increment property ID
    (var-set next-property-id (+ property-id u1))

    (ok property-id)
  )
)

;; Schedule fire prevention assessment
(define-public (schedule-assessment (property-id uint))
  (let
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
      (assessment-id (var-get next-assessment-id))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)

    ;; Create assessment record
    (map-set assessments
      { assessment-id: assessment-id }
      {
        property-id: property-id,
        assessor: tx-sender,
        assessment-date: u0,
        ventilation-score: u0,
        safety-score: u0,
        compliance-score: u0,
        overall-rating: "pending",
        recommendations: "",
        next-assessment-due: u0,
        status: "scheduled"
      }
    )

    ;; Update property assessments list
    (let
      (
        (current-list (default-to (list) (get assessment-ids (map-get? property-assessments { property-id: property-id }))))
      )
      (map-set property-assessments
        { property-id: property-id }
        { assessment-ids: (unwrap! (as-max-len? (append current-list assessment-id) u50) ERR_INVALID_ASSESSMENT) }
      )
    )

    ;; Increment assessment ID
    (var-set next-assessment-id (+ assessment-id u1))

    (ok assessment-id)
  )
)

;; Complete fire prevention assessment
(define-public (complete-assessment
  (assessment-id uint)
  (ventilation-score uint)
  (safety-score uint)
  (compliance-score uint)
  (recommendations (string-ascii 500)))
  (let
    (
      (assessment (unwrap! (map-get? assessments { assessment-id: assessment-id }) ERR_ASSESSMENT_NOT_FOUND))
      (assessor-data (unwrap! (map-get? certified-assessors { assessor: tx-sender }) ERR_UNAUTHORIZED))
      (overall-score (/ (+ ventilation-score safety-score compliance-score) u3))
      (rating (if (>= overall-score u80) "excellent"
                (if (>= overall-score u60) "good"
                  (if (>= overall-score u40) "fair" "poor"))))
      (risk (if (< overall-score u40) "high"
              (if (< overall-score u70) "medium" "low")))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (get certified assessor-data) ERR_UNAUTHORIZED)
    (asserts! (get active assessor-data) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status assessment) "scheduled") ERR_INVALID_STATUS)
    (asserts! (and (<= ventilation-score u100) (<= safety-score u100) (<= compliance-score u100)) ERR_INVALID_ASSESSMENT)

    ;; Update assessment with results
    (map-set assessments
      { assessment-id: assessment-id }
      (merge assessment {
        assessment-date: block-height,
        ventilation-score: ventilation-score,
        safety-score: safety-score,
        compliance-score: compliance-score,
        overall-rating: rating,
        recommendations: recommendations,
        next-assessment-due: (+ block-height u52560), ;; ~1 year in blocks
        status: "completed"
      })
    )

    ;; Update property with assessment results
    (let
      (
        (property (unwrap! (map-get? properties { property-id: (get property-id assessment) }) ERR_PROPERTY_NOT_FOUND))
      )
      (map-set properties
        { property-id: (get property-id assessment) }
        (merge property {
          last-assessment: block-height,
          compliance-status: (if (>= overall-score u60) "compliant" "non-compliant"),
          risk-level: risk
        })
      )
    )

    ;; Update assessor stats
    (map-set certified-assessors
      { assessor: tx-sender }
      (merge assessor-data {
        total-assessments: (+ (get total-assessments assessor-data) u1)
      })
    )

    (ok true)
  )
)

;; Register as fire safety assessor
(define-public (register-assessor (specializations (list 10 (string-ascii 50))))
  (begin
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)

    (map-set certified-assessors
      { assessor: tx-sender }
      {
        certified: false,
        specializations: specializations,
        total-assessments: u0,
        rating: u0,
        active: true
      }
    )

    (ok true)
  )
)

;; Certify assessor (only contract owner)
(define-public (certify-assessor (assessor principal))
  (let
    (
      (assessor-data (unwrap! (map-get? certified-assessors { assessor: assessor }) ERR_UNAUTHORIZED))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)

    (map-set certified-assessors
      { assessor: assessor }
      (merge assessor-data { certified: true })
    )

    (ok true)
  )
)

;; Add safety standard
(define-public (add-safety-standard (name (string-ascii 100)) (description (string-ascii 300)) (minimum-score uint))
  (let
    (
      (standard-id (var-get next-standard-id))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (<= minimum-score u100) ERR_INVALID_ASSESSMENT)

    (map-set safety-standards
      { standard-id: standard-id }
      {
        name: name,
        description: description,
        minimum-score: minimum-score,
        active: true
      }
    )

    (var-set next-standard-id (+ standard-id u1))
    (ok standard-id)
  )
)

;; Read-only Functions

(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-assessment (assessment-id uint))
  (map-get? assessments { assessment-id: assessment-id })
)

(define-read-only (get-assessor (assessor principal))
  (map-get? certified-assessors { assessor: assessor })
)

(define-read-only (get-safety-standard (standard-id uint))
  (map-get? safety-standards { standard-id: standard-id })
)

(define-read-only (get-property-assessments (property-id uint))
  (map-get? property-assessments { property-id: property-id })
)

(define-read-only (get-assessment-fee)
  (var-get assessment-fee)
)

;; Admin Functions

(define-public (set-assessment-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set assessment-fee new-fee)
    (ok true)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)
