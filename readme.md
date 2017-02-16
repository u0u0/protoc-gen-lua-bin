# Quick-Cocos2dx-Community 中的 protoc-gen-lua 使用说明

## 背景

google的黑科技protobuffer开源以后，在游戏的客户端与服务器通讯中得到了广泛的应用。但是官方一直没有提供lua的支持。

[protoc-gen-lua](https://github.com/sean-lin/protoc-gen-lua) 是最早实现pb for lua的项目。不过原作者很久没维护了，历时遗留的嵌套问题也没有去合并社区的修正方案。风云的pbc项目也是lua的protobuffer解决方案之一，但是它的用户接口与官方用法差异较大。

两种方案各有优势，Quick-Cocos2dx-Community 选择集成 protoc-gen-lua， 最重要的一点还是与Google官方pb用法规范上保持较好的一致性，这更有利于pb其它版本的老司机转到lua pb的使用上来，也有利于自定义需求的修改。

## 版本说明

Quick-Cocos2dx-Community 集成 protoc-gen-lua 方案，并做以下修正：

1. 修正了 protoc-gen-lua 嵌套问题。(工具中修正)
2. 添加通过 message:DescriptorType()获取子类的真实名称。(引擎中修正)
3. 修正 main function has more than 200 local variables 错误。(工具中修正)
4. 修正 enum 变量有 default 的时候，不能正确设置 default 值的问题。(工具中修正)

对应的protobuffer版本为2.6.1。

## 安装

1. 安装Python 2.x, Windows下请安装32位的python。
2. 如果已通过pip安装了protobuffer的python插件，请先卸载掉，以保证版本匹配。
3. 解压protoc-gen-lua.zip，进入`python_win32`或`python_mac`目录. 启动控制台，运行`python setup.py install`，安装protobuffer的python包。

> zip包自带了protobuf-2.6.1编译后的"compiler"，并以放置在python插件目录下，以保证python插件安装成功。

## proto 转化为 lua

protoc-gen-lua是以插件的形式，配合google官方的protoc来实现.proto文件转换为lua文件，引擎中只需要转换出来lua文件，配合runtime进行编解码。

定义的.proto文件全部放在`proto`下，然后双击运行`buildproto.bat`，对应的lua文件生成在output目录下。

如`RoomInfo.proto`生成`RoomInfo.lua`。

## 引擎中的使用

把`AddressBook_pb.lua、GetRoom_pb.lua、ResultInfo_pb.lua、RoomInfo_pb.lua`拷贝到项目工程下的`src/app/pb`文件夹中。

```
-- 引用文件
require("app.pb.AddressBook_pb")
require("app.pb.ResultInfo_pb")
require("app.pb.RoomInfo_pb")
require("app.pb.GetRoom_pb")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
	self:testRoom()
	self:testPerson()
end

function MainScene:testRoom()
	-- 序列化 GetRoomRequest
	local roomIdList = {10,20,30}
	local getRoomRequestWriter = GetRoom_pb.GetRoomRequest() --#pbTips

	for _, v in ipairs(roomIdList) do
		getRoomRequestWriter.roomId:append(v) -- 向数组添加元素，不能直接赋值
	end
	print("== Serialize to GetRoomRequest")
	local data = getRoomRequestWriter:SerializeToString()

	-- 反序列化 GetRoomRequest
	local getRoomRequestReader = GetRoom_pb.GetRoomRequest() --#pbTips
	print("== Parse From GetRoomRequest")
	getRoomRequestReader:ParseFromString(data)
	-- 使用 ipairs 可正确获取到数据，paris 会有多余数据打印出来
	for _, v in ipairs(getRoomRequestReader.roomId) do
		print(v)
	end

	-- 序列化 GetRoomResponse
	local getRoomResponseWriter = GetRoom_pb.GetRoomResponse()
	getRoomResponseWriter.result = ResultInfo_pb.SUCCESS

	for i=1,2 do
		local room = getRoomResponseWriter.room:add() -- 数组中的元素是对象，用add来添加
		room.id = "1000" .. i
		room.name = "小黑屋-" .. i
		room.taskType = RoomInfo_pb.MAINLINE
	end
	print("== Serialize to GetRoomResponse")
	local data = getRoomResponseWriter:SerializeToString()

	-- 反序列化 GetRoomResponse
	local getRoomResponseReader = GetRoom_pb.GetRoomResponse()
	print("== Parse From GetRoomResponse")
	getRoomResponseReader:ParseFromString(data)
	print("result:" .. getRoomResponseReader.result)
	print("message:" .. getRoomResponseReader.message) -- default value test
	for _, v in ipairs(getRoomResponseReader.room) do
		print(v.id)
		print(v.name)
		print(v.taskType)
		print(v.needHp) -- default value test
	end
end

function MainScene:testPerson()
	print("========= test AddressBook ====")

	-- 序列化
	local addressBookWriter = AddressBook_pb.AddressBook()
	for i = 1, 5 do
		local person = addressBookWriter.person:add()
		person.name = "my " .. i
		person.id = i

		local phone = person.phone:add()
		phone.number = "123456789"
		if i % 2 == 0 then
			phone.type = AddressBook_pb.Person.WORK
		end
	end
	local data = addressBookWriter:SerializeToString()

	-- write to file for compare test with python pb
	local path = cc.FileUtils:getInstance():getWritablePath() .. "testpb.bin"
	io.writefile(path, data, "wb")

	-- 反序列化
	local addressBookReader = AddressBook_pb.AddressBook()
	addressBookReader:ParseFromString(data)
	for _, person in ipairs(addressBookReader.person) do
		print(person.name)
		print(person.id)
		for _, phone in ipairs(person.phone) do
			print(phone.number)
			if (phone.type == AddressBook_pb.Person.MOBILE) then
				print("MOBILE")
			elseif (phone.type == AddressBook_pb.Person.HOME) then
				print("HOME")
			else
				print("WORK")
			end
		end
	end
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
```
