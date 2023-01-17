-- TODO description
local qiu = require "Framework/queue_item"
while true do
	local line = io.read()
	if not line then
		break
	end
	print(arg[1] .. ":" .. qiu.serialize_request_options({url=line}))
end
