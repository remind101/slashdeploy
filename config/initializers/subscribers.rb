ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args| 
  event = ActiveSupport::Notifications::Event.new(*args)
  controller = "controller:#{event.payload[:controller]}"
  action = "action:#{event.payload[:action]}"
  format = "format:#{event.payload[:format] || 'all'}"
  format = "format:all" if format == "format:*/*"
  status = event.payload[:status]
  tags = [controller, action, format]
  ActiveSupport::Notifications.instrument :performance, action: :timing, tags: tags, measurement: 'request.total_duration', value: event.duration
  ActiveSupport::Notifications.instrument :performance, action: :timing, tags: tags, measurement: 'database.query.time', value: event.payload[:db_runtime]
  ActiveSupport::Notifications.instrument :performance, action: :timing, tags: tags, measurement: 'web.view.time', value: event.payload[:view_runtime]
  ActiveSupport::Notifications.instrument :performance, tags: tags, measurement: "request.status.#{status}"
end

ActiveSupport::Notifications.subscribe /performance/ do |name, start, finish, id, payload| 
  action = payload[:action] || :increment
  measurement = payload[:measurement]
  value = payload[:value]
  tags = payload[:tags]
  key_name = "#{name}.#{measurement}"
  if action == :increment
    $statsd.increment key_name, tags: tags
  else
    $statsd.histogram key_name, value, tags: tags
  end
end
