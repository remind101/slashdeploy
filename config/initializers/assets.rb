# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '2.0'
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')

# rballestrini commented this out because we were getting the following error:
#
#     ActionView::Template::Error:
#       undefined method `start_with?' for /\.(?:svg|eot|woff|ttf)\z/:Regexp
#
#Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)\z/
