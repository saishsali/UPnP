#!./snabb

local app = require("core.app")
local config = require("core.config")
local client = require("apps.upnp.client")
local router = require("apps.upnp.router")


local arg2 = {
		start_ip = "192.168.1.1",
		end_ip = "192.168.1.10"
	}

	local c1 = config.new()

	config.app(c1,"client1",client.Client,{ model = 1, service = 'print', mac_address = '9c:d2:1e:eb:fa:1a'})
	config.app(c1,"client2",client.Client,{ model = 2, service = 'display', mac_address = '9c:d2:1e:eb:fa:1b'})
	config.app(c1,"client3",client.Client,{ model = 3, service = 'scan', mac_address = '9c:d2:1e:eb:fa:1c' })
	config.app(c1,"Router1",router.Router,arg2)

	config.link(c1, "client1.output -> Router1.input1")
	config.link(c1, "Router1.output1 -> client1.input")
	config.link(c1, "client2.output -> Router1.input2")
	config.link(c1, "Router1.output2 -> client2.input")
	config.link(c1, "client3.output -> Router1.input3")
	config.link(c1, "Router1.output3 -> client3.input")
	app.configure(c1)
	app.main({duration = 1})


	local c2 = config.new()

	config.app(c2,"client1",client.Client,{ model = 1, service = 'print', mac_address = '9c:d2:1e:eb:fa:1a'})
	config.app(c2,"client2",client.Client,{ model = 2, service = 'display', mac_address = '9c:d2:1e:eb:fa:1b'})
	config.app(c2,"client3",client.Client,{ model = 3, service = 'scan', mac_address = '9c:d2:1e:eb:fa:1c' })
	config.app(c2,"client4",client.Client,{ model = 4, service = 'camera', mac_address = '9c:d2:1e:eb:fa:1d' })
	config.app(c2,"Router1",router.Router,arg2)

	config.link(c2, "client1.output -> Router1.input1")
	config.link(c2, "Router1.output1 -> client1.input")
	config.link(c2, "client2.output -> Router1.input2")
	config.link(c2, "Router1.output2 -> client2.input")
	config.link(c2, "client3.output -> Router1.input3")
	config.link(c2, "Router1.output3 -> client3.input") 
	config.link(c2, "client4.output -> Router1.input4")
	config.link(c2, "Router1.output4 -> client4.input")
	
	app.configure(c2)
	app.main({duration = 1})


	local c3 = config.new()

	config.app(c3,"client1",client.Client,{ model = 1, service = 'print', mac_address = '9c:d2:1e:eb:fa:1a'})
	--config.app(c3,"client2",client.Client,{ model = 2, service = 'display', mac_address = '9c:d2:1e:eb:fa:1b'})
	config.app(c3,"client3",client.Client,{ model = 3, service = 'scan', mac_address = '9c:d2:1e:eb:fa:1c' })
	config.app(c3,"client4",client.Client,{ model = 4, service = 'camera', mac_address = '9c:d2:1e:eb:fa:1d' })
	config.app(c3,"Router1",router.Router,arg2)

	config.link(c3, "client1.output -> Router1.input1")
	config.link(c3, "Router1.output1 -> client1.input")
	--config.link(c3, "client2.output -> Router1.input2")
	--config.link(c3, "Router1.output2 -> client2.input")
	config.link(c3, "client3.output -> Router1.input3")
	config.link(c3, "Router1.output3 -> client3.input") 
	config.link(c3, "client4.output -> Router1.input4")
	config.link(c3, "Router1.output4 -> client4.input")
	
	app.configure(c3)
	app.main({duration = 1})

--[[ local c2 = config.new()	
	config.app(c2,"client1",client.Client,{ model = 1 })
	config.app(c2,"Router1",Router.Router,arg2)
	
	config.link(c2, "client1.output -> Router1.input")	
	
	app.configure(c2)
	app.main({duration = 1})


	local c3 = config.new()

	config.app(c3,"client1",client.Client,{ model = 1 })
	config.app(c3,"client2",client.Client,{ model = 2 })
	config.app(c3,"Router1",Router.Router,arg2)
	

	config.link(c3, "client2.output -> Router1.input")
	config.link(c3, "Router1.output -> client2.input")
	app.configure(c3)
	app.main({done = fun1})


	local c4 = config.new()	
	config.app(c4,"client1",client.Client,{ model = 1 })
	config.app(c4,"client2",client.Client,{ model = 2 })
	config.app(c4,"Router1",Router.Router,arg2)
	
	config.link(c4, "client2.output -> Router1.input")	
	config.link(c4, "Router1.output -> client1.input")
	app.configure(c4)
	app.main({duration = 1})
]]--

--[[	local c3 = config.new()
	config.app(c3,"client1",client.Client,{ model = 1 })
	config.app(c3,"client2",client.Client,{ model = 2 })
	--config.app(c3,"client3",client.Client,{ model = 3 })
	config.app(c3,"Router1",Router.Router,arg2)

	--config.link(c3, "client1.output -> Router1.input")
	config.link(c3, "Router1.output -> client2.input")
	
	app.configure(c3)
	app.main({duration = 1})
]]--