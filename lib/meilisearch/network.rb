# https://meilisearch.notion.site/API-usage-Remote-search-request-f64fae093abf409e9434c9b9c8fab6f3
module Meilisearch
  module Network
    # self has a certain meaning in ruby
    # while it's not defined as a method in classes by default so there's nothing
    # preventing us from having a method called "self", I think it could cause confusion
    #
    # perhaps "whoami" or "host" or "me" or "shard_name" could be alternatives?
    # we could make an exception in the ruby sdk and call it remote_self but it sounds nonsensical
    def self
      http_get '/network/self'
    end

    def update_self(new_uid)
      # this is stated as both put and post in the notion doc
      # will be determined when 1.13 guides are out I suppose
      http_put '/network/self', new_uid.to_s
    end

    def remotes
      http_get '/network/remotes'
    end

    def remote(uid)
      http_get "/network/remotes/#{uid}"
    end

    def add_remote(remote)
      remote = Utils.trasform_attributes(remote)
      http_post '/network/remotes', remote
    end

    def update_remote(uid, remote_edits)
      remote_edits = Utils.trasform_attributes(remote_edits)
      http_patch "/network/remotes/#{uid}", remote_edits
    end

    def delete_remote(uid)
      http_delete "/network/remotes/#{uid}"
    end
  end
end
