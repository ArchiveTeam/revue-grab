local retry_common = {}
local socket = require "socket"



retry_common.retry_unless_hit_iters = function(max, give_up_instead_of_crashing)
	local new_options = deep_copy(current_options)
	local cur_try = new_options["try"] or 1
	if cur_try > max then
		if not give_up_instead_of_crashing then
			error("Crashing due to too many retries")
		else
			print("Giving up due to too many retries...")
			return
		end
	end
	new_options["try"] = cur_try + 1
	new_options["delay_until"] = socket.gettime() + 2^(cur_try + 1)
	queue_request(new_options, current_handler)
end

retry_common.only_retry_handler = function(max, allowed_status_codes)
	local handler = {}
	local allowed_sc_lookup = {}
	for _, v in pairs(allowed_status_codes) do
		allowed_sc_lookup[v] = true
	end
	handler.httploop_result = function(url, err, http_stat)
		if not allowed_sc_lookup[http_stat["statcode"]] then
			retry_common.retry_unless_hit_iters(max)
		end
	end
	handler.write_to_warc = function(url, http_stat)
		return allowed_sc_lookup[http_stat["statcode"]]
	end
	return handler
end

return retry_common
