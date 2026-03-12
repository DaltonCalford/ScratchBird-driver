(ns metabase.driver.scratchbird-support
  (:require
    [clojure.string :as str]))

(def scratchbird-type->base-type
  {"BOOLEAN"                     :type/Boolean
   "SMALLINT"                    :type/Integer
   "INTEGER"                     :type/Integer
   "INT"                         :type/Integer
   "BIGINT"                      :type/BigInteger
   "INT8"                        :type/BigInteger
   "REAL"                        :type/Float
   "FLOAT"                       :type/Float
   "DOUBLE"                      :type/Float
   "DOUBLE PRECISION"            :type/Float
   "NUMERIC"                     :type/Decimal
   "DECIMAL"                     :type/Decimal
   "CHAR"                        :type/Text
   "CHARACTER"                   :type/Text
   "VARCHAR"                     :type/Text
   "CHARACTER VARYING"           :type/Text
   "TEXT"                        :type/Text
   "CLOB"                        :type/Text
   "DATE"                        :type/Date
   "TIME"                        :type/Time
   "TIME WITHOUT TIME ZONE"      :type/Time
   "TIME WITH TIME ZONE"         :type/TimeWithTZ
   "TIMESTAMP"                   :type/DateTime
   "TIMESTAMP WITHOUT TIME ZONE" :type/DateTime
   "TIMESTAMP WITH TIME ZONE"    :type/DateTimeWithTZ
   "TIMESTAMPTZ"                 :type/DateTimeWithTZ
   "UUID"                        :type/UUID
   "JSON"                        :type/JSON
   "JSONB"                       :type/JSON
   "BLOB"                        :type/*
   "BYTEA"                       :type/*
   "ARRAY"                       :type/Array
   "VECTOR"                      :type/Array
   "GEOMETRY"                    :type/*
   "GEOGRAPHY"                   :type/*
   "COMPOSITE"                   :type/Structured
   "RANGE"                       :type/Structured
   "RECORD"                      :type/Structured
   "ROW"                         :type/Structured
   "VARIANT"                     :type/JSON
   "INET"                        :type/IPAddress
   "CIDR"                        :type/IPAddress
   "MACADDR"                     :type/Text
   "BIT"                         :type/*
   "BIT VARYING"                 :type/*
   "XML"                         :type/Text
   "INTERVAL"                    :type/*
   "MONEY"                       :type/Decimal
   "TSVECTOR"                    :type/Text
   "TSQUERY"                     :type/Text
   "UNKNOWN"                     :type/*
   "SERIAL"                      :type/Integer
   "BIGSERIAL"                   :type/BigInteger})

(def scratchbird-feature-support
  {:foreign-keys                    true
   :schemas                         true
   :basic-aggregations              true
   :standard-deviation-aggregations true
   :expression-aggregations         true
   :percentile-aggregations         true
   :expressions                     true
   :expressions/today               true
   :expressions/datetime            true
   :expressions/date                true
   :expressions/integer             true
   :expressions/float               true
   :expressions/text                true
   :split-part                      true
   :regex                           true
   :regex/lookaheads-and-lookbehinds false
   :collate                         true
   :window-functions/cumulative     true
   :window-functions/offset         true
   :metadata/key-constraints        true
   :describe-fields                 true
   :describe-indexes                true
   :table-privileges                false
   :nested-field-columns            false
   :uploads                         false
   :upload-with-auto-pk             false
   :connection/multiple-databases   false
   :uuid-type                       true
   :identifiers-with-spaces         true})

(def scratchbird-connection-properties
  [{:name "host" :display-name "Host" :type :string :default "localhost" :required true}
   {:name "port" :display-name "Port" :type :integer :default 3092 :required true}
   {:name "db" :display-name "Database" :type :string :required true}
   {:name "user" :display-name "Username" :type :string :required true}
   {:name "password" :display-name "Password" :type :password :required true}
   {:name "sslmode" :display-name "SSL Mode" :type :select
    :options [{:name "disable" :value "disable"}
              {:name "allow" :value "allow"}
              {:name "prefer" :value "prefer"}
              {:name "require" :value "require"}
              {:name "verify-ca" :value "verify-ca"}
              {:name "verify-full" :value "verify-full"}]
    :default "require"}
   {:name "sslrootcert" :display-name "CA Certificate" :type :string}
   {:name "sslcert" :display-name "Client Certificate" :type :string}
   {:name "sslkey" :display-name "Client Key" :type :string}
   {:name "sslpassword" :display-name "SSL Key Password" :type :password}
   {:name "role" :display-name "Role" :type :string}
   {:name "currentSchema" :display-name "Current Schema" :type :string
    :helper-text "Optional override. If omitted, ScratchBird uses the server-side user/role/group default schema, falling back to users.public."}
   {:name "front_door_mode" :display-name "Ingress Mode" :type :select
    :options [{:name "direct" :value "direct"}
              {:name "manager_proxy" :value "manager_proxy"}]
    :default "direct"}
   {:name "manager_auth_token" :display-name "Manager Auth Token" :type :password}
   {:name "application_name" :display-name "Application Name" :type :string :default "metabase"}
   {:name "connectTimeout" :display-name "Connect Timeout (seconds)" :type :integer}
   {:name "socketTimeout" :display-name "Socket Timeout (seconds)" :type :integer}
   {:name "binaryTransfer" :display-name "Binary Transfer" :type :boolean :default true
    :helper-text "ScratchBird uses binary-first parameter binding. Set false only for JDBC-compatibility paths that explicitly require text transfer."}])

(def ^:private allowed-sslmodes
  #{"disable" "allow" "prefer" "require" "verify-ca" "verify-full"})

(defn normalize-db-type
  [database-type]
  (-> (or database-type "")
      str/trim
      str/upper-case
      (str/replace #"\s+" " ")
      (str/replace #"\(.*\)" "")
      str/trim))

(defn normalize-sslmode
  [details]
  (let [sslmode (some-> (or (:sslmode details) "require") str/lower-case)]
    (when-not (contains? allowed-sslmodes sslmode)
      (throw (ex-info "ScratchBird requires a valid sslmode value."
                      {:sslmode sslmode
                       :allowed allowed-sslmodes})))
    sslmode))

(defn resolved-current-schema
  [details]
  (or (:currentSchema details)
      (:current_schema details)
      (:searchPath details)
      (:search_path details)))

(defn ->jdbc-properties
  [details]
  (let [sslmode (normalize-sslmode details)
        binary-transfer (if (contains? details :binaryTransfer)
                          (:binaryTransfer details)
                          true)
        current-schema (resolved-current-schema details)]
    (cond-> {"sslmode" sslmode
             "application_name" (or (:application_name details) "metabase")
             "binaryTransfer" (str (boolean binary-transfer))}
      (:sslrootcert details) (assoc "sslrootcert" (:sslrootcert details))
      (:sslcert details) (assoc "sslcert" (:sslcert details))
      (:sslkey details) (assoc "sslkey" (:sslkey details))
      (some? (:connectTimeout details)) (assoc "connectTimeout" (str (:connectTimeout details)))
      (some? (:socketTimeout details)) (assoc "socketTimeout" (str (:socketTimeout details)))
      (some? (:sslpassword details)) (assoc "sslpassword" (:sslpassword details))
      (some? (:role details)) (assoc "role" (:role details))
      (some? current-schema) (assoc "currentSchema" current-schema)
      (some? (:front_door_mode details)) (assoc "front_door_mode" (:front_door_mode details))
      (some? (:manager_auth_token details)) (assoc "manager_auth_token" (:manager_auth_token details)))))
