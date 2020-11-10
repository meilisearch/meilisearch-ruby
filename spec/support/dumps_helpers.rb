# frozen_string_literal: true

module DumpsHelpers
  def wait_for_dump_creation(client, dump_uid, timeout_in_ms = 5000, interval_in_ms = 50)
    Timeout.timeout(timeout_in_ms.to_f / 1000) do
      loop do
        dump_status = client.dump_status(dump_uid)
        return dump_status if dump_status['status'] != 'in_progress'

        sleep interval_in_ms.to_f / 1000
      end
    end
  rescue Timeout::Error
    raise MeiliSearch::TimeoutError
  end
end
