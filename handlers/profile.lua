local retry_common = require "Lib/retry_common"

local module = {}

local cur_stat_code = nil

module.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
	local newurl = urlpos["url"]["url"]
	-- Get images, viz. profile image
	if string.match(newurl, "^https://s3%.amazonaws%.com/revue/") or string.match(newurl, "%.png$") or string.match(newurl, "%.jpe?g$") then
		queue_request({url=newurl}, retry_common.only_retry_handler(10, {200}))
	end
	-- Get first page stuff
	if string.match(newurl, "^https?://www%.getrevue%.co/profile/[a-z0-9A-Z%-%_]+/issues/[^/]+$") then
		queue_request({url=newurl}, "issue")
	end
end


module.get_urls = function(file, url, is_css, iri)
	if cur_stat_code == 200 then
		local csrf_token = string.match(get_body(), '<meta name="csrf%-token" content="([^" ]+)" />')
		local profile = string.match(current_options.url, "^https://www%.getrevue%.co/profile/([a-z0-9A-Z%-%_]+)")
		queue_request({url="https://www.getrevue.co/profile/" .. profile .. "/issues", body_data="p=1", method="POST", headers={["X-CSRF-Token"]=csrf_token}}, "issues")
	end
end

module.httploop_result = function(url, err, http_stat)
	local sc = http_stat["statcode"]
	cur_stat_code = sc
	if sc == 200 or sc == 404 then
		-- Nothing; get_urls will do the interesting part
	else
		retry_common.retry_unless_hit_iters(10)
	end
end


module.write_to_warc = function(url, http_stat)
	local sc = http_stat["statcode"]
	return sc == 200 or sc == 404
end

return module

