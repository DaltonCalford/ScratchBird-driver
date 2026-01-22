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
