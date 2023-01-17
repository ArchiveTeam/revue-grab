local urlparse = require("socket.url")
local JSON = require 'Lib/JSON'
local retry_common = require "Lib/retry_common"

local module = {}

local cur_stat_code = nil


module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local json = JSON:decode(get_body())
		local issues_html = json["issues"]
		local pc = 0
		for post in string.gmatch(issues_html, 'href=["\'](/profile/[^/ "\']+/[^" \']+)["\']') do
			queue_request({url=urlparse.absolute(current_options.url, post)}, "issue")
			pc = pc + 1
		end
		if issues_html ~= " " then
			local this_id = tonumber(string.match(current_options.body_data, "^p=([0-9]+)$"))
			assert(json["next_page"] == this_id + 1)
			queue_request({url=current_options["url"], body_data="p=" .. json["next_page"], method="POST", headers={["X-CSRF-Token"]=current_options.headers["X-CSRF-Token"]}}, module)
			assert(pc > 0)
		end
	end
end

module.httploop_result = function(url, err, http_stat)
	local sc = http_stat["statcode"]
	cur_stat_code = sc
	if sc == 200 then
		-- Nothing; get_urls will do the interesting part
	else
		retry_common.retry_unless_hit_iters(10)
	end
end


module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200
end

return module

