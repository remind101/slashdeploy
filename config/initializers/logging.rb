STDOUT.sync = true

#logger = Logger.new(Rails.env.test? ? nil : STDOUT)
logger = Logger.new(STDOUT)
Rails.logger = Perty::Logger.new(logger)

Rails.configuration.lograge.logger = Rails.logger
