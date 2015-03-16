module(...,package.seeall)

local ffi = require("ffi")
local C = ffi.C
local app  = require("core.app")
local link = require("core.link")
local buffer = require("core.buffer")
local packet = require("core.packet")
local library = require("apps.upnp.library")


local DEST_MAC = 0
local SOURCE_MAC = 6
local ETHERTYPE_OFFSET = 12
local IPV4_PROTOCOL_OFFSET = 23
local IPV4_SOURCE_OFFSET = 26
local IPV4_DEST_OFFSET = 30
local IPV4_SOURCE_PORT_OFFSET = 34
local IPV4_DEST_PORT_OFFSET = 36
local PAYLOAD_OFFSET = 42


Client = {}

-- Performing DHCP Discover
-- Client sends a packet to the router requesting for IP address
function Client:addressing()
	print('Client: Addressing request by client '..self.model)
	link.transmit(self.output.output, library.getPacket(8,11,self.my_mac,'00:00:00:00:00:00','0.0.0.0','255.255.255.255',68,67,''))
end


function Client:discovery()
	print('Client: Discovery packet sent by client '..self.model)
	link.transmit(self.output.output, library.getPacket(8,11,self.my_mac,'00:00:00:00:00:00',self.my_ip,'239.255.255.250',0,1900,''))
end

function Client:control()
	print('Which service do you want Client '..self.model)
	local count, choice = 1, 0
	for _, feature in pairs(self.description) do
		print(count..') '..feature)
		count = count + 1	
	end
	print('0) No service')
	choice = io.read()	
	count = 1
	for dest_ip, _ in pairs(self.description) do
		if tonumber(choice,10) == count then
			print('Client: Sending service request from client '..self.model)
			link.transmit(self.output.output, library.getPacket(8,11,self.my_mac,'00:00:00:00:00:00',self.my_ip,dest_ip,2000,1000,''))
			break
		end
		count = count + 1
	end
end

function Client:new (arg)
   local rules = arg and config.parse_app_arg(arg) or {}
   assert(rules)
   return setmetatable({model = rules.model, service = rules.service , my_mac = rules.mac_address , my_ip = '', flag = 1, description = {}, client_cnt = 0 }, {__index = Client})
end


function Client:push()
	local i = assert(self.input.input, "input port not found")
	local o = assert(self.output.output, "output port not found")

	while not link.empty(i) and not link.full(o) do
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
	   	local payload = ffi.cast("char*", buffer + PAYLOAD_OFFSET)
	   	
	   if dest_ip[0] == 4211081199 and dest_port[0] == 1900 then 
		   	print('Client: Service information sent by client '..self.model..' : '..self.service)
		   	link.transmit(o,library.getPacket(8,11,self.my_mac,library.mac_address_binary_to_text(source_mac_ptr1[0],source_mac_ptr2[0]),self.my_ip,library.ip_binary_to_text(source_ip),0,1900,self.service))	

	 	-- Ip address received
	 	elseif self.my_ip == '' and dest_ip[0] == 4294967295 and library.mac_address_binary_to_text(dest_mac_ptr1[0],dest_mac_ptr2[0]) == self.my_mac and source_port[0] == 67 and dest_port[0] == 68 then
			local alloted_ip = ffi.cast("char*", buffer + PAYLOAD_OFFSET)
		   	self.my_ip = ffi.string(alloted_ip)
		   	print('Client: Ip address received by Client '..self.model..' is '..self.my_ip)
		   	self.flag = 2
	
		elseif dest_port[0] == 1900 then
	   		--print(self.my_ip)
	   		--print(ffi.string(payload))
	   		self.description[library.ip_binary_to_text(source_ip)] = ffi.string(payload)
	   		print('Client: Description received by client '..self.model..' : '..self.description[library.ip_binary_to_text(source_ip)])
	   		self.flag = 3
	   	
	   	elseif dest_port[0] == 1000 then
	   		print('Client: Service offered by client '..self.model)
	   	end
	end
end

function Client:pull()

	if self.flag == 1 then	-- Addressing stage
		self:addressing()
		self.flag = 0

	elseif self.flag == 2 then -- Discovery stage
		self.client_cnt = #app.app_array 
		self:discovery()
		self.flag = 0
	
	elseif #app.app_array ~= self.client_cnt then
		self.flag = 2
	
	elseif self.flag == 3 then -- Control stage
		local count, choice = 1, 0
		self:control()
		self.flag = 0
	end
end

