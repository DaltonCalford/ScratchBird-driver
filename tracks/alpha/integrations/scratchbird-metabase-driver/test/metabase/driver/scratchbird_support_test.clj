(ns metabase.driver.scratchbird-support-test
  (:require
    [clojure.test :refer [deftest is testing]]
    [metabase.driver.scratchbird-support :as support]))

(deftest jdbc-properties-accept-current-jdbc-parity-options
  (let [props (support/->jdbc-properties {:sslmode "disable"
                                          :binaryTransfer false
                                          :currentSchema "tenant.analytics"
                                          :front_door_mode "manager_proxy"
                                          :manager_auth_token "secret-token"
                                          :role "bi_reader"
                                          :application_name "metabase"
                                          :connectTimeout 7
                                          :socketTimeout 11})]
    (is (= "disable" (get props "sslmode")))
    (is (= "false" (get props "binaryTransfer")))
    (is (= "tenant.analytics" (get props "currentSchema")))
    (is (= "manager_proxy" (get props "front_door_mode")))
    (is (= "secret-token" (get props "manager_auth_token")))
    (is (= "bi_reader" (get props "role")))
    (is (= "7" (get props "connectTimeout")))
    (is (= "11" (get props "socketTimeout")))))

(deftest resolved-current-schema-honors-driver-aliases
  (is (= "tenant.ops" (support/resolved-current-schema {:currentSchema "tenant.ops"})))
  (is (= "tenant.ops" (support/resolved-current-schema {:searchPath "tenant.ops"})))
  (is (= "tenant.ops" (support/resolved-current-schema {:search_path "tenant.ops"}))))

(deftest feature-support-reflects-jdbc-metadata-surface
  (testing "metadata and index discovery stay explicitly enabled"
    (is (true? (:schemas support/scratchbird-feature-support)))
    (is (true? (:metadata/key-constraints support/scratchbird-feature-support)))
    (is (true? (:describe-fields support/scratchbird-feature-support)))
    (is (true? (:describe-indexes support/scratchbird-feature-support))))
  (testing "non-implemented privilege/upload surfaces stay disabled"
    (is (false? (:table-privileges support/scratchbird-feature-support)))
    (is (false? (:uploads support/scratchbird-feature-support)))))

(deftest connection-property-schema-exposes-expanded-jdbc-surface
  (let [names (set (map :name support/scratchbird-connection-properties))
        sslmode-prop (first (filter #(= "sslmode" (:name %))
                                    support/scratchbird-connection-properties))]
    (is (contains? names "currentSchema"))
    (is (contains? names "front_door_mode"))
    (is (contains? names "manager_auth_token"))
    (is (= #{"disable" "allow" "prefer" "require" "verify-ca" "verify-full"}
           (set (map :value (:options sslmode-prop)))))))
