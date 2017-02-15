cd %~dp0/proto

for %%i in (*.proto) do (
	echo %%i
	..\protoc.exe --plugin=protoc-gen-lua="..\plugin\protoc-gen-lua.bat" --lua_out=../output. %%i
	::..\protoc.exe --python_out=../output. %%i
)
echo end
pause
