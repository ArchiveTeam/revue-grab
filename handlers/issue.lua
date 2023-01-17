local retry_common = require "Lib/retry_common"
local one_redirect = require "handlers/one_redirect"

local module = {}

local cur_stat_code = nil


module.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
	local newurl = urlpos["url"]["url"]
	-- Get images
	if string.match(newurl, "^https://s3%.amazonaws%.com/revue/") or string.match(newurl, "%.png$") or string.match(newurl, "%.jpe?g$") then
		queue_request({url=newurl}, retry_common.only_retry_handler(10, {200}))
	end
	-- For playbackability, get these redundant links with UTM stuff
	if string.match(newurl, "^https://www%.getrevue%.co/profile/.+%?.*utm") then
		queue_request({url=newurl}, retry_common.only_retry_handler(10, {200}))
	end
end


-- Example of 500ing page: https://www.getrevue.co/profile/thatwastheweek/issues/the-end-of-apps-and-the-rise-of-the-machines-1408682
-- Not covering these yet
module.httploop_result = function(url, err, http_stat)
	local sc = http_stat["statcode"]
	cur_stat_code = sc
	if sc == 200 then
		-- Putting this here - queue the /archive redirect as well
		local id = string.match(current_options.url, "%-([0-9]+)$")
		local user = string.match(current_options.url, "^https://www%.getrevue%.co/profile/([a-z0-9A-Z%-%_]+)/")
		queue_request({url="https://www.getrevue.co/profile/" .. user .. "/archive/" .. id}, one_redirect.make_one_redirect_handler({}, false))
	elseif sc == 500 then
		-- Do nothing
		-- E.g. https://www.getrevue.co/profile/thatwastheweek/issues/stop-breathe-think-1248871 - from https://web.archive.org/web/20221004003729/https://www.getrevue.co/profile/thatwastheweek/issues/stop-breathe-think-1248871 it may be because this was members-only
	else
		retry_common.retry_unless_hit_iters(10)
	end
end


module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200 or sc == 500
end

return module
