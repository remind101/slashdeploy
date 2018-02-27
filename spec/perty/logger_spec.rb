require 'spec_helper'
require 'stringio'
require 'perty/logger'

RSpec.describe Perty::Logger do
  it 'logs to a logger' do
    buf = StringIO.new
    logger = Perty::Logger.new(Logger.new(buf))
    logger.info 'foo'
    expect(buf.string).to eq "foo\n"
  end

  describe '#with_requet_id' do
    it 'prefixes the log lines with the request id' do
      buf = StringIO.new
      logger = Perty::Logger.new(Logger.new(buf))
      logger.with_request_id('id') { logger.info 'foo' }
      expect(buf.string).to eq "request_id=id foo\n"
    end
  end

  describe '#with_module' do
    it 'prefixes the log line with a module' do
      buf = StringIO.new
      logger = Perty::Logger.new(Logger.new(buf))
      logger.with_module('slack commands') { logger.info 'foo' }
      expect(buf.string).to eq "[slack commands] foo\n"
    end

    it 'allows for nested modules' do
      buf = StringIO.new
      logger = Perty::Logger.new(Logger.new(buf))
      logger.with_module('slack commands') do
        logger.with_module('DeployCommand') do
          logger.info 'foo'
        end
        logger.info 'bar'
      end
      expect(buf.string).to eq <<-MSG.strip_heredoc
      [slack commands] [DeployCommand] foo
      [slack commands] bar
      MSG
    end
  end

  describe 'with request id and module' do
    it 'puts the request id first' do
      buf = StringIO.new
      logger = Perty::Logger.new(Logger.new(buf))
      logger.with_module('slack commands') { logger.with_request_id('id') { logger.info 'foo' } }
      expect(buf.string).to eq "[slack commands] request_id=id foo\n"
    end
  end
end
