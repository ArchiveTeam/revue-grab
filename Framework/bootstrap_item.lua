-- TODO description
local qiu = require "Framework/queue_item"
print(arg[1] .. ":" .. qiu.serialize_request_options({url=arg[2]}))
