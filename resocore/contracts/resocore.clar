;; Smart City Resource Management System
;; Manages city resources like parking, waste management, and energy

;; Constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-ASSET (err u2))
(define-constant ERR-ASSET-UNAVAILABLE (err u3))
(define-constant ERR-INVALID-ARGS (err u4))
(define-constant ERR-INSUFFICIENT-FUNDS (err u5))
(define-constant ERR-SENSOR-NOT-FOUND (err u6))
(define-constant ERR-INVALID-VOLUME (err u7))
(define-constant ERR-INVALID-COST (err u8))
(define-constant ERR-INVALID-COORDINATES (err u9))
(define-constant ERR-INVALID-CAR (err u10))
(define-constant ERR-INVALID-SENSOR (err u11))

;; Resource Types
(define-constant ASSET-TYPE-PARKING u1)
(define-constant ASSET-TYPE-WASTE u2)
(define-constant ASSET-TYPE-POWER u3)

;; Configuration Constants
(define-constant MAX-VOLUME u1000000)
(define-constant MAX-COST u1000000000)

;; Data Variables
(define-data-var manager principal tx-sender)
(define-data-var asset-count uint u0)
(define-data-var min-parking-cost uint u1000) ;; in microSTX
(define-data-var power-rate uint u100) ;; cost per kWh in microSTX

;; Maps
(define-map assets
    uint
    {
        asset-type: uint,
        coordinates: (string-utf8 64),
        volume: uint,
        free: uint,
        operational: bool,
        cost: uint
    }
)

(define-map parking-spaces
    uint
    {
        space-id: uint,
        in-use: bool,
        car-id: (optional (string-utf8 32)),
        end-block: uint
    }
)

(define-map trash-containers
    uint
    {
        container-id: uint,
        fullness: uint,
        last-emptied: uint,
        requires-service: bool
    }
)

(define-map power-usage
    {asset-id: uint, client: principal}
    {
        reserved: uint,
        consumed: uint,
        last-check: uint
    }
)

(define-map sensors
    principal
    {
        sensor-id: (string-utf8 32),
        sensor-type: uint,
        asset-id: uint,
        operational: bool,
        last-signal: uint,
        verified: bool
    }
)

;; Validation Functions
(define-private (validate-coordinates (coordinates (string-utf8 64)))
    (> (len coordinates) u0))

(define-private (validate-volume (volume uint))
    (and (> volume u0) (<= volume MAX-VOLUME)))

(define-private (validate-cost (cost uint))
    (and (> cost u0) (<= cost MAX-COST)))

(define-private (validate-car-id (car-id (string-utf8 32)))
    (> (len car-id) u0))

(define-private (validate-sensor-id (sensor-id (string-utf8 32)))
    (> (len sensor-id) u0))

;; Authorization
(define-private (is-manager)
    (is-eq tx-sender (var-get manager)))

(define-private (is-verified-sensor)
    (match (map-get? sensors tx-sender)
        sensor (get verified sensor)
        false))

;; Resource Management Functions
(define-public (register-asset 
    (asset-type uint)
    (coordinates (string-utf8 64))
    (volume uint)
    (cost uint))
    (begin
        (asserts! (is-manager) ERR-UNAUTHORIZED)
        (asserts! (validate-coordinates coordinates) ERR-INVALID-COORDINATES)
        (asserts! (validate-volume volume) ERR-INVALID-VOLUME)
        (asserts! (validate-cost cost) ERR-INVALID-COST)
        (asserts! (or 
            (is-eq asset-type ASSET-TYPE-PARKING)
            (is-eq asset-type ASSET-TYPE-WASTE)
            (is-eq asset-type ASSET-TYPE-POWER))
            ERR-INVALID-ASSET)
        
        (let ((asset-id (var-get asset-count)))
            (map-set assets asset-id
                {
                    asset-type: asset-type,
                    coordinates: coordinates,
                    volume: volume,
                    free: volume,
                    operational: true,
                    cost: cost
                })
            (var-set asset-count (+ asset-id u1))
            (ok asset-id))))

