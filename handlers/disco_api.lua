local urlparse = require("socket.url")
local retry_common = require "Lib/retry_common"

local module = {}

local expecting_500 = false

module.get_urls = function(file, url, is_css, iri)
	if expecting_500 then
		assert(string.match(get_body(), "We couldn't find that page"))
	end
end

module.httploop_result = function(url, err, http_stat)
	expecting_500 = false
	assert(string.match(url["url"], "^https://www%.getrevue%.co/subscribers/%-token%-/lists/[0-9]+/subscribe$"))
	local sc = http_stat["statcode"]
	if sc == 302 then
		local newloc = urlparse.absolute(url["url"], http_stat["newloc"])
		assert(string.match(newloc, "^https://www%.getrevue%.co/profile/[a-z0-9A-Z%-%_]+$"))
		queue_request({url=newloc}, "profile", true)
	elseif sc == 500 then
		expecting_500 = true
	else
		retry_common.retry_unless_hit_iters(10)
	end
end


module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 302 or sc == 500
end

return module

