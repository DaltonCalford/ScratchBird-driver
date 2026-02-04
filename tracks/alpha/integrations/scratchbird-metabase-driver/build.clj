; ScratchBird-driver
; Copyright (c) 2025-2026 Dalton Calford
;
; Licensed under the Initial Developer's Public License Version 1.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at:
; https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
(ns build
  (:require [clojure.tools.build.api :as b]))

(def lib 'scratchbird/metabase-driver)
(def version "0.1.0")
(def class-dir "target/classes")
(def basis (b/create-basis {:project "deps.edn"}))

(defn clean [_]
  (b/delete {:path "target"}))

(defn jar [_]
  (clean nil)
  (b/copy-dir {:src-dirs ["src" "resources"] :target-dir class-dir})
  (b/jar {:class-dir class-dir
          :jar-file (format "target/scratchbird-metabase-driver-%s.jar" version)}))
