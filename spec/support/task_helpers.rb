# frozen_string_literal: true

module TaskHelpers
  def wait_for_it(task)
    raise('The param `task` does not have an uid key.') unless task.key?('uid')

    client.wait_for_task(task['uid'])
  end
end
