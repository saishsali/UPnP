module(...,package.seeall)

local ffi = require("ffi")
local C = ffi.C
local buffer = require("core.buffer")
local packet = require("core.packet")
local bit = require("bit")

local AF_INET = 2

local DEST_MAC = 0
local SOURCE_MAC = 6
local ETHERTYPE_OFFSET = 12
local IPV4_PROTOCOL_OFFSET = 23
local IPV4_SOURCE_OFFSET = 26
local IPV4_DEST_OFFSET = 30
local IPV4_SOURCE_PORT_OFFSET = 34
local IPV4_DEST_PORT_OFFSET = 36
local PAYLOAD_OFFSET = 42


function my_sleep(n)
	local t = os.clock()
   	while os.clock() - t <= n do
   		-- nothing
   	end
end

-- returns number of entries in table
function tablelength(T)
 	local count = 0
  	for _ in pairs(T) do count = count + 1 end
  	return count
end

--[[ 
	If Mac Address = 9c:d2:1e:eb:fa:1d
	returns:
		first = eb1ed29c
		second = 1dfa
]]--

function mac_address_text_to_binary(mac_address)
	local first, second, i = '', '', 1

	while i <= #mac_address do
		if i <= 11 then
			first = first..string.sub(mac_address,i+1,i+1)..string.sub(mac_address,i,i)
		else
			second = second..string.sub(mac_address,i+1,i+1)..string.sub(mac_address,i,i)
		end
		i = i + 3
	end
	return tonumber(string.reverse(first),16),tonumber(string.reverse(second),16)
end

--[[
	If mac_address1 = 3944665756
	   mac_address2 = 7674
	returns:
		9c:d2:1e:eb:fa:1d
]]--

function mac_address_binary_to_text(mac_address1, mac_address2)
	local first, second = bit.tohex(mac_address1), bit.tohex(mac_address2)
	local i = #first
	local result = ''

	while i>0 do
		result = result..string.sub(first,i-1,i-1)..string.sub(first,i,i)..':'
		i = i - 2
	end
	
	i = #second
	while i>4 do
		result = result..string.sub(second,i-1,i-1)..string.sub(second,i,i)..':'
		i = i - 2
	end
	return string.sub(result,1,#result-1)
end


--[[
	If Ip address : 33663168
	returns: '192.168.1.2'
]]--
function ip_binary_to_text(ip_address)
	local strmaxlen = 16
	local buf = ffi.new('char[?]', strmaxlen)
	C.inet_ntop(AF_INET, ip_address , buf, strmaxlen)
	return ffi.string(buf)
end

--[[
	If Ip address : '192.168.1.2'
	returns: 33663168
]]--

function ip_text_to_binary(ip_address)
	local in_addr  = ffi.new("int32_t[1]") 
   	C.inet_pton(AF_INET, ip_address, in_addr)
	return in_addr[0]
end


function getPacket(ethertype, protocol, source_mac, dest_mac, source_ip, dest_ip, source_port, dest_port, payload)
	
	p = packet.allocate()
	b = buffer.allocate()
	
	packet.add_iovec(p, b, 60)

	local buff = p.iovecs[0].buffer.pointer + p.iovecs[0].offset
	local dest_mac_ptr1 = ffi.cast("uint32_t*", buff + DEST_MAC)
   	local dest_mac_ptr2 = ffi.cast("uint16_t*", buff + DEST_MAC + 4)
   	local source_mac_ptr1 = ffi.cast("uint32_t*", buff + SOURCE_MAC)
   	local source_mac_ptr2 = ffi.cast("uint16_t*", buff + SOURCE_MAC + 4)
	local ethertype_ptr = ffi.cast("uint16_t*", buff + ETHERTYPE_OFFSET)
	local source_ip_ptr = ffi.cast("uint32_t*", buff + IPV4_SOURCE_OFFSET)
	local dest_ip_ptr = ffi.cast("uint32_t*", buff + IPV4_DEST_OFFSET)
	local source_port_ptr = ffi.cast("uint16_t*", buff + IPV4_SOURCE_PORT_OFFSET)
	local dest_port_ptr = ffi.cast("uint16_t*", buff + IPV4_DEST_PORT_OFFSET)
	local payload_ptr = ffi.cast("char*", buff + PAYLOAD_OFFSET)

	local first, second = mac_address_text_to_binary(source_mac)
	source_mac_ptr1[0] = first
	source_mac_ptr2[0] = second
	
	first, second = mac_address_text_to_binary(dest_mac)
	dest_mac_ptr1[0] = first
	dest_mac_ptr2[0] = second
	

	ethertype_ptr[0] = ethertype
	buff[IPV4_PROTOCOL_OFFSET] = protocol
	source_ip_ptr[0] = ip_text_to_binary(source_ip)
	dest_ip_ptr[0] = ip_text_to_binary(dest_ip)
	source_port_ptr[0] = source_port
	dest_port_ptr[0] = dest_port

	for i=1, payload:len() do
		payload_ptr[i-1]=string.byte(payload, i)
		payload_ptr[i] = 0
	end
	return p
end