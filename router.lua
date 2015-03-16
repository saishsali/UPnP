module(...,package.seeall)

local ffi = require("ffi")
local C = ffi.C
local app  = require("core.app")
local link = require("core.link")
local config = require("core.config")
local buffer = require("core.buffer")
local packet = require("core.packet")
local pcap = require("lib.pcap.pcap")
local bit = require("bit")
local library = require("apps.upnp.library")

local AF_INET = 2

local DEST_MAC = 0
local SOURCE_MAC = 6
local ETHERTYPE_OFFSET = 12
local IPV4_PROTOCOL_OFFSET = 23
local IPV4_SOURCE_OFFSET = 26
local IPV4_DEST_OFFSET = 30
local IPV4_SOURCE_PORT_OFFSET = 34
local IPV4_DEST_PORT_OFFSET = 36
local PAYLOAD_OFFSET = 42    -- Check different packet headers


Router = {}

function Router:getOutputLink(ip_address)
	local mac_address = self.client_information[ip_address]
	local name = ''

	for i = 1, #app.app_array do
		local application = app.app_array[i]
		if app.configuration.apps[application.name].arg.mac_address == mac_address then
			name = application.name
			break	
		end
	end

	for lnk, l in pairs(app.link_table) do
		if string.find(lnk,name..'.input') ~= nil then
			return l
		end
	end  
end

function Router:increment_ip()
	local client_id = ""
	local idx = #self.current_ip
	while true  do
		if string.sub(self.current_ip,idx,idx) == '.' then
			self.current_ip = string.sub(self.current_ip,1,idx) .. tostring(tonumber(client_id) + 1)
			break
		else
			client_id = string.sub(self.current_ip,idx,idx) .. client_id
		end
		idx = idx - 1
	end
end


function Router:relink()
   self.inputi, self.outputi = {}, {}
   for _,l in pairs(self.output) do
      table.insert(self.outputi, l)
   end
   for _,l in pairs(self.input) do
      table.insert(self.inputi, l)
   end
end


function Router:new(arg)
	local rules = arg and config.parse_app_arg(arg) or {}
    assert(rules)
	return setmetatable({my_ip = rules.start_ip, current_ip = rules.start_ip, client_count = 0, client_information = {}}, {__index = Router})
end



function Router:push()
	for index, i in ipairs(self.inputi) do
		for _ = 1, link.nreadable(i) do
			local p = link.receive(i)	   	
		    local buffer = p.iovecs[0].buffer.pointer + p.iovecs[0].offset	
		    local dest_mac_ptr1 = ffi.cast("uint32_t*", buffer + DEST_MAC)
		   	local dest_mac_ptr2 = ffi.cast("uint16_t*", buffer + DEST_MAC + 4)
		   	local source_mac_ptr1 = ffi.cast("uint32_t*", buffer + SOURCE_MAC)
		   	local source_mac_ptr2 = ffi.cast("uint16_t*", buffer + SOURCE_MAC + 4)
			local source_ip = ffi.cast("uint32_t*", buffer + IPV4_SOURCE_OFFSET)
		   	local dest_ip = ffi.cast("uint32_t*", buffer + IPV4_DEST_OFFSET)
		   	local source_port = ffi.cast("uint16_t*", buffer + IPV4_SOURCE_PORT_OFFSET)
		   	local dest_port = ffi.cast("uint16_t*", buffer + IPV4_DEST_PORT_OFFSET)
 	
		   	-- decimal value of FFFFFFFF (255.255.255.255) is 4294967295
		   	-- Assigning Ip address to client
		   	if source_ip[0] == 0 and dest_ip[0] == 4294967295 and source_port[0] == 68 and dest_port[0] == 67 then
			  	self.client_count = self.client_count + 1
			   	print('Router: Assigning Ip address to client ')
			   	self:increment_ip()
			   	self.client_information[self.current_ip] = library.mac_address_binary_to_text(source_mac_ptr1[0], source_mac_ptr2[0])
			   	for _, o in ipairs(self.outputi) do
			   		link.transmit(o,library.getPacket(8,11,'00:00:00:00:00:00', library.mac_address_binary_to_text(source_mac_ptr1[0], source_mac_ptr2[0]),self.my_ip,'255.255.255.255',67,68,self.current_ip))
		 		end

		 	-- Multicasting discovery packet
			elseif dest_ip[0] == 4211081199 and dest_port[0] == 1900 then
	   			print('Router: Multicasting discovery packet to all clients')
	   			local source_link = self:getOutputLink(library.ip_binary_to_text(source_ip))
	   			
	   			for _, o in ipairs(self.outputi) do
	   				if source_link ~= o then
	   					link.transmit(o,p)
	  				end
	   			end
	   		--[[elseif dest_port[0] == 1000 then
	   			print('Router: sending service request from client')
	   			link.transmit(self:getOutputLink(library.ip_binary_to_text(dest_ip)),p)
	   		]]--
	   		else
		  		--print('Router: sending description to client')
		  		link.transmit(self:getOutputLink(library.ip_binary_to_text(dest_ip)),p)  		
		  	end
		end
	end
end