;; Parking Management
(define-public (book-parking 
    (asset-id uint)
    (car-id (string-utf8 32))
    (duration uint))
    (let (
        (asset (unwrap! (map-get? assets asset-id) ERR-INVALID-ASSET))
        (parking-cost (* (get cost asset) duration))
        )
        (asserts! (validate-car-id car-id) ERR-INVALID-CAR)
        (asserts! (>= (get free asset) u1) ERR-ASSET-UNAVAILABLE)
        (asserts! (>= parking-cost (var-get min-parking-cost)) ERR-INSUFFICIENT-FUNDS)
        
        ;; Process payment
        (try! (stx-transfer? parking-cost tx-sender (var-get manager)))
        
        ;; Update parking spot
        (map-set parking-spaces asset-id
            {
                space-id: asset-id,
                in-use: true,
                car-id: (some car-id),
                end-block: (+ block-height duration)
            })
        
        ;; Update resource availability
        (map-set assets asset-id
            (merge asset {free: (- (get free asset) u1)}))
        
        (ok true)))

;; Waste Management
(define-public (update-trash-level
    (asset-id uint)
    (fullness uint))
    (begin
        (asserts! (is-verified-sensor) ERR-UNAUTHORIZED)
        (asserts! (<= fullness u100) ERR-INVALID-ARGS)
        (asserts! (is-some (map-get? assets asset-id)) ERR-INVALID-ASSET)
        
        (match (map-get? trash-containers asset-id)
            container (begin
                (map-set trash-containers asset-id
                    (merge container {
                        fullness: fullness,
                        requires-service: (> fullness u80),
                        last-emptied: block-height
                    }))
                (ok true))
            ERR-INVALID-ASSET)))

;; Energy Management
(define-public (reserve-power
    (asset-id uint)
    (amount uint))
    (let (
        (asset (unwrap! (map-get? assets asset-id) ERR-INVALID-ASSET))
        (power-cost (* amount (var-get power-rate)))
        )
        (asserts! (validate-volume amount) ERR-INVALID-VOLUME)
        (asserts! (>= (get free asset) amount) ERR-ASSET-UNAVAILABLE)
        
        ;; Process payment
        (try! (stx-transfer? power-cost tx-sender (var-get manager)))
        
        ;; Update energy allocation
        (map-set power-usage
            {asset-id: asset-id, client: tx-sender}
            {
                reserved: amount,
                consumed: u0,
                last-check: block-height
            })
        
        (map-set assets asset-id
            (merge asset {free: (- (get free asset) amount)}))
        
        (ok true)))

;; IoT Device Management
(define-public (register-sensor
    (sensor-id (string-utf8 32))
    (sensor-type uint)
    (asset-id uint))
    (begin
        (asserts! (is-manager) ERR-UNAUTHORIZED)
        (asserts! (validate-sensor-id sensor-id) ERR-INVALID-SENSOR)
        (asserts! (is-some (map-get? assets asset-id)) ERR-INVALID-ASSET)
        (asserts! (or 
            (is-eq sensor-type ASSET-TYPE-PARKING)
            (is-eq sensor-type ASSET-TYPE-WASTE)
            (is-eq sensor-type ASSET-TYPE-POWER))
            ERR-INVALID-ASSET)
        
        (map-set sensors tx-sender
            {
                sensor-id: sensor-id,
                sensor-type: sensor-type,
                asset-id: asset-id,
                operational: true,
                last-signal: block-height,
                verified: true
            })
        (ok true)))

(define-public (deactivate-sensor (sensor-principal principal))
    (begin
        (asserts! (is-manager) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? sensors sensor-principal)) ERR-SENSOR-NOT-FOUND)
        
        (match (map-get? sensors sensor-principal)
            sensor (begin
                (map-set sensors sensor-principal
                    (merge sensor {operational: false, verified: false}))
                (ok true))
            ERR-SENSOR-NOT-FOUND)))

(define-public (update-sensor-signal)
    (match (map-get? sensors tx-sender)
        sensor (begin
            (map-set sensors tx-sender
                (merge sensor {last-signal: block-height}))
            (ok true))
        ERR-SENSOR-NOT-FOUND))

;; Read-only functions
(define-read-only (get-asset-details (asset-id uint))
    (map-get? assets asset-id))

(define-read-only (get-parking-status (asset-id uint))
    (map-get? parking-spaces asset-id))

(define-read-only (get-trash-container-status (asset-id uint))
    (map-get? trash-containers asset-id))

(define-read-only (get-power-usage (asset-id uint) (client principal))
    (map-get? power-usage {asset-id: asset-id, client: client}))

(define-read-only (get-sensor-status (sensor-principal principal))
    (map-get? sensors sensor-principal))