# load sidekiq testing for our tests and set testing mode to fake.
# Fake uses a queue object instead of talking to a real redis queue.
require 'sidekiq/testing'
Sidekiq::Testing.fake!
