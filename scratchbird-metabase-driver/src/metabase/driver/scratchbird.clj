; ScratchBird-driver
; Copyright (c) 2025-2026 Dalton Calford
;
; Licensed under the Initial Developer's Public License Version 1.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at:
; https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
(ns metabase.driver.scratchbird
  (:require
    [clojure.string :as str]
    [metabase.driver :as driver]
    [metabase.driver.common :as driver.common]
    [metabase.driver.sql-jdbc :as sql-jdbc]
    [metabase.driver.sql-jdbc.connection :as sql-jdbc.conn]
    [metabase.driver.sql-jdbc.sync :as sql-jdbc.sync]
    [metabase.driver.sql.query-processor :as sql.qp]
    [metabase.util.honey-sql-2 :as h2x]))

(def ^:private scratchbird-type->base-type
  {"BOOLEAN"                   :type/Boolean
   "SMALLINT"                  :type/Integer
   "INTEGER"                   :type/Integer
   "INT"                       :type/Integer
   "BIGINT"                    :type/BigInteger
   "INT8"                      :type/BigInteger
   "REAL"                      :type/Float
   "FLOAT"                     :type/Float
   "DOUBLE"                    :type/Float
   "DOUBLE PRECISION"          :type/Float
   "NUMERIC"                   :type/Decimal
   "DECIMAL"                   :type/Decimal
   "CHAR"                      :type/Text
   "CHARACTER"                 :type/Text
   "VARCHAR"                   :type/Text
   "CHARACTER VARYING"         :type/Text
   "TEXT"                      :type/Text
   "CLOB"                      :type/Text
   "DATE"                      :type/Date
   "TIME"                      :type/Time
   "TIME WITHOUT TIME ZONE"    :type/Time
   "TIME WITH TIME ZONE"       :type/TimeWithTZ
   "TIMESTAMP"                 :type/DateTime
   "TIMESTAMP WITHOUT TIME ZONE" :type/DateTime
   "TIMESTAMP WITH TIME ZONE"  :type/DateTimeWithTZ
   "TIMESTAMPTZ"               :type/DateTimeWithTZ
   "UUID"                      :type/UUID
   "JSON"                      :type/JSON
   "JSONB"                     :type/JSON
   "BLOB"                      :type/*
   "BYTEA"                     :type/*
   "ARRAY"                     :type/Array
   "VECTOR"                    :type/Array
   "GEOMETRY"                  :type/*
   "GEOGRAPHY"                 :type/*
   "RECORD"                    :type/Structured
   "ROW"                       :type/Structured
   "VARIANT"                   :type/JSON
   "INET"                      :type/IPAddress
   "CIDR"                      :type/IPAddress
   "MACADDR"                   :type/Text
   "BIT"                       :type/*
   "BIT VARYING"               :type/*
   "XML"                       :type/Text
   "INTERVAL"                  :type/*
   "MONEY"                     :type/Decimal
   "SERIAL"                    :type/Integer
   "BIGSERIAL"                 :type/BigInteger})

(def ^:private scratchbird-feature-support
  {:foreign-keys                  true
   :schemas                       true
   :basic-aggregations            true
   :standard-deviation-aggregations true
   :expression-aggregations       true
   :percentile-aggregations       true
   :expressions                   true
   :expressions/today             true
   :expressions/datetime          true
   :expressions/date              true
   :expressions/integer           true
   :expressions/float             true
   :expressions/text              true
   :split-part                    true
   :regex                         true
   :regex/lookaheads-and-lookbehinds false
   :collate                       true
   :window-functions/cumulative   true
   :window-functions/offset       true
   :metadata/key-constraints      true
   :describe-fields               true
   :describe-indexes              true
   :table-privileges              true
   :nested-field-columns          false
   :uploads                       false
   :upload-with-auto-pk           false
   :connection/multiple-databases false
   :uuid-type                     true
   :identifiers-with-spaces       true})

(defn- normalize-db-type
  [database-type]
  (-> (or database-type "")
      str/trim
      str/upper-case
      (str/replace #"\s+" " ")
      (str/replace #"\(.*\)" "")
      str/trim))

(defn- require-tls!
  [details]
  (let [sslmode (some-> (:sslmode details) str/lower-case)]
    (when (= sslmode "disable")
      (throw (ex-info "ScratchBird requires TLS; sslmode=disable is not allowed." {:sslmode sslmode})))
    (or sslmode "require")))

(defn- ->jdbc-properties
  [details]
  (let [sslmode (require-tls! details)
        binary-transfer (if (contains? details :binaryTransfer)
                          (:binaryTransfer details)
                          true)]
    (when (false? binary-transfer)
      (throw (ex-info "binary_transfer=false is not supported." {:binaryTransfer binary-transfer})))
    (cond-> {"sslmode" sslmode
             "application_name" (or (:application_name details) "metabase")}
      (:sslrootcert details) (assoc "sslrootcert" (:sslrootcert details))
      (:sslcert details) (assoc "sslcert" (:sslcert details))
      (:sslkey details) (assoc "sslkey" (:sslkey details))
      (some? (:connectTimeout details)) (assoc "connectTimeout" (str (:connectTimeout details)))
      (some? (:socketTimeout details)) (assoc "socketTimeout" (str (:socketTimeout details)))
      (some? binary-transfer) (assoc "binaryTransfer" (str (boolean binary-transfer)))
      (some? (:sslpassword details)) (assoc "sslpassword" (:sslpassword details))
      (some? (:role details)) (assoc "role" (:role details)))))

(defmethod driver/display-name :scratchbird [_] "ScratchBird")

(defmethod driver/connection-properties :scratchbird
  [_]
  [{:name "host" :display-name "Host" :type :string :default "localhost" :required true}
   {:name "port" :display-name "Port" :type :integer :default 3092 :required true}
   {:name "db" :display-name "Database" :type :string :required true}
   {:name "user" :display-name "Username" :type :string :required true}
   {:name "password" :display-name "Password" :type :password :required true}
   {:name "sslmode" :display-name "SSL Mode" :type :select
    :options [{:name "require" :value "require"}
              {:name "verify-ca" :value "verify-ca"}
              {:name "verify-full" :value "verify-full"}]
    :default "require"}
   {:name "sslrootcert" :display-name "CA Certificate" :type :string}
   {:name "sslcert" :display-name "Client Certificate" :type :string}
   {:name "sslkey" :display-name "Client Key" :type :string}
   {:name "sslpassword" :display-name "SSL Key Password" :type :password}
   {:name "role" :display-name "Role" :type :string}
   {:name "application_name" :display-name "Application Name" :type :string :default "metabase"}
   {:name "connectTimeout" :display-name "Connect Timeout (seconds)" :type :integer}
   {:name "socketTimeout" :display-name "Socket Timeout (seconds)" :type :integer}
   {:name "binaryTransfer" :display-name "Binary Transfer" :type :boolean :default true
    :helper-text "ScratchBird uses binary-only parameter binding; keep enabled."}])

(defmethod sql-jdbc.conn/connection-details->spec :scratchbird
  [_ details]
  (let [props (->jdbc-properties details)
        host (or (:host details) "localhost")
        port (let [raw-port (or (:port details) 3092)]
               (if (string? raw-port)
                 (Integer/parseInt raw-port)
                 raw-port))
        db   (:db details)]
    {:classname "com.scratchbird.jdbc.SBDriver"
     :subprotocol "scratchbird"
     :subname (format "//%s:%s/%s" host port db)
     :user (:user details)
     :password (:password details)
     :properties props}))

(defmethod driver/can-connect? :scratchbird
  [driver details]
  (sql-jdbc.conn/can-connect? driver details))

(defmethod driver/db-default-timezone :scratchbird
  [_ _]
  "UTC")

(defmethod driver/db-start-of-week :scratchbird
  [_ _]
  :monday)

(doseq [[feature supported?] scratchbird-feature-support]
  (defmethod driver/database-supports? [:scratchbird feature] [_ _ _] supported?))

(defmethod sql-jdbc.sync/database-type->base-type :scratchbird
  [driver database-type]
  (let [normalized (normalize-db-type database-type)
        mapped (get scratchbird-type->base-type normalized)]
    (or mapped
        (sql-jdbc.sync/pattern-based-database-type->base-type driver database-type))))

(defmethod sql-jdbc.sync/column->semantic-type :scratchbird
  [driver database-type column-name]
  (let [normalized (normalize-db-type database-type)]
    (or (when (#{"JSON" "JSONB"} normalized) :type/SerializedJSON)
        ((get-method sql-jdbc.sync/column->semantic-type :sql-jdbc) driver database-type column-name))))

(defmethod sql.qp/current-datetime-honeysql-form :scratchbird
  [_driver]
  (h2x/current-datetime-honeysql-form :postgres))

(defn- extract-integer
  [unit expr]
  (h2x/->integer (h2x/extract unit (h2x/->pg-timestamp expr))))

(defn- date-trunc
  [unit expr]
  (let [expr' (h2x/->pg-timestamp expr)
        trunc [:date_trunc (h2x/literal unit) expr']]
    (h2x/with-database-type-info trunc (or (h2x/database-type expr') "timestamp"))))

(defmethod sql.qp/date [:scratchbird :default]          [_ _ expr] expr)
(defmethod sql.qp/date [:scratchbird :second-of-minute] [_ _ expr] (extract-integer :second expr))
(defmethod sql.qp/date [:scratchbird :minute]           [_ _ expr] (date-trunc :minute expr))
(defmethod sql.qp/date [:scratchbird :minute-of-hour]   [_ _ expr] (extract-integer :minute expr))
(defmethod sql.qp/date [:scratchbird :hour]             [_ _ expr] (date-trunc :hour expr))
(defmethod sql.qp/date [:scratchbird :hour-of-day]      [_ _ expr] (extract-integer :hour expr))
(defmethod sql.qp/date [:scratchbird :day-of-month]     [_ _ expr] (extract-integer :day expr))
(defmethod sql.qp/date [:scratchbird :day-of-year]      [_ _ expr] (extract-integer :doy expr))
(defmethod sql.qp/date [:scratchbird :month]            [_ _ expr] (date-trunc :month expr))
(defmethod sql.qp/date [:scratchbird :month-of-year]    [_ _ expr] (extract-integer :month expr))
(defmethod sql.qp/date [:scratchbird :quarter]          [_ _ expr] (date-trunc :quarter expr))
(defmethod sql.qp/date [:scratchbird :quarter-of-year]  [_ _ expr] (extract-integer :quarter expr))
(defmethod sql.qp/date [:scratchbird :year]             [_ _ expr] (date-trunc :year expr))
(defmethod sql.qp/date [:scratchbird :year-of-era]      [_ _ expr] (extract-integer :year expr))
(defmethod sql.qp/date [:scratchbird :week-of-year-iso] [_ _ expr] (extract-integer :week expr))

(defmethod sql.qp/date [:scratchbird :day-of-week]
  [driver _unit expr]
  (sql.qp/adjust-day-of-week driver
                             (h2x/+ (extract-integer :dow expr) 1)
                             (driver.common/start-of-week-offset-for-day :sunday)))

(defmethod sql.qp/date [:scratchbird :week]
  [_driver _unit expr]
  (sql.qp/adjust-start-of-week :scratchbird (partial date-trunc :week) expr))

(defmethod sql.qp/unix-timestamp->honeysql [:scratchbird :seconds]
  [_ _ expr]
  (h2x/with-database-type-info [:to_timestamp expr] "timestamptz"))

(defn init []
  (let [register (ns-resolve 'metabase.driver 'register!)]
    (if register
      (register :scratchbird :parent :sql-jdbc)
      (sql-jdbc/register-driver! :scratchbird))))
