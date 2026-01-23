(ns metabase.driver.scratchbird
  (:require
    [metabase.driver :as driver]
    [metabase.driver.sql-jdbc :as sql-jdbc]
    [metabase.driver.sql-jdbc.connection :as sql-jdbc.conn]))

(defmethod driver/display-name :scratchbird [_]
  "ScratchBird")

(defmethod driver/connection-properties :scratchbird
  [_]
  [{:name "host" :display-name "Host" :type :string :default "localhost" :required true}
   {:name "port" :display-name "Port" :type :integer :default 3092 :required true}
   {:name "db" :display-name "Database" :type :string :required true}
   {:name "user" :display-name "Username" :type :string :required true}
   {:name "password" :display-name "Password" :type :password :required true}
   {:name "sslmode" :display-name "SSL Mode" :type :select
    :options [{:name "require"} {:name "verify-ca"} {:name "verify-full"}]
    :default "require"}
   {:name "sslrootcert" :display-name "CA Certificate" :type :string}
   {:name "sslcert" :display-name "Client Certificate" :type :string}
   {:name "sslkey" :display-name "Client Key" :type :string}
   {:name "application_name" :display-name "Application Name" :type :string :default "metabase"}
   {:name "connectTimeout" :display-name "Connect Timeout (seconds)" :type :integer}
   {:name "socketTimeout" :display-name "Socket Timeout (seconds)" :type :integer}
   {:name "binaryTransfer" :display-name "Binary Transfer" :type :boolean :default true}])

(defmethod driver/connection-details->spec :scratchbird
  [_ details]
  (sql-jdbc.conn/connection-details->spec
   details
   {:classname "com.scratchbird.jdbc.SBDriver"
    :subprotocol "scratchbird"
    :subname (format "//%s:%s/%s"
                     (:host details) (:port details) (:db details))}))

(defmethod driver/can-connect? :scratchbird
  [_ details]
  ;; Keep this aligned with Metabase driver API version.
  (sql-jdbc.conn/can-connect-with-details? details))

(defmethod driver/db-default-timezone :scratchbird
  [_ _]
  "UTC")

(defmethod driver/database-supports? [:scratchbird :schemas] [_ _ _] true)
(defmethod driver/database-supports? [:scratchbird :foreign-keys] [_ _ _] true)
(defmethod driver/database-supports? [:scratchbird :basic-aggregations] [_ _ _] true)

(defn init []
  (sql-jdbc/register-driver! :scratchbird))
