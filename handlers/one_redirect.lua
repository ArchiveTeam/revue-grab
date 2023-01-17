local urlparse = require("socket.url")
local retry_common = require "Lib/retry_common"

local module = {}

module.make_one_redirect_handler = function(result_handler, allow_404)
	local handler = {}
	handler.httploop_result = function(url, err, http_stat)
		local status_code = http_stat["statcode"]
		if status_code < 300 then
			error("Neither redirect nor error status code")
		elseif status_code < 400 then
			local newloc = urlparse.absolute(url["url"], http_stat["newloc"])
			assert(newloc)
			queue_request({url=newloc}, result_handler)
		elseif status_code == 404 and allow_404 then
			-- Nothing
		else
			retry_common.retry_unless_hit_iters(10)
		end
	end
	
	return handler
end


return module
