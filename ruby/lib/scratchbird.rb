# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "scratchbird/client"
require "scratchbird/connection"
require "scratchbird/errors"
require "scratchbird/protocol"
require "scratchbird/result"
require "scratchbird/scram"
require "scratchbird/sql"
require "scratchbird/statement"
require "scratchbird/types"
require "scratchbird/config"

module Scratchbird
  def self.connect(uri_or_opts)
    Connection.new(uri_or_opts)
  end
end
